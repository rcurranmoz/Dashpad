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
            
            // "next week" or "next month"
            (#"next\s+(week|month)\b"#, { _, matches in
                let component: Calendar.Component = matches[0] == "month" ? .month : .weekOfYear
                guard let target = calendar.date(byAdding: component, value: 1, to: now) else { return nil }
                return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: target)
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
            
            // "june 12" / "June 12th" — rolls into next year if already past
            (#"\b(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|jun|jul|aug|sept?|oct|nov|dec)\.?\s+(\d{1,2})(?:st|nd|rd|th)?\b"#, { _, matches in
                let monthNames = ["jan": 1, "feb": 2, "mar": 3, "apr": 4, "may": 5, "jun": 6,
                                  "jul": 7, "aug": 8, "sep": 9, "oct": 10, "nov": 11, "dec": 12]
                guard let month = monthNames[String(matches[0].prefix(3))],
                      let day = Int(matches[1]), (1...31).contains(day) else { return nil }
                var components = calendar.dateComponents([.year], from: now)
                components.month = month
                components.day = day
                components.hour = 9
                components.minute = 0
                guard let date = calendar.date(from: components) else { return nil }
                if date < now, let next = calendar.date(byAdding: .year, value: 1, to: date) { return next }
                return date
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
        
        // Try each regex pattern
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
        
        // Second chance: system data detector covers phrasings the regexes
        // don't ("june 12", "next month", "12/25 at noon"). Future dates only —
        // the detector happily resolves "june 12" into the past.
        if detectedDate == nil,
           let match = dataDetectorMatch(in: input),
           let date = futureDate(from: match.date, now: now) {
            detectedDate = date
            if let matchRange = Range(match.range, in: input) {
                cleanedText = input.replacingCharacters(in: matchRange, with: "")
                    .trimmingCharacters(in: .whitespaces)
                while cleanedText.contains("  ") {
                    cleanedText = cleanedText.replacingOccurrences(of: "  ", with: " ")
                }
            }
        }

        // Removing a date phrase can leave a dangling preposition
        // ("renew registration before"). Trim it.
        if detectedDate != nil {
            let danglers: Set<String> = ["before", "by", "on", "at", "due", "until", "for"]
            var words = cleanedText.split(separator: " ").map(String.init)
            while let last = words.last, danglers.contains(last.lowercased()) {
                words.removeLast()
            }
            cleanedText = words.joined(separator: " ")
        }

        return (detectedDate, cleanedText.isEmpty ? input : cleanedText)
    }

    /// Best-effort date extraction from an arbitrary phrase, used when the
    /// on-device model pulls out a due-date phrase the regexes can't handle.
    static func detectorDate(in text: String) -> Date? {
        futureDate(from: dataDetectorMatch(in: text)?.date, now: Date())
    }

    /// The detector resolves phrases like "june 12" into the current year even
    /// when that's already past; roll those forward a year. Anything further
    /// back is a genuinely past date the user didn't mean as a due date.
    private static func futureDate(from date: Date?, now: Date) -> Date? {
        guard let date else { return nil }
        if date > now { return date }
        if let bumped = Calendar.current.date(byAdding: .year, value: 1, to: date),
           now.timeIntervalSince(date) < 60 * 60 * 24 * 366 {
            return bumped
        }
        return nil
    }

    private static func dataDetectorMatch(in text: String) -> NSTextCheckingResult? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        return detector.firstMatch(in: text, options: [], range: range)
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
