import Cocoa

@MainActor
public final class AppTracker {
    public static let shared = AppTracker()
    
    public private(set) var activeAppName: String = "Finder"
    public private(set) var activeAppBundleId: String = ""
    
    public var onAppChanged: ((String) -> Void)?
    
    private init() {}
    
    public func start() {
        if let frontmost = NSWorkspace.shared.frontmostApplication {
            handleAppActivated(frontmost)
        }
        
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }
    
    @objc private func appDidActivate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        handleAppActivated(app)
    }
    
    private func handleAppActivated(_ app: NSRunningApplication) {
        let name = app.localizedName ?? "Unknown"
        let bundleId = app.bundleIdentifier ?? ""
        
        self.activeAppName = name
        self.activeAppBundleId = bundleId
        
        self.onAppChanged?(name)
    }
}
