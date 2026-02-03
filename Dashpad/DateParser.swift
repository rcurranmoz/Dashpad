import Foundation

struct DateParser {
    
    /// Attempts to parse a natural language date from the input text
    /// Returns the parsed date and the cleaned text (with date portion removed)
    static func parse(_ input: String) -> (date: Date?, cleanedText: String) {
        let lowercased = input.lowercased()
        let calendar = Calendar.current
        let now = Date()
        
        var detectedDate: Date? = nil
        var cleanedText = input
        
        // Patterns to check (order matters - more specific first)
        let patterns: [(regex: String, handler: (String, [String]) -> Date?)] = [
            // "tomorrow at 3pm" or "tomorrow 3pm"
            (#"(tomorrow)\s*(?:at\s*)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?"#, { _, matches in
                guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else { return nil }
                return applyTime(to: tomorrow, hour: matches[1], minute: matches.count > 2 ? matches[2] : nil, period: matches.count > 3 ? matches[3] : nil)
            }),
            
            // "today at 3pm" or "today 3pm"
            (#"(today)\s*(?:at\s*)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?"#, { _, matches in
                return applyTime(to: now, hour: matches[1], minute: matches.count > 2 ? matches[2] : nil, period: matches.count > 3 ? matches[3] : nil)
            }),
            
            // "next tuesday" or "next tuesday 2pm"
            (#"(next)\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\s*(?:(?:at\s*)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?)?"#, { _, matches in
                guard let targetDate = nextWeekday(matches[1]) else { return nil }
                if matches.count > 2 && !matches[2].isEmpty {
                    return applyTime(to: targetDate, hour: matches[2], minute: matches.count > 3 ? matches[3] : nil, period: matches.count > 4 ? matches[4] : nil)
                }
                return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: targetDate)
            }),
            
            // "tuesday" or "tuesday 2pm" (this week or next)
            (#"(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\s*(?:(?:at\s*)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?)?"#, { _, matches in
                guard let targetDate = nextWeekday(matches[0]) else { return nil }
                if matches.count > 1 && !matches[1].isEmpty {
                    return applyTime(to: targetDate, hour: matches[1], minute: matches.count > 2 ? matches[2] : nil, period: matches.count > 3 ? matches[3] : nil)
                }
                return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: targetDate)
            }),
            
            // "in 2 hours" or "in 30 minutes"
            (#"in\s+(\d+)\s*(hour|hr|minute|min)s?"#, { _, matches in
                guard let value = Int(matches[0]) else { return nil }
                let unit = matches[1]
                if unit.starts(with: "hour") || unit.starts(with: "hr") {
                    return calendar.date(byAdding: .hour, value: value, to: now)
                } else {
                    return calendar.date(byAdding: .minute, value: value, to: now)
                }
            }),
            
            // "in 2 days" or "in a week"
            (#"in\s+(\d+|a|one)\s*(day|week)s?"#, { _, matches in
                let valueStr = matches[0]
                let value = (valueStr == "a" || valueStr == "one") ? 1 : (Int(valueStr) ?? 1)
                let unit = matches[1]
                if unit.starts(with: "week") {
                    return calendar.date(byAdding: .day, value: value * 7, to: now)
                } else {
                    return calendar.date(byAdding: .day, value: value, to: now)
                }
            }),
            
            // "tomorrow" (standalone)
            (#"\btomorrow\b"#, { _, _ in
                guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else { return nil }
                return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow)
            }),
            
            // "today" (standalone)
            (#"\btoday\b"#, { _, _ in
                return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now)
            }),
            
            // "tonight"
            (#"\btonight\b"#, { _, _ in
                return calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now)
            }),
            
            // "this morning"
            (#"this\s+morning"#, { _, _ in
                return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now)
            }),
            
            // "this afternoon"
            (#"this\s+afternoon"#, { _, _ in
                return calendar.date(bySettingHour: 14, minute: 0, second: 0, of: now)
            }),
            
            // "this evening"
            (#"this\s+evening"#, { _, _ in
                return calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now)
            }),
            
            // "end of day" or "eod"
            (#"\b(eod|end of day)\b"#, { _, _ in
                return calendar.date(bySettingHour: 17, minute: 0, second: 0, of: now)
            }),
            
            // "mm/dd" or "m/d" - assumes current year
            (#"\b(\d{1,2})/(\d{1,2})\b"#, { _, matches in
                guard let month = Int(matches[0]), let day = Int(matches[1]) else { return nil }
                var components = calendar.dateComponents([.year], from: now)
                components.month = month
                components.day = day
                components.hour = 9
                components.minute = 0
                return calendar.date(from: components)
            }),
        ]
        
        // Try each pattern
        for (pattern, handler) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(lowercased.startIndex..., in: lowercased)
                if let match = regex.firstMatch(in: lowercased, options: [], range: range) {
                    // Extract captured groups
                    var captures: [String] = []
                    for i in 1..<match.numberOfRanges {
                        if let captureRange = Range(match.range(at: i), in: lowercased) {
                            captures.append(String(lowercased[captureRange]))
                        } else {
                            captures.append("")
                        }
                    }
                    
                    if let date = handler(lowercased, captures) {
                        detectedDate = date
                        
                        // Remove the matched portion from the text
                        if let matchRange = Range(match.range, in: input) {
                            cleanedText = input.replacingCharacters(in: matchRange, with: "")
                            cleanedText = cleanedText.trimmingCharacters(in: .whitespaces)
                            // Clean up double spaces
                            while cleanedText.contains("  ") {
                                cleanedText = cleanedText.replacingOccurrences(of: "  ", with: " ")
                            }
                        }
                        break
                    }
                }
            }
        }
        
        return (detectedDate, cleanedText.isEmpty ? input : cleanedText)
    }
    
    // MARK: - Helpers
    
    private static func applyTime(to date: Date, hour: String, minute: String?, period: String?) -> Date? {
        let calendar = Calendar.current
        guard var hourInt = Int(hour) else { return nil }
        let minuteInt = minute.flatMap { Int($0) } ?? 0
        
        // Handle AM/PM
        if let p = period?.lowercased() {
            if p == "pm" && hourInt < 12 {
                hourInt += 12
            } else if p == "am" && hourInt == 12 {
                hourInt = 0
            }
        } else {
            // No AM/PM specified - assume PM for hours 1-6, AM for 7-11
            if hourInt >= 1 && hourInt <= 6 {
                hourInt += 12
            }
        }
        
        return calendar.date(bySettingHour: hourInt, minute: minuteInt, second: 0, of: date)
    }
    
    private static func nextWeekday(_ name: String) -> Date? {
        let calendar = Calendar.current
        let weekdays = ["sunday": 1, "monday": 2, "tuesday": 3, "wednesday": 4, "thursday": 5, "friday": 6, "saturday": 7]
        
        guard let targetWeekday = weekdays[name.lowercased()] else { return nil }
        
        let today = calendar.component(.weekday, from: Date())
        var daysToAdd = targetWeekday - today
        
        if daysToAdd <= 0 {
            daysToAdd += 7 // Next week
        }
        
        return calendar.date(byAdding: .day, value: daysToAdd, to: Date())
    }
    
    /// Formats a date for display in a friendly way
    static func formatForDisplay(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let timeString = timeFormatter.string(from: date).lowercased()
        
        if calendar.isDateInToday(date) {
            return "Today \(timeString)"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow \(timeString)"
        } else if let daysUntil = calendar.dateComponents([.day], from: now, to: date).day, daysUntil < 7 {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE"
            return "\(dayFormatter.string(from: date)) \(timeString)"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            return "\(dateFormatter.string(from: date)) \(timeString)"
        }
    }
}
