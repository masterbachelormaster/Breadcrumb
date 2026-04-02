import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Zurück")
                    }
                    .font(.body)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Einstellungen")
                    .font(.headline)

                Spacer()

                Color.clear.frame(width: 60, height: 1)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Content
            Form {
                Toggle("Beim Login starten", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }
            }
            .formStyle(.grouped)
        }
    }
}
