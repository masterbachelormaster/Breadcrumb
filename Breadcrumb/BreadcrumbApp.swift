import SwiftUI

@main
struct BreadcrumbApp: App {
    var body: some Scene {
        MenuBarExtra("Breadcrumb", systemImage: "bookmark.fill") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
