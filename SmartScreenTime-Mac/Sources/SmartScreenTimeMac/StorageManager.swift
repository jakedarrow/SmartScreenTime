import Foundation

public struct AppState: Codable, Sendable {
    public var focusModeActive: Bool
    public var currentSessionName: String
    public var dailyLimitMinutes: Int
    public var todayMinutesSpent: Int
    public var lastDateString: String
    public var consecutiveBypassesTonight: Int
    
    public static var `default`: AppState {
        AppState(
            focusModeActive: false,
            currentSessionName: "Deep Focus",
            dailyLimitMinutes: 45,
            todayMinutesSpent: 0,
            lastDateString: DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none),
            consecutiveBypassesTonight: 0
        )
    }
}

public final class StorageManager: @unchecked Sendable {
    public static let shared = StorageManager()
    
    private let fileURL: URL
    private let lock = NSLock()
    public private(set) var state: AppState
    
    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("SmartScreenTime", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("state.json")
        
        if let data = try? Data(contentsOf: fileURL),
           let loaded = try? JSONDecoder().decode(AppState.self, from: data) {
            self.state = loaded
        } else {
            self.state = .default
        }
        
        checkDayRollover()
    }
    
    public func update(_ block: (inout AppState) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        block(&state)
        save()
    }
    
    private func checkDayRollover() {
        let todayStr = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        if state.lastDateString != todayStr {
            state.lastDateString = todayStr
            state.todayMinutesSpent = 0
            state.consecutiveBypassesTonight = 0
            save()
        }
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(state) {
            try? data.write(to: fileURL)
        }
    }
}
