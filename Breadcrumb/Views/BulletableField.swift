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
/// On every render the bullet array is derived by `BulletText.parse`.
/// Edits write back through the binding immediately via the local helpers.
struct BulletableField: View {
    @Environment(LanguageManager.self) private var languageManager

    let label: String
    @Binding var text: String

    @FocusState private var plainFocused: Bool
    @FocusState private var listFocused: Int?

    private var items: [String] {
        BulletText.parse(text)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if items.count <= 1 {
                plainModeField
            } else {
                listModeField
            }
            addBulletButton
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
                            insertBullet(after: index)
                        }
                    Button {
                        removeBullet(at: index)
                    } label: {
                        Image(systemName: "xmark")
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
                let parsed = BulletText.parse(text)
                guard index < parsed.count else { return "" }
                return parsed[index]
            },
            set: { newValue in
                var parsed = BulletText.parse(text)
                guard index < parsed.count else { return }
                parsed[index] = newValue
                // Don't filter empties here — that would yank the row out
                // from under the user mid-typing. Re-derivation on next
                // render handles cleanup once focus moves on.
                text = parsed.joined(separator: "\n")
            }
        )
    }

    private func addBullet() {
        var parsed = BulletText.parse(text)
        parsed.append("")
        text = parsed.joined(separator: "\n")
        // Focus the new bullet. We need to wait one render so the new
        // TextField exists in the focus map.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(50))
            listFocused = parsed.count - 1
        }
    }

    private func insertBullet(after index: Int) {
        var parsed = BulletText.parse(text)
        let newIndex = min(index + 1, parsed.count)
        parsed.insert("", at: newIndex)
        text = parsed.joined(separator: "\n")
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(50))
            listFocused = newIndex
        }
    }

    private func removeBullet(at index: Int) {
        var parsed = BulletText.parse(text)
        guard index < parsed.count else { return }
        parsed.remove(at: index)
        text = parsed.joined(separator: "\n")
        // Move focus to the previous bullet, or the first if we removed
        // the first one. If the array is now empty, the view re-renders
        // in plain mode and focus naturally goes nowhere.
        if !parsed.isEmpty {
            listFocused = max(0, index - 1)
        }
    }
}
