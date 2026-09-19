import Foundation

public struct ArbitrationResult: Sendable {
    public let isApproved: Bool
    public let grantedMinutes: Int
    public let grantedSeconds: Int
    public let decisionSummary: String
    public let reasoning: String
    public let taskTitle: String
    public let isDivertedToReminders: Bool
}

public final class IntentArbitrator: @unchecked Sendable {
    public static let shared = IntentArbitrator()
    
    private init() {}
    
    /// Evaluates spoken or typed intent based on the Agency Template:
    /// "I am going to go to bed [X] minutes past my bedtime so that I can [Action]. If I don't do this now, [Impact], and doing it now will [Value]."
    public func evaluate(spokenText: String, followUpHour: Int = 18, followUpMinute: Int = 0) -> ArbitrationResult {
        let sleepMetrics = HealthContextBridge.shared.fetchSleepMetrics()
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        
        // Calculate minutes past 10:00 PM curfew
        var minutesPastCurfew = 0
        if hour >= 22 {
            minutesPastCurfew = (hour - 22) * 60 + minute
        } else if hour < 5 {
            minutesPastCurfew = (hour + 2) * 60 + minute // After midnight
        }
        
        let textLower = spokenText.lowercased()
        
        // 1. Extract requested duration (support seconds for rapid testing)
        var requestedSeconds = 10 * 60
        var isSecondsTest = false
        
        let secRegex = try? NSRegularExpression(pattern: #"(\d+)\s*(?:seconds|second|secs|sec|s)\b"#, options: .caseInsensitive)
        let minRegex = try? NSRegularExpression(pattern: #"(\d+)\s*(?:minutes|mins|min|m)\b"#, options: .caseInsensitive)
        
        if let match = secRegex?.firstMatch(in: spokenText, range: NSRange(spokenText.startIndex..., in: spokenText)),
           let range = Range(match.range(at: 1), in: spokenText), let val = Int(spokenText[range]) {
            requestedSeconds = min(val, 300)
            isSecondsTest = true
        } else if let match = minRegex?.firstMatch(in: spokenText, range: NSRange(spokenText.startIndex..., in: spokenText)),
                  let range = Range(match.range(at: 1), in: spokenText), let val = Int(spokenText[range]) {
            requestedSeconds = min(val, 30) * 60
        }
        
        // 2. Extract Action / Task Title
        var extractedAction = "Late Night Task"
        let markers = ["so that i can", "so that I can", "so i can", "so I can", "in order to", "need to", "want to"]
        for marker in markers {
            if let range = spokenText.range(of: marker, options: .caseInsensitive) {
                let after = spokenText[range.upperBound...]
                let firstSentence = after.components(separatedBy: CharacterSet(charactersIn: ".!\n"))[0]
                let clean = firstSentence.trimmingCharacters(in: .whitespacesAndNewlines)
                if !clean.isEmpty && clean.count > 3 {
                    extractedAction = clean
                    break
                }
            }
        }
        
        // 3. Classify Urgency & Consequence
        let highUrgencyKeywords = [
            "deadline", "client", "emergency", "release", "mix", "send", "joe",
            "handoff", "upload", "broken", "fix", "deploy", "server", "bounce", "master", "deliver", "test"
        ]
        let lowUrgencyKeywords = [
            "look at", "explore", "learn", "browse", "tweak", "scroll", "watch",
            "read", "organize", "research", "youtube", "check"
        ]
        
        var urgencyScore = 3.0 // baseline (1-5)
        for kw in highUrgencyKeywords {
            if textLower.contains(kw) {
                urgencyScore += 1.0
            }
        }
        for kw in lowUrgencyKeywords {
            if textLower.contains(kw) {
                urgencyScore -= 1.0
            }
        }
        urgencyScore = max(1.0, min(5.0, urgencyScore))
        
        // 4. Multi-Factor Scoring Math
        var netScore = urgencyScore * 20.0
        
        // Penalty for minutes past curfew
        netScore -= Double(minutesPastCurfew) * 0.4
        
        // Penalty for cumulative 7-day sleep debt (relative to 8.0h target)
        netScore -= sleepMetrics.cumulativeSleepDebtHours * 4.0
        
        // Penalty if last night was below the critical 7.0h floor
        if sleepMetrics.lastNightHours < Config.minimumAcceptableSleepHours {
            let deficit = Config.minimumAcceptableSleepHours - sleepMetrics.lastNightHours
            netScore -= (deficit * 18.0)
        }
        
        // Penalty for consecutive days under 7.0h
        if sleepMetrics.consecutiveUnderSleptDays >= 2 {
            netScore -= Double(sleepMetrics.consecutiveUnderSleptDays) * 10.0
        }
        
        // 5. Decision Threshold (Passing score: 45.0)
        let isApproved = netScore >= 45.0
        
        if isApproved {
            let grantedSecs = min(requestedSeconds, 15 * 60)
            let grantedMins = max(1, grantedSecs / 60)
            let endObj = calendar.date(byAdding: .second, value: grantedSecs, to: now) ?? now
            let endTimeStr = DateFormatter.localizedString(from: endObj, dateStyle: .none, timeStyle: .short)
            
            let summary = isSecondsTest ? "Approved: \(grantedSecs)s window" : "Approved: \(grantedMins)m window"
            let reasoning = "Granted until \(endTimeStr)."
            
            return ArbitrationResult(
                isApproved: true,
                grantedMinutes: grantedMins,
                grantedSeconds: grantedSecs,
                decisionSummary: summary,
                reasoning: reasoning,
                taskTitle: extractedAction,
                isDivertedToReminders: false
            )
        } else {
            // Smart No: Divert to Apple Reminders (Default 6:00 PM)
            let notes = "Context: \(spokenText)\n7d Sleep Debt: \(sleepMetrics.cumulativeSleepDebtHours)h\nCurfew Offset: +\(minutesPastCurfew)m"
            RemindersBridge.shared.createSmartNoReminder(
                taskTitle: extractedAction.capitalized,
                notes: notes,
                dueHour: followUpHour,
                dueMinute: followUpMinute
            )
            
            let timeFmt = followUpHour > 12 ? "\(followUpHour - 12):\(String(format: "%02d", followUpMinute)) PM" : "\(followUpHour):\(String(format: "%02d", followUpMinute)) AM"
            let summary = "Request Denied"
            let reasoning = "7d sleep debt is \(sleepMetrics.cumulativeSleepDebtHours)h (< 8.0h target). Created follow-up in Reminders for tomorrow \(timeFmt)."
            
            return ArbitrationResult(
                isApproved: false,
                grantedMinutes: 0,
                grantedSeconds: 0,
                decisionSummary: summary,
                reasoning: reasoning,
                taskTitle: extractedAction,
                isDivertedToReminders: true
            )
        }
    }
}
