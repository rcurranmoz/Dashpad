import Foundation

struct TagPredictor {
    
    // Common keyword -> tag mappings (supports multiple tags per keyword)
    private static let keywordMappings: [String: [String]] = [
        // Work
        "meeting": ["work"],
        "email": ["work"],
        "call": ["work", "family"],  // Can be work call or family call
        "presentation": ["work"],
        "deadline": ["work"],
        "project": ["work"],
        "client": ["work"],
        "boss": ["work"],
        "coworker": ["work"],
        "office": ["work"],
        "slack": ["work"],
        "zoom": ["work"],
        "report": ["work"],
        "review": ["work"],
        
        // Family
        "mom": ["family"],
        "dad": ["family"],
        "parent": ["family"],
        "kid": ["family"],
        "kids": ["family"],
        "son": ["family"],
        "daughter": ["family"],
        "wife": ["family"],
        "husband": ["family"],
        "brother": ["family"],
        "sister": ["family"],
        "family": ["family"],
        "birthday": ["family", "social"],
        "anniversary": ["family"],
        
        // Home
        "clean": ["home"],
        "laundry": ["home"],
        "dishes": ["home"],
        "vacuum": ["home"],
        "trash": ["home"],
        "garbage": ["home"],
        "groceries": ["home", "shopping"],
        "grocery": ["home"],
        "cook": ["home"],
        "repair": ["home"],
        "fix": ["home"],
        "mow": ["home"],
        "lawn": ["home"],
        "garden": ["home"],
        
        // Health
        "doctor": ["health"],
        "dentist": ["health"],
        "appointment": ["health", "work"],
        "gym": ["health"],
        "workout": ["health"],
        "exercise": ["health"],
        "run": ["health"],
        "medicine": ["health"],
        "prescription": ["health"],
        "vitamin": ["health"],
        
        // Finance
        "pay": ["finance"],
        "bill": ["finance"],
        "rent": ["finance"],
        "mortgage": ["finance"],
        "insurance": ["finance"],
        "tax": ["finance"],
        "taxes": ["finance"],
        "bank": ["finance"],
        "transfer": ["finance"],
        "budget": ["finance"],
        
        // Shopping
        "buy": ["shopping"],
        "order": ["shopping"],
        "amazon": ["shopping"],
        "return": ["shopping"],
        "pickup": ["shopping"],
        "store": ["shopping"],
        "mall": ["shopping"],
        
        // Social
        "friend": ["social"],
        "friends": ["social"],
        "party": ["social"],
        "dinner": ["social"],
        "lunch": ["social", "work"],
        "drinks": ["social"],
        "hangout": ["social"],
        "visit": ["social", "family"],
        
        // Travel
        "flight": ["travel"],
        "hotel": ["travel"],
        "book": ["travel"],
        "passport": ["travel"],
        "trip": ["travel"],
        "vacation": ["travel"],
        "pack": ["travel"],
        "airport": ["travel"],
        
        // Pets
        "dog": ["pets"],
        "cat": ["pets"],
        "vet": ["pets"],
        "walk": ["pets", "health"],
        "feed": ["pets"],
        "pet": ["pets"]
    ]
    
    /// Suggests tags based on the input text and existing user tags
    /// Returns up to 3 suggestions, prioritizing user's existing tags
    static func suggestTags(for text: String, existingUserTags: [String]) -> [String] {
        let lowercasedText = text.lowercased()
        let words = lowercasedText.components(separatedBy: .whitespaces)
        
        var scores: [String: Int] = [:]
        
        // Check keyword mappings
        for word in words {
            if let tags = keywordMappings[word] {
                for tag in tags {
                    scores[tag, default: 0] += 2
                }
            }
            
            // Partial matches
            for (keyword, tags) in keywordMappings {
                if word.contains(keyword) || keyword.contains(word) {
                    for tag in tags {
                        scores[tag, default: 0] += 1
                    }
                }
            }
        }
        
        // Boost tags the user has used before
        for userTag in existingUserTags {
            let lowercasedTag = userTag.lowercased()
            
            // Direct mention of tag
            if lowercasedText.contains(lowercasedTag) {
                scores[userTag, default: 0] += 5
            }
            
            // Check if any word relates to user's existing tags
            for word in words {
                if lowercasedTag.contains(word) || word.contains(lowercasedTag) {
                    scores[userTag, default: 0] += 3
                }
            }
        }
        
        // Sort by score and take top 3
        let suggestions = scores
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
        
        return suggestions
    }
    
    /// Default tag colors for common tags
    static func color(for tag: String) -> String {
        let colors: [String: String] = [
            "work": "6366F1",      // Indigo
            "family": "EC4899",    // Pink
            "home": "F59E0B",      // Amber
            "health": "10B981",    // Emerald
            "finance": "06B6D4",   // Cyan
            "shopping": "8B5CF6",  // Purple
            "social": "F97316",    // Orange
            "travel": "3B82F6",    // Blue
            "pets": "84CC16",      // Lime
            "urgent": "EF4444"     // Red
        ]
        
        return colors[tag.lowercased()] ?? generateColor(for: tag)
    }
    
    /// Generate a consistent color for custom tags
    private static func generateColor(for tag: String) -> String {
        let colors = [
            "8B5CF6", "EC4899", "F59E0B", "10B981",
            "06B6D4", "3B82F6", "F97316", "84CC16"
        ]
        
        let hash = abs(tag.hashValue)
        return colors[hash % colors.count]
    }
}
