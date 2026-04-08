import SwiftUI

/// Editing replacement for `OptionalFieldView` for status fields that may
/// contain bullet lists. Bound to a single `String` (no schema change).
///
/// **Mode is implicit from content.** A field with zero or one bullet
/// item renders as a plain `TextField`. Two or more items render as a
/// vertical stack of bullet rows. The user transitions between modes by
/// pressing the "Add bullet" button or by adding/removing list items.
///
/// **Source of truth:** the binding `String` is always authoritative.
/// On every render the bullet array is derived by `BulletText.parseRaw`,
/// which preserves empty rows and trailing whitespace so the cursor does
/// not jump out from under the user mid-typing. Display contexts use
/// `BulletText.parse` instead, which trims and filters for clean output.
/// Edits write back through the binding immediately via the local helpers.
struct BulletableField: View {
    @Environment(LanguageManager.self) private var languageManager

    @AppStorage("feature.bulletListsEnabled") private var bulletListsEnabled = true

    let label: String
    @Binding var text: String

    @FocusState private var plainFocused: Bool
    @FocusState private var listFocused: Int?

    private var items: [String] {
        BulletText.parseRaw(text)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if items.count <= 1 || !bulletListsEnabled {
                plainModeField
            } else {
                listModeField
            }
            if bulletListsEnabled {
                addBulletButton
            }
        }
    }

    // MARK: - Plain mode

    @ViewBuilder
    private var plainModeField: some View {
        TextField(label, text: $text)
            .textFieldStyle(.roundedBorder)
            .focused($plainFocused)
    }

    // MARK: - List mode

    @ViewBuilder
    private var listModeField: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("•")
                        .foregroundStyle(.secondary)
                    TextField(label, text: bindingForItem(at: index))
                        .textFieldStyle(.roundedBorder)
                        .focused($listFocused, equals: index)
                        .onSubmit {
                            guard bulletListsEnabled else { return }
                            insertBullet(after: index)
                        }
                    Button {
                        removeBullet(at: index)
                    } label: {
                        Image(systemName: "minus.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(Strings.General.delete(languageManager.language))
                }
            }
        }
    }

    // MARK: - Add bullet button

    @ViewBuilder
    private var addBulletButton: some View {
        Button {
            addBullet()
        } label: {
            Label(
                Strings.Status.addBullet(languageManager.language),
                systemImage: "list.bullet"
            )
            .font(.caption)
        }
        .buttonStyle(.borderless)
    }

    // MARK: - Mutations

    private func bindingForItem(at index: Int) -> Binding<String> {
        Binding(
            get: {
                let parsed = BulletText.parseRaw(text)
                guard index < parsed.count else { return "" }
                return parsed[index]
            },
            set: { newValue in
                var parsed = BulletText.parseRaw(text)
                guard index < parsed.count else { return }
                parsed[index] = newValue
                // parseRaw (used throughout this view) preserves empty rows
                // and trailing whitespace while the user is typing, so the
                // cursor doesn't jump. Normalization is not done here.
                text = parsed.joined(separator: "\n")
            }
        )
    }

    private func addBullet() {
        guard bulletListsEnabled else { return }
        var parsed = BulletText.parseRaw(text)
        parsed.append("")
        text = parsed.joined(separator: "\n")
        // Focus the new bullet. We need to wait one render so the new
        // TextField exists in the focus map.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            listFocused = parsed.count - 1
        }
    }

    private func insertBullet(after index: Int) {
        guard bulletListsEnabled else { return }
        var parsed = BulletText.parseRaw(text)
        let newIndex = min(index + 1, parsed.count)
        parsed.insert("", at: newIndex)
        text = parsed.joined(separator: "\n")
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            listFocused = newIndex
        }
    }

    private func removeBullet(at index: Int) {
        var parsed = BulletText.parseRaw(text)
        guard index < parsed.count else { return }
        parsed.remove(at: index)
        text = parsed.joined(separator: "\n")
        if parsed.count >= 2 {
            // Still in list mode — focus moves to the previous bullet.
            listFocused = max(0, index - 1)
        } else {
            // View will re-render in plain mode. Transfer focus there so
            // the user can keep typing without losing it.
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                plainFocused = true
            }
        }
    }
}
