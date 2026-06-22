import SwiftUI

/// A styled card showing a motivational quote and its author, used on the
/// Pomodoro break-over screen to fill the space and nudge the user back to work.
struct BreakQuoteCard: View {
    let quote: MotivationalQuote

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "quote.opening")
                .font(.title3)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(quote.text)
                .font(.body)
                .italic()
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text("— \(quote.author)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(nsColor: .separatorColor)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(quote.text), by \(quote.author)")
    }
}
