import AppKit

/// Renders the menu bar timer label into an image.
///
/// MenuBarExtra renders a plain `Text` label with the system menu bar font,
/// whose proportional digits make the status item width change every second.
/// Font modifiers like `monospacedDigit()` are ignored there, so the label is
/// drawn into an `NSImage` with the monospaced-digit system font instead.
/// The drawing handler runs lazily at display time, so `labelColor` resolves
/// against the actual menu bar appearance (light/dark).
@MainActor
enum MenuBarLabelRenderer {
    static func image(for text: String) -> NSImage {
        let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        let measured = NSAttributedString(string: text, attributes: [.font: font]).size()
        let size = NSSize(width: ceil(measured.width), height: max(ceil(measured.height), 18))
        return NSImage(size: size, flipped: false) { rect in
            let attributed = NSAttributedString(string: text, attributes: [
                .font: font,
                .foregroundColor: NSColor.labelColor,
            ])
            let textSize = attributed.size()
            attributed.draw(at: NSPoint(
                x: (rect.width - textSize.width) / 2,
                y: (rect.height - textSize.height) / 2
            ))
            return true
        }
    }
}
