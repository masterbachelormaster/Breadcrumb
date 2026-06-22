import Testing
@testable import Breadcrumb

@Suite("Motivational quotes")
struct MotivationalQuotesTests {

    @Test("Corpus is reasonably sized and every entry has text and author")
    func corpusPopulated() {
        #expect(MotivationalQuotes.all.count >= 100)
        for q in MotivationalQuotes.all {
            #expect(!q.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            #expect(!q.author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    @Test("IDs match array position and are unique")
    func idsMatchIndex() {
        for (index, q) in MotivationalQuotes.all.enumerated() {
            #expect(q.id == index)
        }
        #expect(Set(MotivationalQuotes.all.map(\.id)).count == MotivationalQuotes.all.count)
    }

    @Test("Quote texts are unique (no duplicates)")
    func textsAreUnique() {
        let normalized = MotivationalQuotes.all.map { $0.text.lowercased() }
        #expect(Set(normalized).count == normalized.count)
    }

    @Test("random() returns a member of the corpus")
    func randomReturnsMember() {
        #expect(MotivationalQuotes.all.contains(MotivationalQuotes.random()))
    }

    @Test("random(excluding:) never returns the excluded id")
    func randomExcludesPrevious() {
        for _ in 0..<500 {
            let excluded = Int.random(in: 0..<MotivationalQuotes.all.count)
            #expect(MotivationalQuotes.random(excluding: excluded).id != excluded)
        }
    }
}
