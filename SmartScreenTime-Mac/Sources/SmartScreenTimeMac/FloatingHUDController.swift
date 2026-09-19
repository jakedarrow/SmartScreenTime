import Cocoa

@MainActor
public final class FloatingHUDController: NSObject {
    public static let shared = FloatingHUDController()
    
    private var window: NSPanel?
    private var visualEffect: NSVisualEffectView?
    private var primaryLabel: NSTextField?
    private var secondaryLabel: NSTextField?
    private var actionButton: NSButton?
    
    public var onTaskCompleteClicked: (() -> Void)?
    public var onEmergencyResolveClicked: (() -> Void)?
    
    private var isEmergencyMode: Bool = false
    
    private override init() {
        super.init()
    }
    
    public func show(taskName: String, initialSeconds: Int) {
        isEmergencyMode = false
        if window == nil {
            createWindow()
        }
        
        configureForTask(taskName: taskName, seconds: initialSeconds)
        presentWindow()
    }
    
    public func showEmergency(reason: String) {
        isEmergencyMode = true
        if window == nil {
            createWindow()
        }
        
        configureForEmergency(reason: reason)
        presentWindow()
    }
    
    public func hide() {
        window?.orderOut(nil)
    }
    
    public func updateTime(seconds: Int) {
        guard !isEmergencyMode else { return }
        let mins = max(0, seconds) / 60
        let secs = max(0, seconds) % 60
        primaryLabel?.stringValue = String(format: "%02d:%02d", mins, secs)
    }
    
    private func presentWindow() {
        guard let win = window else { return }
        
        // Ensure position at top center of primary display
        if let screen = NSScreen.main ?? NSScreen.screens.first {
            let screenRect = screen.visibleFrame
            let x = screenRect.midX - (win.frame.width / 2)
            let y = screenRect.maxY - win.frame.height - 12
            win.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        win.orderFrontRegardless()
        win.makeKeyAndOrderFront(nil)
    }
    
    private func configureForTask(taskName: String, seconds: Int) {
        let mins = max(0, seconds) / 60
        let secs = max(0, seconds) % 60
        primaryLabel?.stringValue = String(format: "%02d:%02d", mins, secs)
        primaryLabel?.textColor = NSColor.systemBlue
        
        secondaryLabel?.stringValue = taskName
        secondaryLabel?.textColor = NSColor.labelColor
        
        actionButton?.title = "Task Complete"
        actionButton?.target = self
        actionButton?.action = #selector(handleActionClicked)
        
        visualEffect?.layer?.borderColor = NSColor.white.withAlphaComponent(0.15).cgColor
    }
    
    private func configureForEmergency(reason: String) {
        primaryLabel?.stringValue = "EMERGENCY"
        primaryLabel?.textColor = NSColor.systemRed
        
        secondaryLabel?.stringValue = reason.isEmpty ? "Override Active" : reason
        secondaryLabel?.textColor = NSColor.white
        
        actionButton?.title = "Resolve Emergency"
        actionButton?.target = self
        actionButton?.action = #selector(handleActionClicked)
        
        visualEffect?.layer?.borderColor = NSColor.systemRed.withAlphaComponent(0.5).cgColor
    }
    
    private func createWindow() {
        let panelWidth: CGFloat = 390
        let panelHeight: CGFloat = 46
        
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        
        panel.isMovableByWindowBackground = true
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        
        let effect = NSVisualEffectView(frame: panel.contentView!.bounds)
        effect.autoresizingMask = [.width, .height]
        effect.material = .hudWindow
        effect.state = .active
        effect.blendingMode = .behindWindow
        effect.wantsLayer = true
        effect.layer?.cornerRadius = 23
        effect.layer?.masksToBounds = true
        effect.layer?.borderColor = NSColor.white.withAlphaComponent(0.15).cgColor
        effect.layer?.borderWidth = 1.2
        panel.contentView?.addSubview(effect)
        self.visualEffect = effect
        
        // Primary Badge / Time Label
        let pLabel = NSTextField(labelWithString: "15:00")
        pLabel.frame = NSRect(x: 16, y: 12, width: 85, height: 22)
        pLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .bold)
        pLabel.textColor = NSColor.systemBlue
        effect.addSubview(pLabel)
        self.primaryLabel = pLabel
        
        // Secondary Title / Reason Label
        let sLabel = NSTextField(labelWithString: "Active Task")
        sLabel.frame = NSRect(x: 104, y: 12, width: 140, height: 22)
        sLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        sLabel.textColor = NSColor.labelColor
        sLabel.lineBreakMode = .byTruncatingTail
        effect.addSubview(sLabel)
        self.secondaryLabel = sLabel
        
        // Action Button
        let btn = NSButton(title: "Task Complete", target: self, action: #selector(handleActionClicked))
        btn.frame = NSRect(x: 250, y: 8, width: 130, height: 30)
        btn.bezelStyle = .rounded
        btn.font = NSFont.systemFont(ofSize: 11, weight: .bold)
        effect.addSubview(btn)
        self.actionButton = btn
        
        self.window = panel
    }
    
    @objc private func handleActionClicked() {
        hide()
        if isEmergencyMode {
            onEmergencyResolveClicked?()
        } else {
            onTaskCompleteClicked?()
        }
    }
}
