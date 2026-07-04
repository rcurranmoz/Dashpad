import Foundation
import FoundationModels

/// On-device intelligence for Dashpad, powered by Apple's Foundation Models.
/// Every idea is analyzed locally — nothing ever leaves the device.
enum DashIntelligence {

    /// True when the on-device model is ready to use (Apple Intelligence
    /// enabled, model assets downloaded). All callers fall back to the
    /// keyword-based TagPredictor / regex DateParser when this is false.
    static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    /// Loads model assets ahead of the first request so the first capture
    /// doesn't pay the cold-start cost. Call during the splash animation.
    static func prewarm() {
        guard isAvailable else { return }
        LanguageModelSession().prewarm()
    }

    // MARK: - Capture Analysis

    @Generable
    struct CaptureAnalysis {
        @Guide(description: "Up to 2 category tags that best fit this note, chosen ONLY from the allowed tag list. Empty if none fit well.")
        var tags: [String]

        @Guide(description: "The exact words in the note that say when it happens or is due, e.g. 'tomorrow 3pm' or 'next friday'. Omit if no time is mentioned.")
        var dueDatePhrase: String?
    }

    struct SmartCapture {
        var tags: [String]
        var dueDate: Date?
    }

    /// Understands a captured note: picks the best category tags and pulls
    /// out a due date, no matter how it's phrased. Returns nil when the
    /// model is unavailable or declines.
    static func analyze(_ text: String, knownTags: [String]) async -> SmartCapture? {
        guard isAvailable else { return nil }

        let allowed = allowedTags(including: knownTags)
        let session = LanguageModelSession(instructions: """
            You file short captured notes into categories for an idea-capture app.
            Allowed tags: \(allowed.joined(separator: ", ")).
            Pick the single best tag (two at most). A grocery or household \
            shopping item is 'grocery'. Something to watch is 'movies'. \
            Something to build or a product thought is 'ideas'. \
            If nothing fits well, return no tags — never invent new tags.
            """)

        do {
            let response = try await session.respond(
                to: "Note: \(text)",
                generating: CaptureAnalysis.self
            )
            let tags = response.content.tags
                .map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
                .filter { allowed.contains($0) }

            var dueDate: Date?
            if let phrase = response.content.dueDatePhrase, !phrase.isEmpty {
                dueDate = DateParser.parse(phrase).date ?? DateParser.detectorDate(in: phrase)
            }
            return SmartCapture(tags: Array(tags.prefix(2)).removingDuplicates(), dueDate: dueDate)
        } catch {
            return nil
        }
    }

    // MARK: - Spark (next steps for an idea)

    /// Turns a raw idea into a few concrete next steps.
    static func spark(title: String, body: String?) async -> String? {
        guard isAvailable else { return nil }

        let session = LanguageModelSession(instructions: """
            You help someone act on an idea they captured. Reply with 2 to 4 \
            short, concrete next steps as a dash list. Be specific and \
            energizing. No preamble, no closing line — just the steps.
            """)

        var prompt = "Idea: \(title)"
        if let body, !body.isEmpty { prompt += "\nContext: \(body)" }

        guard let content = try? await session.respond(to: prompt).content else { return nil }
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    // MARK: - Helpers

    private static func allowedTags(including knownTags: [String]) -> [String] {
        (TagPredictor.builtInTags + knownTags.map { $0.lowercased() }).removingDuplicates()
    }
}

private extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
