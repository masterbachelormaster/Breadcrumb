import SwiftUI
import AppKit

/// Invisible helper that reports when the hosting menu bar popover window is
/// hidden. SwiftUI's `appearsActive` never updates for MenuBarExtra panels,
/// so this observes the window's occlusion state directly via AppKit.
struct PopoverVisibilityObserver: NSViewRepresentable {
    var onHidden: () -> Void

    func makeNSView(context: Context) -> ObserverView {
        let view = ObserverView()
        view.onHidden = onHidden
        return view
    }

    func updateNSView(_ nsView: ObserverView, context: Context) {
        nsView.onHidden = onHidden
    }

    final class ObserverView: NSView {
        var onHidden: (() -> Void)?
        private weak var observedWindow: NSWindow?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard window !== observedWindow else { return }

            if let observedWindow {
                NotificationCenter.default.removeObserver(
                    self,
                    name: NSWindow.didChangeOcclusionStateNotification,
                    object: observedWindow
                )
                NotificationCenter.default.removeObserver(
                    self,
                    name: NSWindow.willCloseNotification,
                    object: observedWindow
                )
            }
            observedWindow = window

            guard let window else {
                // The popover tore down its window entirely — also "hidden".
                notifyHidden()
                return
            }

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(occlusionDidChange),
                name: NSWindow.didChangeOcclusionStateNotification,
                object: window
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(windowWillClose),
                name: NSWindow.willCloseNotification,
                object: window
            )
        }

        @objc private func windowWillClose() {
            notifyHidden()
        }

        @objc private func occlusionDidChange() {
            guard let window = observedWindow,
                  !window.occlusionState.contains(.visible) else { return }
            notifyHidden()
        }

        /// Defers the callback so state mutation never happens inside a
        /// view update or layout pass.
        private func notifyHidden() {
            Task { @MainActor [weak self] in
                self?.onHidden?()
            }
        }
    }
}
