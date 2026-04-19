import SwiftUI
import AppKit

struct PlaceholderTextView: NSViewRepresentable {
    var placeholder: String
    @Binding var text: String
    var focusOnAppear: Bool = false
    var onFocusChange: ((Bool) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = PlaceholderNSTextView()
        textView.placeholderString = placeholder
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: NSFont.systemFontSize)
        textView.isRichText = false
        textView.allowsUndo = true
        textView.drawsBackground = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.textContainerInset = NSSize(width: 2, height: 6)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false

        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder

        let coordinator = context.coordinator
        textView.onFocusChange = { [weak coordinator] focused in
            coordinator?.parent.onFocusChange?(focused)
        }

        context.coordinator.textView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? PlaceholderNSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
        if textView.placeholderString != placeholder {
            textView.placeholderString = placeholder
        }
        context.coordinator.parent = self
        if focusOnAppear && !context.coordinator.hasFocused {
            context.coordinator.hasFocused = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                textView.window?.makeFirstResponder(textView)
            }
        }
    }

    @MainActor
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PlaceholderTextView
        var textView: PlaceholderNSTextView?
        var hasFocused = false

        init(_ parent: PlaceholderTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}

class PlaceholderNSTextView: NSTextView {
    var placeholderString: String = "" {
        didSet { needsDisplay = true }
    }

    var onFocusChange: ((Bool) -> Void)?

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result { onFocusChange?(true) }
        return result
    }

    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if result { onFocusChange?(false) }
        return result
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if string.isEmpty && !placeholderString.isEmpty {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font ?? .systemFont(ofSize: NSFont.systemFontSize),
                .foregroundColor: NSColor.placeholderTextColor
            ]
            let inset = textContainerInset
            let padding = textContainer?.lineFragmentPadding ?? 5
            let rect = NSRect(
                x: inset.width + padding,
                y: inset.height,
                width: bounds.width - (inset.width + padding) * 2,
                height: bounds.height - inset.height * 2
            )
            placeholderString.draw(in: rect, withAttributes: attrs)
        }
    }
}
