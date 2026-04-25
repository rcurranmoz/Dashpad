import Foundation

struct TagPredictor {

    // MARK: - Keyword → Tag Mappings

    private static let keywordMappings: [String: [String]] = [
        // Work
        "meeting": ["work"], "email": ["work"], "presentation": ["work"],
        "deadline": ["work"], "project": ["work"], "client": ["work"],
        "boss": ["work"], "slack": ["work"], "zoom": ["work"],
        "report": ["work"], "review": ["work"], "sprint": ["work"],
        "standup": ["work"], "pr": ["work"], "deploy": ["work"],

        // Family
        "mom": ["family"], "dad": ["family"], "parent": ["family"],
        "kid": ["family"], "kids": ["family"], "son": ["family"],
        "daughter": ["family"], "wife": ["family"], "husband": ["family"],
        "brother": ["family"], "sister": ["family"], "birthday": ["family", "social"],
        "anniversary": ["family"],

        // Home
        "clean": ["home"], "laundry": ["home"], "dishes": ["home"],
        "vacuum": ["home"], "trash": ["home"], "garbage": ["home"],
        "repair": ["home"], "fix": ["home"], "mow": ["home"],
        "lawn": ["home"], "garden": ["home"], "lease": ["home"],

        // Health
        "doctor": ["health"], "dentist": ["health"], "appointment": ["health"],
        "gym": ["health"], "workout": ["health"], "exercise": ["health"],
        "run": ["health"], "running": ["health"], "medicine": ["health"],
        "prescription": ["health"], "vitamin": ["health"], "therapy": ["health"],
        "meditation": ["health"], "sleep": ["health"],

        // Finance
        "pay": ["finance"], "bill": ["finance"], "rent": ["finance"],
        "mortgage": ["finance"], "insurance": ["finance"], "tax": ["finance"],
        "taxes": ["finance"], "bank": ["finance"], "budget": ["finance"],
        "invoice": ["finance"], "subscription": ["finance"],

        // Grocery / Shopping (food items trigger grocery)
        "milk": ["grocery"], "eggs": ["grocery"], "bread": ["grocery"],
        "butter": ["grocery"], "cheese": ["grocery"], "yogurt": ["grocery"],
        "chicken": ["grocery"], "beef": ["grocery"], "fish": ["grocery"],
        "salmon": ["grocery"], "pasta": ["grocery"], "rice": ["grocery"],
        "flour": ["grocery"], "sugar": ["grocery"], "salt": ["grocery"],
        "pepper": ["grocery"], "olive": ["grocery"], "oil": ["grocery"],
        "coffee": ["grocery"], "tea": ["grocery"], "juice": ["grocery"],
        "water": ["grocery"], "soda": ["grocery"], "beer": ["grocery"],
        "wine": ["grocery"], "fruit": ["grocery"], "vegetables": ["grocery"],
        "apples": ["grocery"], "bananas": ["grocery"], "tomatoes": ["grocery"],
        "onions": ["grocery"], "garlic": ["grocery"], "potatoes": ["grocery"],
        "spinach": ["grocery"], "lettuce": ["grocery"], "carrots": ["grocery"],
        "cereal": ["grocery"], "granola": ["grocery"], "oats": ["grocery"],
        "snacks": ["grocery"], "chips": ["grocery"], "crackers": ["grocery"],
        "sauce": ["grocery"], "ketchup": ["grocery"], "mustard": ["grocery"],
        "groceries": ["grocery"],
        // Non-food shopping
        "buy": ["shopping"], "order": ["shopping"], "amazon": ["shopping"],
        "return": ["shopping"], "store": ["shopping"],

        // Movies / TV / Media — watch triggers high confidence
        "watch": ["movies"], "rewatch": ["movies"],
        "movie": ["movies"], "film": ["movies"], "cinema": ["movies"],
        "netflix": ["movies"], "hulu": ["movies"], "hbo": ["movies"],
        "disney": ["movies"], "apple tv": ["movies"], "prime": ["movies"],
        "show": ["movies"], "series": ["movies"], "episode": ["movies"],
        "season": ["movies"], "documentary": ["movies"], "anime": ["movies"],
        "tv": ["movies"],

        // Games
        "game": ["games"], "play": ["games"], "gaming": ["games"],
        "steam": ["games"], "switch": ["games"], "xbox": ["games"],
        "playstation": ["games"], "ps5": ["games"], "ps4": ["games"],
        "nintendo": ["games"], "dlc": ["games"], "rpg": ["games"],

        // Apps / Software
        "app": ["apps"], "download": ["apps"], "software": ["apps"],
        "tool": ["apps"], "extension": ["apps"], "plugin": ["apps"],
        "saas": ["apps"], "service": ["apps"],

        // Ideas / Build
        "idea": ["ideas"], "concept": ["ideas"], "build": ["ideas"],
        "create": ["ideas"], "make": ["ideas"], "prototype": ["ideas"],
        "startup": ["ideas"], "product": ["ideas"], "feature": ["ideas"],
        "side project": ["ideas"], "hack": ["ideas"],

        // Books / Reading
        "book": ["books"], "read": ["books"], "reading": ["books"],
        "novel": ["books"], "author": ["books"], "chapter": ["books"],
        "audiobook": ["books"], "kindle": ["books"],

        // Music
        "music": ["music"], "song": ["music"], "album": ["music"],
        "playlist": ["music"], "artist": ["music"], "concert": ["music"],
        "gig": ["music"], "spotify": ["music"],

        // Travel
        "flight": ["travel"], "hotel": ["travel"], "passport": ["travel"],
        "trip": ["travel"], "vacation": ["travel"], "pack": ["travel"],
        "airport": ["travel"], "visa": ["travel"], "airbnb": ["travel"],

        // Social
        "friend": ["social"], "friends": ["social"], "party": ["social"],
        "dinner": ["social", "work"], "lunch": ["social", "work"],
        "drinks": ["social"], "hangout": ["social"], "visit": ["social", "family"],

        // Pets
        "dog": ["pets"], "cat": ["pets"], "vet": ["pets"],
        "feed": ["pets"], "pet": ["pets"],
    ]

    // Tags where a single keyword match is enough to auto-apply
    // (because the keyword is domain-specific and unambiguous)
    private static let autoApplyKeywords: Set<String> = [
        // Grocery — these are grocery items, full stop
        "milk", "eggs", "bread", "butter", "cheese", "yogurt", "chicken",
        "beef", "fish", "salmon", "pasta", "rice", "flour", "sugar",
        "coffee", "tea", "juice", "fruit", "vegetables", "apples", "bananas",
        "tomatoes", "onions", "garlic", "potatoes", "spinach", "lettuce",
        "carrots", "cereal", "granola", "oats", "groceries",
        // Movies — "watch X" is unambiguous
        "watch", "rewatch",
    ]

    // MARK: - Public API

    /// Returns up to 3 suggested tags, prioritising existing user tags
    static func suggestTags(for text: String, existingUserTags: [String]) -> [String] {
        let scores = scoreText(text, existingUserTags: existingUserTags)
        return scores
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
    }

    /// Returns one tag to silently auto-apply when confidence is high enough.
    /// Only fires for unambiguous domain keywords (grocery items, "watch X", etc.)
    static func autoApplyTag(for text: String, existingUserTags: [String]) -> String? {
        let words = text.lowercased().components(separatedBy: .whitespaces)

        for word in words {
            if autoApplyKeywords.contains(word), let tags = keywordMappings[word] {
                return tags.first
            }
        }

        // Also fire if an existing user tag scores very high (user has trained the system)
        let scores = scoreText(text, existingUserTags: existingUserTags)
        if let top = scores.max(by: { $0.value < $1.value }), top.value >= 5 {
            return top.key
        }

        return nil
    }

    // MARK: - Tag Colors

    static func color(for tag: String) -> String {
        let fixed: [String: String] = [
            "work": "6366F1",
            "family": "EC4899",
            "home": "F59E0B",
            "health": "10B981",
            "finance": "06B6D4",
            "shopping": "8B5CF6",
            "grocery": "22C55E",
            "movies": "EF4444",
            "games": "F97316",
            "apps": "3B82F6",
            "ideas": "8B5CF6",
            "books": "A78BFA",
            "music": "EC4899",
            "social": "F97316",
            "travel": "0EA5E9",
            "pets": "84CC16",
            "urgent": "EF4444",
        ]
        return fixed[tag.lowercased()] ?? generateColor(for: tag)
    }

    // MARK: - Private

    private static func scoreText(_ text: String, existingUserTags: [String]) -> [String: Int] {
        let lowercased = text.lowercased()
        let words = lowercased.components(separatedBy: .whitespaces)
        var scores: [String: Int] = [:]

        for word in words {
            if let tags = keywordMappings[word] {
                for tag in tags { scores[tag, default: 0] += 2 }
            }
            for (keyword, tags) in keywordMappings {
                if word.contains(keyword) || keyword.contains(word) {
                    for tag in tags { scores[tag, default: 0] += 1 }
                }
            }
        }

        for userTag in existingUserTags {
            let lt = userTag.lowercased()
            if lowercased.contains(lt) {
                scores[userTag, default: 0] += 5
            }
            for word in words {
                if lt.contains(word) || word.contains(lt) {
                    scores[userTag, default: 0] += 3
                }
            }
        }

        return scores
    }

    private static func generateColor(for tag: String) -> String {
        let palette = ["8B5CF6", "EC4899", "F59E0B", "10B981", "06B6D4", "3B82F6", "F97316", "84CC16"]
        return palette[abs(tag.hashValue) % palette.count]
    }
}
