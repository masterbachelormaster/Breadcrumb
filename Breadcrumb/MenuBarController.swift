import AppKit
import Observation
import SwiftData
import SwiftUI

/// Owns the menu bar status item and its popover.
///
/// Replaces SwiftUI's `MenuBarExtra`, which on macOS 27 fails to activate its
/// popover on click. Following Calendr's approach, this hand-wires the status
/// button click and presents `ContentView` inside a borderless
/// `.nonactivatingPanel` shown via `makeKeyAndOrderFront(_:)` — never
/// `NSApp.activate`. That is what reliably opens (and keeps keyboard focus)
/// without depending on the broken app-activation path.
@MainActor
final class MenuBarController: NSObject {
    private let pomodoroTimer: PomodoroTimer
    private let windowManager: WindowManager
    private let aiService: AIService
    private let languageManager: LanguageManager
    private let speechRecognizer: SpeechRecognizer
    private let modelContainer: ModelContainer

    private var statusItem: NSStatusItem?
    private var panel: NSPanel?
    private var hostingView: NSHostingView<AnyView>?
    private var globalMonitor: Any?

    init(
        pomodoroTimer: PomodoroTimer,
        windowManager: WindowManager,
        aiService: AIService,
        languageManager: LanguageManager,
        speechRecognizer: SpeechRecognizer,
        modelContainer: ModelContainer
    ) {
        self.pomodoroTimer = pomodoroTimer
        self.windowManager = windowManager
        self.aiService = aiService
        self.languageManager = languageManager
        self.speechRecognizer = speechRecognizer
        self.modelContainer = modelContainer
        super.init()
    }

    // MARK: - Setup

    func install() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.sendAction(on: [.leftMouseDown, .rightMouseUp])
            button.target = self
            button.action = #selector(handleClick)
        }
        statusItem = item
        updateLabel()
        observeLabel()
    }

    /// Programmatically show the popover (notification-driven flows). Revives the
    /// path that `NSStatusBarButton.performClick` no longer supports on macOS 27.
    func showPopover() {
        if panel == nil { showPanel() }
    }

    // MARK: - Status label

    /// Re-renders the status label whenever the timer state or language changes,
    /// re-arming the observation each time.
    private func observeLabel() {
        withObservationTracking {
            _ = pomodoroTimer.menuBarLabel(languageManager.language)
            _ = pomodoroTimer.currentPhase
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.updateLabel()
                self?.observeLabel()
            }
        }
    }

    private func updateLabel() {
        guard let button = statusItem?.button else { return }
        if pomodoroTimer.currentPhase == .idle {
            let image = NSImage(systemSymbolName: "bookmark.fill", accessibilityDescription: "Breadcrumb")
            image?.isTemplate = true
            button.image = image
        } else {
            // The running label carries emoji, so it must keep its colors —
            // a template image would flatten them to a single tint.
            let label = pomodoroTimer.menuBarLabel(languageManager.language)
            let image = MenuBarLabelRenderer.image(for: label)
            image.isTemplate = false
            button.image = image
            button.setAccessibilityLabel(label)
        }
    }

    // MARK: - Click handling

    @objc private func handleClick() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePanel()
        }
    }

    private func togglePanel() {
        if panel != nil {
            closePanel()
        } else {
            showPanel()
        }
    }

    private func showContextMenu() {
        guard let button = statusItem?.button else { return }
        let language = languageManager.language
        let menu = NSMenu()

        let settings = NSMenuItem(
            title: Strings.General.settingsEllipsis(language),
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settings.target = self
        menu.addItem(settings)

        let about = NSMenuItem(
            title: Strings.General.about(language),
            action: #selector(openAbout),
            keyEquivalent: ""
        )
        about.target = self
        about.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: nil)
        menu.addItem(about)

        menu.addItem(.separator())

        menu.addItem(NSMenuItem(
            title: Strings.General.quit(language),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        // Drive the menu ourselves — assigning `statusItem.menu` + performClick is
        // a no-op on macOS 27.
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.maxY + 4), in: button)
    }

    @objc private func openSettings() {
        windowManager.openSettings()
    }

    @objc private func openAbout() {
        windowManager.open(.about)
    }

    // MARK: - Panel

    private func showPanel() {
        guard let buttonRect = statusButtonScreenFrame() else { return }

        let panel = MenuBarPanel()

        let host = NSHostingView(rootView: contentRootView())
        host.translatesAutoresizingMaskIntoConstraints = false

        let backdrop = NSVisualEffectView()
        backdrop.material = .popover
        backdrop.blendingMode = .behindWindow
        backdrop.state = .active
        backdrop.wantsLayer = true
        backdrop.layer?.cornerRadius = 10
        backdrop.addSubview(host)
        NSLayoutConstraint.activate([
            host.leadingAnchor.constraint(equalTo: backdrop.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: backdrop.trailingAnchor),
            host.topAnchor.constraint(equalTo: backdrop.topAnchor),
            host.bottomAnchor.constraint(equalTo: backdrop.bottomAnchor)
        ])
        panel.contentView = backdrop

        // ContentView is a fixed 350×450 popover.
        let size = NSSize(width: 350, height: 450)
        panel.setContentSize(size)

        let origin = NSPoint(
            x: buttonRect.midX - size.width / 2,
            y: buttonRect.minY - size.height - 6
        )
        panel.setFrameOrigin(clampToScreen(origin: origin, size: size))

        self.panel = panel
        self.hostingView = host

        // The crux: show + key WITHOUT activating the app.
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(host)
        statusItem?.button?.highlight(true)

        installGlobalMonitor()
    }

    private func closePanel() {
        removeGlobalMonitor()
        statusItem?.button?.highlight(false)
        panel?.orderOut(nil)
        panel = nil
        hostingView = nil
    }

    private func contentRootView() -> AnyView {
        AnyView(
            ContentView()
                .environment(pomodoroTimer)
                .environment(windowManager)
                .environment(aiService)
                .environment(languageManager)
                .environment(speechRecognizer)
                .modelContainer(modelContainer)
        )
    }

    /// Keep the panel on screen: nudge it left if it would overflow the right
    /// edge (status item near the corner), and never push it above the menu bar.
    private func clampToScreen(origin: NSPoint, size: NSSize) -> NSPoint {
        guard let screen = NSScreen.main else { return origin }
        let visible = screen.visibleFrame
        var x = origin.x
        if x + size.width > visible.maxX - 8 {
            x = visible.maxX - size.width - 8
        }
        x = max(x, visible.minX + 8)
        return NSPoint(x: x, y: origin.y)
    }

    // MARK: - Dismiss

    private func installGlobalMonitor() {
        removeGlobalMonitor()
        globalMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                // Ignore clicks on our own status item — the button's action
                // toggles the panel; closing here too would race it and reopen.
                if self.statusButtonScreenFrame()?.contains(NSEvent.mouseLocation) == true {
                    return
                }
                self.closePanel()
            }
        }
    }

    private func removeGlobalMonitor() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
    }

    private func statusButtonScreenFrame() -> NSRect? {
        guard let button = statusItem?.button, let window = button.window else { return nil }
        return window.convertToScreen(button.convert(button.bounds, to: nil))
    }
}

/// Borderless, non-activating panel — takes keyboard focus without making the
/// app active, which is what survives the macOS 27 activation regression.
private final class MenuBarPanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 350, height: 450),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        level = .popUpMenu
        collectionBehavior = [.moveToActiveSpace]
        isMovable = false
        hidesOnDeactivate = false
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    override var acceptsFirstResponder: Bool { true }
}
