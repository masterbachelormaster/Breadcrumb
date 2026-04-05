import AppKit
import SwiftUI

struct SoundPicker: View {
    let label: String
    @Binding var selection: String

    private let systemSounds = [
        "Basso", "Blow", "Bottle", "Frog", "Funk",
        "Glass", "Hero", "Morse", "Ping", "Pop",
        "Purr", "Sosumi", "Submarine", "Tink"
    ]

    var body: some View {
        HStack {
            Picker(label, selection: $selection) {
                Text(Strings.Settings.noSound(currentLanguage))
                    .tag("")
                ForEach(systemSounds, id: \.self) { sound in
                    Text(sound).tag(sound)
                }
            }

            Button(Strings.Settings.previewSound(currentLanguage), systemImage: "speaker.wave.2") {
                previewSound()
            }
            .buttonStyle(.borderless)
            .labelStyle(.iconOnly)
            .disabled(selection.isEmpty)
        }
    }

    private var currentLanguage: AppLanguage {
        let stored = UserDefaults.standard.string(forKey: "app.language") ?? "de"
        return AppLanguage(rawValue: stored) ?? .german
    }

    private func previewSound() {
        NSSound(named: NSSound.Name(selection))?.play()
    }
}
