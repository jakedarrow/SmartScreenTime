import Foundation

/// Central code-defined configuration for SmartScreenTime.
/// Modify these properties directly in code to customize your rules.
public struct Config: Sendable {
    // MARK: - Bedtime & Curfew Rules
    public static let weeknightBedtimeStartHour = 22  // 10:00 PM (Curfew starts)
    public static let weeknightBedtimeEndHour = 5     // 5:00 AM (Curfew lifts)
    
    // Optimal sleep baseline (8.0h for athletic & cognitive recovery). Jake feels terrible under 7.0h.
    public static let targetSleepHours: Double = 8.0
    public static let minimumAcceptableSleepHours: Double = 7.0
    
    // MARK: - Weekend Rules
    public static let weekendAllowedApps = [
        "Logic Pro", "Xcode", "Visual Studio Code", "Terminal", "Finder", "Ableton Live"
    ]
    public static let weekendAlwaysBlockedDomains = [
        "youtube.com", "instagram.com", "reddit.com", "twitter.com", "x.com", "tiktok.com"
    ]
    
    // MARK: - Social Stake / Emergency Contact
    /// Phone number or Apple ID / contact name to receive accountability SMS.
    public static let girlfriendContact = "+14253616679"
    
    // MARK: - Ambient Chime
    public static let chimeIntervalSeconds: TimeInterval = 60.0
    
    // MARK: - HealthKit DB Path
    public static let healthDbPath = "/Users/jakedarrow/Documents/Developer/PersonalTrainer/data/healthkit_history.db"
    
    // MARK: - Key Wi-Fi Networks
    public static let workWifiSSIDs = ["PACCARGuest", "PACCAR", "Work"]
    public static let homeWifiSSIDs = ["Wuffen"]
    public static let girlfriendWifiSSIDs = ["Winnie's world", "Winnie's World", "Winifred"]
    
    // MARK: - Developer / Testing Mode
    /// When true, simulates active bedtime curfew during the day so you can test all lock/arbitration/SMS features.
    public static let debugForceCurfewActive: Bool = false
}
