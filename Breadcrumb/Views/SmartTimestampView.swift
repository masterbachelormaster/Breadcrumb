import SwiftUI

struct SmartTimestampView: View {
    @Environment(LanguageManager.self) private var languageManager
    let date: Date
    var font: Font = .caption
    var color: AnyShapeStyle = AnyShapeStyle(.secondary)

    @State private var showRelative = false

    var body: some View {
        Button {
            showRelative.toggle()
        } label: {
            Group {
                if showRelative {
                    Text(date, style: .relative)
                } else {
                    Text(formattedDate)
                }
            }
            .font(font)
            .foregroundStyle(color)
        }
        .buttonStyle(ToolbarButtonStyle())
    }

    private var formattedDate: String {
        let calendar = Calendar.current
        let now = Date.now

        if calendar.isDateInToday(date) {
            let timeString = date.formatted(.dateTime.hour().minute())
            return "\(Strings.General.today(languageManager.language)) \(timeString)"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .year) {
            return date.formatted(.dateTime.day().month().hour().minute())
        } else {
            return date.formatted(.dateTime.day().month().year().hour().minute())
        }
    }
}
