import Cocoa

// MARK: - Custom Keyable Lock Window
public final class KeyableLockWindow: NSWindow {
    public override var canBecomeKey: Bool { return true }
    public override var canBecomeMain: Bool { return true }
    
    public var onEscapePressed: (() -> Void)?
    public var onCommandQPressed: (() -> Void)?
    
    public override func keyDown(with event: NSEvent) {
        // Escape key (keyCode 53)
        if event.keyCode == 53 {
            onEscapePressed?()
            return
        }
        // Cmd+Q
        if event.keyCode == 12 && event.modifierFlags.contains(.command) {
            onCommandQPressed?()
            return
        }
        super.keyDown(with: event)
    }
}

// MARK: - Curfew Lock Screen Controller
@MainActor
public final class CurfewLockScreenController: NSObject {
    public static let shared = CurfewLockScreenController()
    
    private var lockWindows: [KeyableLockWindow] = []
    private var previewWindow: NSWindow?
    
    public private(set) var isLocked: Bool = false
    public private(set) var isTestMode: Bool = false
    public private(set) var isPreviewMode: Bool = false
    
    // Card State Management
    private enum CardState {
        case overview
        case requestTask
        case smartNoResult(ArbitrationResult)
        case emergencyOverride
    }
    
    private var currentCardState: CardState = .overview
    private weak var primaryCardView: NSView?
    
    // Test Mode Safety Auto-Dismiss Timer
    private var testModeTimer: Timer?
    private var testModeSecondsRemaining: Int = 60
    private weak var testModeLabel: NSTextField?
    
    // Callbacks
    public var onRequestApproved: ((_ result: ArbitrationResult) -> Void)?
    public var onEmergencyApproved: ((_ reason: String) -> Void)?
    public var onExitTestModeRequested: (() -> Void)?
    
    private override init() {
        super.init()
    }
    
    // MARK: - Windowed Preview Mode (100% Zero Risk Sandbox)
    public func showWindowedPreview() {
        if isLocked { unlockAllScreens() }
        closePreview()
        
        isPreviewMode = true
        self.currentCardState = .overview
        
        let cardWidth: CGFloat = 520
        let cardHeight: CGFloat = 370
        
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: cardWidth, height: cardHeight),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        win.title = "Curfew Preview (Zero-Risk Safe Sandbox)"
        win.center()
        win.isReleasedWhenClosed = false
        
        let card = NSView(frame: win.contentView!.bounds)
        card.autoresizingMask = [.width, .height]
        card.wantsLayer = true
        card.layer?.backgroundColor = NSColor(calibratedRed: 0.09, green: 0.12, blue: 0.18, alpha: 1.0).cgColor
        win.contentView?.addSubview(card)
        
        self.primaryCardView = card
        renderCurrentCardState()
        
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.previewWindow = win
    }
    
    public func closePreview() {
        isPreviewMode = false
        previewWindow?.close()
        previewWindow = nil
    }
    
    // MARK: - Full Screen Lock Mode
    public func lockAllScreens(isTestMode: Bool = false) {
        guard !isLocked else { return }
        closePreview()
        
        self.isLocked = true
        self.isTestMode = isTestMode
        self.currentCardState = .overview
        
        dismissAllWindows()
        
        for (index, screen) in NSScreen.screens.enumerated() {
            let win = createLockWindow(for: screen, isPrimary: index == 0)
            lockWindows.append(win)
            win.orderFrontRegardless()
            if index == 0 {
                win.makeKeyAndOrderFront(nil)
            }
        }
        
        NSApp.activate(ignoringOtherApps: true)
        
        if isTestMode {
            startTestModeSafetyTimer()
        }
    }
    
    public func unlockAllScreens() {
        guard isLocked || isPreviewMode else { return }
        self.isLocked = false
        self.isTestMode = false
        closePreview()
        stopTestModeSafetyTimer()
        dismissAllWindows()
    }
    
    private func dismissAllWindows() {
        stopTestModeSafetyTimer()
        for win in lockWindows {
            win.orderOut(nil)
        }
        lockWindows.removeAll()
        primaryCardView = nil
    }
    
    // MARK: - Test Mode Auto-Dismiss Timer
    private func startTestModeSafetyTimer() {
        stopTestModeSafetyTimer()
        testModeSecondsRemaining = 60
        updateTestModeLabelText()
        
        testModeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.testModeSecondsRemaining -= 1
                self.updateTestModeLabelText()
                if self.testModeSecondsRemaining <= 0 {
                    self.stopTestModeSafetyTimer()
                    self.onExitTestModeRequested?()
                }
            }
        }
    }
    
    private func stopTestModeSafetyTimer() {
        testModeTimer?.invalidate()
        testModeTimer = nil
    }
    
    private func updateTestModeLabelText() {
        guard isTestMode else { return }
        testModeLabel?.stringValue = "Test Mode Active (Auto-unlocks in \(testModeSecondsRemaining)s) • Press Esc to Exit"
    }
    
    // MARK: - Window Creation
    private func createLockWindow(for screen: NSScreen, isPrimary: Bool) -> KeyableLockWindow {
        let frame = screen.frame
        let window = KeyableLockWindow(
            contentRect: frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)) + 1)
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = false
        
        window.onEscapePressed = { [weak self] in
            guard let self = self else { return }
            if self.isTestMode {
                self.onExitTestModeRequested?()
            } else if case .overview = self.currentCardState {
                // Already at root overview
            } else {
                self.switchCardState(.overview)
            }
        }
        
        window.onCommandQPressed = {
            NSApplication.shared.terminate(nil)
        }
        
        let visualEffect = NSVisualEffectView(frame: window.contentView!.bounds)
        visualEffect.autoresizingMask = [.width, .height]
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.blendingMode = .behindWindow
        visualEffect.wantsLayer = true
        visualEffect.layer?.backgroundColor = NSColor(calibratedRed: 0.04, green: 0.05, blue: 0.08, alpha: 0.96).cgColor
        window.contentView?.addSubview(visualEffect)
        
        if isPrimary {
            let cardWidth: CGFloat = 520
            let cardHeight: CGFloat = 370
            let cardX = (frame.width - cardWidth) / 2
            let cardY = (frame.height - cardHeight) / 2
            
            let card = NSView(frame: NSRect(x: cardX, y: cardY, width: cardWidth, height: cardHeight))
            card.wantsLayer = true
            card.layer?.backgroundColor = NSColor(calibratedRed: 0.09, green: 0.12, blue: 0.18, alpha: 0.98).cgColor
            card.layer?.cornerRadius = 18
            card.layer?.borderColor = NSColor.white.withAlphaComponent(0.12).cgColor
            card.layer?.borderWidth = 1.0
            card.layer?.shadowColor = NSColor.black.cgColor
            card.layer?.shadowOpacity = 0.6
            card.layer?.shadowRadius = 32
            visualEffect.addSubview(card)
            
            self.primaryCardView = card
            renderCurrentCardState()
            
            // Test Mode Banner
            if isTestMode {
                let banner = NSView(frame: NSRect(x: (frame.width - 480) / 2, y: cardY + cardHeight + 16, width: 480, height: 36))
                banner.wantsLayer = true
                banner.layer?.backgroundColor = NSColor.systemYellow.withAlphaComponent(0.15).cgColor
                banner.layer?.cornerRadius = 18
                banner.layer?.borderColor = NSColor.systemYellow.withAlphaComponent(0.5).cgColor
                banner.layer?.borderWidth = 1.0
                
                let label = NSTextField(labelWithString: "Test Mode Active (Auto-unlocks in 60s) • Press Esc to Exit")
                label.frame = NSRect(x: 16, y: 8, width: 340, height: 20)
                label.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .bold)
                label.textColor = NSColor.systemYellow
                banner.addSubview(label)
                self.testModeLabel = label
                
                let exitBtn = NSButton(title: "Exit Test", target: self, action: #selector(handleExitTestClicked))
                exitBtn.frame = NSRect(x: 365, y: 4, width: 95, height: 28)
                exitBtn.bezelStyle = .rounded
                exitBtn.font = NSFont.systemFont(ofSize: 11, weight: .bold)
                banner.addSubview(exitBtn)
                
                visualEffect.addSubview(banner)
            }
        }
        
        return window
    }
    
    // MARK: - Card State Views Rendering
    private func switchCardState(_ state: CardState) {
        self.currentCardState = state
        renderCurrentCardState()
    }
    
    private func renderCurrentCardState() {
        guard let card = primaryCardView else { return }
        card.subviews.forEach { $0.removeFromSuperview() }
        
        let cardWidth = card.bounds.width
        let cardHeight = card.bounds.height
        
        switch currentCardState {
        case .overview:
            renderOverviewView(in: card, width: cardWidth, height: cardHeight)
        case .requestTask:
            renderRequestTaskView(in: card, width: cardWidth, height: cardHeight)
        case .smartNoResult(let result):
            renderSmartNoView(in: card, width: cardWidth, height: cardHeight, result: result)
        case .emergencyOverride:
            renderEmergencyView(in: card, width: cardWidth, height: cardHeight)
        }
    }
    
    // MARK: 1. Overview View
    private func renderOverviewView(in card: NSView, width: CGFloat, height: CGFloat) {
        let sleep = HealthContextBridge.shared.fetchSleepMetrics()
        
        // Status Badge Header
        let badge = NSTextField(labelWithString: isPreviewMode ? "SANDBOX PREVIEW" : (isTestMode ? "TEST MODE" : "BEDTIME CURFEW ACTIVE"))
        badge.frame = NSRect(x: (width - 220) / 2, y: height - 44, width: 220, height: 18)
        badge.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .heavy)
        badge.textColor = isPreviewMode ? NSColor.systemTeal : (isTestMode ? NSColor.systemYellow : NSColor.systemOrange)
        badge.alignment = .center
        card.addSubview(badge)
        
        // Title
        let titleLabel = NSTextField(labelWithString: "Locked for Sleep Recovery")
        titleLabel.frame = NSRect(x: 20, y: height - 82, width: width - 40, height: 32)
        titleLabel.font = NSFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = NSColor.white
        titleLabel.alignment = .center
        card.addSubview(titleLabel)
        
        // Subtitle
        let subLabel = NSTextField(labelWithString: "Screen time is locked until 5:00 AM. Work state remains saved in memory.")
        subLabel.frame = NSRect(x: 30, y: height - 116, width: width - 60, height: 28)
        subLabel.font = NSFont.systemFont(ofSize: 13)
        subLabel.textColor = NSColor(calibratedWhite: 0.72, alpha: 1.0)
        subLabel.alignment = .center
        card.addSubview(subLabel)
        
        // Sleep Context Pill
        let sleepPill = NSTextField(labelWithString: "Last Night: \(sleep.lastNightHours)h  •  7-Day Cumulative Debt: \(sleep.cumulativeSleepDebtHours)h")
        sleepPill.frame = NSRect(x: 30, y: height - 150, width: width - 60, height: 22)
        sleepPill.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        sleepPill.textColor = NSColor(calibratedRed: 0.65, green: 0.82, blue: 1.0, alpha: 1.0)
        sleepPill.alignment = .center
        card.addSubview(sleepPill)
        
        // Hero Primary Button: Sleep Mac (Return / Space triggers sleep immediately)
        let sleepMacBtn = NSButton(title: "Sleep Mac (Return)", target: self, action: #selector(handleSleepMacClicked))
        sleepMacBtn.frame = NSRect(x: 40, y: height - 222, width: width - 80, height: 50)
        sleepMacBtn.bezelStyle = .rounded
        sleepMacBtn.font = NSFont.systemFont(ofSize: 15, weight: .bold)
        sleepMacBtn.keyEquivalent = "\r"
        card.addSubview(sleepMacBtn)
        
        // Secondary Action Buttons Row
        let reqBtn = NSButton(title: "Request Late-Night Task", target: self, action: #selector(handleRequestClicked))
        reqBtn.frame = NSRect(x: 40, y: height - 286, width: (width - 95) / 2, height: 40)
        reqBtn.bezelStyle = .rounded
        reqBtn.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        card.addSubview(reqBtn)
        
        let emerBtn = NSButton(title: "Emergency Override", target: self, action: #selector(handleEmergencyClicked))
        emerBtn.frame = NSRect(x: 55 + (width - 95) / 2, y: height - 286, width: (width - 95) / 2, height: 40)
        emerBtn.bezelStyle = .rounded
        emerBtn.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        card.addSubview(emerBtn)
        
        // Footer Note
        let footnote = NSTextField(labelWithString: "Emergency override dispatches an accountability SMS alert.")
        footnote.frame = NSRect(x: 20, y: 18, width: width - 40, height: 20)
        footnote.font = NSFont.systemFont(ofSize: 11)
        footnote.textColor = NSColor(calibratedWhite: 0.45, alpha: 1.0)
        footnote.alignment = .center
        card.addSubview(footnote)
    }
    
    // MARK: 2. Embedded Request Task View
    private weak var requestTextView: NSTextView?
    
    private func renderRequestTaskView(in card: NSView, width: CGFloat, height: CGFloat) {
        let titleLabel = NSTextField(labelWithString: "Request Late-Night Task")
        titleLabel.frame = NSRect(x: 20, y: height - 42, width: width - 40, height: 26)
        titleLabel.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = NSColor.white
        titleLabel.alignment = .center
        card.addSubview(titleLabel)
        
        let subLabel = NSTextField(labelWithString: "State your intent, impact, and required minutes:")
        subLabel.frame = NSRect(x: 30, y: height - 68, width: width - 60, height: 20)
        subLabel.font = NSFont.systemFont(ofSize: 12)
        subLabel.textColor = NSColor(calibratedWhite: 0.7, alpha: 1.0)
        subLabel.alignment = .center
        card.addSubview(subLabel)
        
        let scroll = NSScrollView(frame: NSRect(x: 40, y: height - 235, width: width - 80, height: 150))
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.borderType = .bezelBorder
        scroll.wantsLayer = true
        scroll.layer?.cornerRadius = 8
        
        let textView = NSTextView(frame: scroll.bounds)
        textView.string = "I am going to go to bed [X] minutes past my bedtime so that I can [Action]. If I don't do this now, [Impact], and doing it now will [Value]."
        textView.font = NSFont.systemFont(ofSize: 13)
        textView.isRichText = false
        textView.backgroundColor = NSColor(calibratedRed: 0.05, green: 0.07, blue: 0.12, alpha: 1.0)
        textView.textColor = NSColor.white
        textView.insertionPointColor = NSColor.systemBlue
        scroll.documentView = textView
        card.addSubview(scroll)
        self.requestTextView = textView
        
        let submitBtn = NSButton(title: "Submit Intent", target: self, action: #selector(handleSubmitRequestClicked))
        submitBtn.frame = NSRect(x: 40, y: 30, width: (width - 95) / 2, height: 40)
        submitBtn.bezelStyle = .rounded
        submitBtn.font = NSFont.systemFont(ofSize: 13, weight: .bold)
        submitBtn.keyEquivalent = "\r"
        card.addSubview(submitBtn)
        
        let cancelBtn = NSButton(title: "Back", target: self, action: #selector(handleBackToOverviewClicked))
        cancelBtn.frame = NSRect(x: 55 + (width - 95) / 2, y: 30, width: (width - 95) / 2, height: 40)
        cancelBtn.bezelStyle = .rounded
        cancelBtn.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        card.addSubview(cancelBtn)
    }
    
    // MARK: 3. Embedded Smart No Result View
    private func renderSmartNoView(in card: NSView, width: CGFloat, height: CGFloat, result: ArbitrationResult) {
        let badge = NSTextField(labelWithString: "REQUEST NOT GRANTED")
        badge.frame = NSRect(x: (width - 240) / 2, y: height - 44, width: 240, height: 18)
        badge.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .heavy)
        badge.textColor = NSColor.systemOrange
        badge.alignment = .center
        card.addSubview(badge)
        
        let titleLabel = NSTextField(labelWithString: result.decisionSummary)
        titleLabel.frame = NSRect(x: 20, y: height - 80, width: width - 40, height: 28)
        titleLabel.font = NSFont.systemFont(ofSize: 19, weight: .bold)
        titleLabel.textColor = NSColor.white
        titleLabel.alignment = .center
        card.addSubview(titleLabel)
        
        let reasonLabel = NSTextField(labelWithString: result.reasoning)
        reasonLabel.frame = NSRect(x: 40, y: height - 200, width: width - 80, height: 100)
        reasonLabel.font = NSFont.systemFont(ofSize: 13)
        reasonLabel.textColor = NSColor(calibratedWhite: 0.85, alpha: 1.0)
        reasonLabel.alignment = .center
        card.addSubview(reasonLabel)
        
        let remindersBtn = NSButton(title: "Open in Apple Reminders", target: self, action: #selector(handleOpenRemindersClicked))
        remindersBtn.frame = NSRect(x: 40, y: 40, width: (width - 95) / 2, height: 40)
        remindersBtn.bezelStyle = .rounded
        remindersBtn.font = NSFont.systemFont(ofSize: 12, weight: .bold)
        card.addSubview(remindersBtn)
        
        let backBtn = NSButton(title: "Return to Curfew", target: self, action: #selector(handleBackToOverviewClicked))
        backBtn.frame = NSRect(x: 55 + (width - 95) / 2, y: 40, width: (width - 95) / 2, height: 40)
        backBtn.bezelStyle = .rounded
        backBtn.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        card.addSubview(backBtn)
    }
    
    // MARK: 4. Embedded Emergency Override View
    private weak var emergencyReasonField: NSTextField?
    
    private func renderEmergencyView(in card: NSView, width: CGFloat, height: CGFloat) {
        let badge = NSTextField(labelWithString: "EMERGENCY OVERRIDE")
        badge.frame = NSRect(x: (width - 240) / 2, y: height - 42, width: 240, height: 18)
        badge.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .heavy)
        badge.textColor = NSColor.systemRed
        badge.alignment = .center
        card.addSubview(badge)
        
        let titleLabel = NSTextField(labelWithString: "Accountability Alert")
        titleLabel.frame = NSRect(x: 20, y: height - 76, width: width - 40, height: 26)
        titleLabel.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = NSColor.white
        titleLabel.alignment = .center
        card.addSubview(titleLabel)
        
        let subLabel = NSTextField(labelWithString: "Dispatches SMS to \(Config.girlfriendContact) with your reason.\nEnter brief description:")
        subLabel.frame = NSRect(x: 30, y: height - 130, width: width - 60, height: 40)
        subLabel.font = NSFont.systemFont(ofSize: 12)
        subLabel.textColor = NSColor(calibratedWhite: 0.8, alpha: 1.0)
        subLabel.alignment = .center
        card.addSubview(subLabel)
        
        let field = NSTextField(frame: NSRect(x: 40, y: height - 190, width: width - 80, height: 36))
        field.placeholderString = "Reason for emergency unlock"
        field.font = NSFont.systemFont(ofSize: 13)
        field.focusRingType = .exterior
        card.addSubview(field)
        self.emergencyReasonField = field
        
        let sendBtn = NSButton(title: "Send Alert & Unlock", target: self, action: #selector(handleSubmitEmergencyClicked))
        sendBtn.frame = NSRect(x: 40, y: 35, width: (width - 95) / 2, height: 40)
        sendBtn.bezelStyle = .rounded
        sendBtn.font = NSFont.systemFont(ofSize: 13, weight: .bold)
        card.addSubview(sendBtn)
        
        let cancelBtn = NSButton(title: "Cancel", target: self, action: #selector(handleBackToOverviewClicked))
        cancelBtn.frame = NSRect(x: 55 + (width - 95) / 2, y: 35, width: (width - 95) / 2, height: 40)
        cancelBtn.bezelStyle = .rounded
        cancelBtn.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        card.addSubview(cancelBtn)
    }
    
    // MARK: - Action Handlers
    @objc private func handleRequestClicked() {
        switchCardState(.requestTask)
    }
    
    @objc private func handleEmergencyClicked() {
        switchCardState(.emergencyOverride)
    }
    
    @objc private func handleBackToOverviewClicked() {
        switchCardState(.overview)
    }
    
    @objc private func handleExitTestClicked() {
        onExitTestModeRequested?()
    }
    
    @objc private func handleSleepMacClicked() {
        triggerMacSleep()
    }
    
    @objc private func handleOpenRemindersClicked() {
        RemindersBridge.shared.openRemindersApp()
        switchCardState(.overview)
    }
    
    @objc private func handleSubmitRequestClicked() {
        let input = requestTextView?.string.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !input.isEmpty else { return }
        
        let result = IntentArbitrator.shared.evaluate(spokenText: input, followUpHour: 18, followUpMinute: 0)
        
        if result.isApproved {
            unlockAllScreens()
            onRequestApproved?(result)
        } else {
            switchCardState(.smartNoResult(result))
        }
    }
    
    @objc private func handleSubmitEmergencyClicked() {
        let reason = emergencyReasonField?.stringValue.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Emergency"
        unlockAllScreens()
        onEmergencyApproved?(reason)
    }
    
    // MARK: - Safe Mac Sleep Action
    public func triggerMacSleep() {
        let script = "tell application \"Finder\" to sleep"
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }
}
