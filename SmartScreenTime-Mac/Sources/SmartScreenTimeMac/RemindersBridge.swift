import Cocoa
import Foundation

public final class RemindersBridge: @unchecked Sendable {
    public static let shared = RemindersBridge()
    
    private init() {}
    
    /// Creates a high-priority follow-up reminder in Apple Reminders scheduled for tomorrow 6:00 PM.
    /// This immediately syncs across iCloud to your iPhone Reminders app.
    @discardableResult
    public func createSmartNoReminder(
        taskTitle: String,
        notes: String,
        dueHour: Int = 18,
        dueMinute: Int = 0
    ) -> Bool {
        let cleanTitle = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let escapedTitle = cleanTitle.replacingOccurrences(of: "\"", with: "\\\"")
        let escapedNotes = notes.replacingOccurrences(of: "\"", with: "\\\"")
        
        // Native AppleScript date math avoids all locale string parsing errors
        let secondsFromMidnight = (dueHour * 3600) + (dueMinute * 60)
        
        let scriptSource = """
        tell application "Reminders"
            set targetList to default list
            set tomorrowDate to (current date) + (1 * days)
            set time of tomorrowDate to \(secondsFromMidnight)
            tell targetList
                make new reminder with properties {name:"\(escapedTitle)", body:"\(escapedNotes)", due date:tomorrowDate, priority:1}
            end tell
        end tell
        """
        
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            if let script = NSAppleScript(source: scriptSource) {
                let result = script.executeAndReturnError(&error)
                if let error = error {
                    print("[RemindersBridge] Error creating reminder: \(error)")
                } else {
                    print("[RemindersBridge] Created iPhone follow-up task for 6:00 PM: \(result.stringValue ?? "done")")
                }
            }
        }
        
        return true
    }
    
    @MainActor
    public func openRemindersApp() {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.reminders") {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
        }
    }
}
