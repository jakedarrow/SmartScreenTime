import Cocoa

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var statusMenu: NSMenu!
    
    private var statusAndCurfewMenuItem: NSMenuItem!
    private var taskCompleteMenuItem: NSMenuItem!
    private var emergencyResolvedMenuItem: NSMenuItem!
    private var sandboxPreviewMenuItem: NSMenuItem!
    private var devTestMenuItem: NSMenuItem!
    private var fastCountdownTestMenuItem: NSMenuItem!
    
    private var isSimulatingCurfew: Bool = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.title = "SST"
        }
        
        isSimulatingCurfew = Config.debugForceCurfewActive
        
        buildMenu()
        
        // Start Tracker & Local Bridge
        AppTracker.shared.start()
        LocalBridgeServer.shared.start()
        WiFiTracker.shared.refresh()
        
        AppTracker.shared.onAppChanged = { [weak self] _ in
            self?.updateMenuState()
        }
        
        ChimeTimerManager.shared.onTick = { [weak self] seconds in
            FloatingHUDController.shared.updateTime(seconds: seconds)
            self?.updateMenuState()
        }
        
        ChimeTimerManager.shared.onSessionEnded = { [weak self] in
            FloatingHUDController.shared.hide()
            StorageManager.shared.update { state in
                state.focusModeActive = false
            }
            self?.updateMenuState()
        }
        
        ChimeTimerManager.shared.onSessionExpired = { [weak self] _ in
            FloatingHUDController.shared.hide()
            StorageManager.shared.update { state in
                state.focusModeActive = false
            }
            self?.updateMenuState()
        }
        
        // HUD Actions
        FloatingHUDController.shared.onTaskCompleteClicked = { [weak self] in
            self?.taskCompleteAction()
        }
        
        FloatingHUDController.shared.onEmergencyResolveClicked = { [weak self] in
            self?.emergencyResolvedAction()
        }
        
        // Curfew In-Card Callbacks
        CurfewLockScreenController.shared.onRequestApproved = { [weak self] result in
            let secs = result.grantedSeconds > 0 ? result.grantedSeconds : result.grantedMinutes * 60
            CurfewLockScreenController.shared.unlockAllScreens()
            ChimeTimerManager.shared.startSession(seconds: secs, taskName: result.taskTitle)
            FloatingHUDController.shared.show(taskName: result.taskTitle, initialSeconds: secs)
            
            StorageManager.shared.update { s in
                s.focusModeActive = true
                s.currentSessionName = result.taskTitle
                s.consecutiveBypassesTonight += 1
            }
            self?.updateMenuState()
        }
        
        CurfewLockScreenController.shared.onEmergencyApproved = { [weak self] reason in
            EmergencySMSBridge.shared.sendEmergencyAlert(reason: reason)
            CurfewLockScreenController.shared.unlockAllScreens()
            
            FloatingHUDController.shared.showEmergency(reason: reason)
            
            StorageManager.shared.update { s in
                s.focusModeActive = true
                s.currentSessionName = "Emergency Override: \(reason)"
            }
            self?.updateMenuState()
        }
        
        CurfewLockScreenController.shared.onExitTestModeRequested = { [weak self] in
            self?.isSimulatingCurfew = false
            CurfewLockScreenController.shared.unlockAllScreens()
            self?.updateMenuState()
        }
        
        // Escape / Cmd+Shift+Escape Hotkeys for Instant Safe Unlock in Test Mode
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            if (event.keyCode == 53 && self.isSimulatingCurfew) ||
               (event.keyCode == 53 && event.modifierFlags.contains(.command) && event.modifierFlags.contains(.shift)) {
                self.isSimulatingCurfew = false
                CurfewLockScreenController.shared.unlockAllScreens()
                self.updateMenuState()
                return nil
            }
            return event
        }
        
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }
            if (event.keyCode == 53 && event.modifierFlags.contains(.command) && event.modifierFlags.contains(.shift)) ||
               (event.keyCode == 53 && self.isSimulatingCurfew) {
                Task { @MainActor in
                    self.isSimulatingCurfew = false
                    CurfewLockScreenController.shared.unlockAllScreens()
                    self.updateMenuState()
                }
            }
        }
        
        updateMenuState()
    }
    
    private func buildMenu() {
        statusMenu = NSMenu()
        
        // Unified Status & Curfew Line
        statusAndCurfewMenuItem = NSMenuItem(title: "Unrestricted • Curfew at 10:00 PM", action: nil, keyEquivalent: "")
        statusAndCurfewMenuItem.isEnabled = false
        statusMenu.addItem(statusAndCurfewMenuItem)
        
        statusMenu.addItem(NSMenuItem.separator())
        
        // Task Complete (Only visible during active timed session)
        taskCompleteMenuItem = NSMenuItem(title: "Task Complete (Lock Screen)", action: #selector(taskCompleteAction), keyEquivalent: "d")
        taskCompleteMenuItem.target = self
        taskCompleteMenuItem.isHidden = true
        statusMenu.addItem(taskCompleteMenuItem)
        
        // Emergency Resolved (Visible when emergency override is active)
        emergencyResolvedMenuItem = NSMenuItem(title: "Resolve Emergency (Lock Screen)", action: #selector(emergencyResolvedAction), keyEquivalent: "e")
        emergencyResolvedMenuItem.target = self
        emergencyResolvedMenuItem.isHidden = true
        statusMenu.addItem(emergencyResolvedMenuItem)
        
        statusMenu.addItem(NSMenuItem.separator())
        
        // Zero-Risk Windowed Sandbox Preview
        sandboxPreviewMenuItem = NSMenuItem(title: "Preview Curfew in Window (Safe Sandbox)", action: #selector(openSandboxPreview), keyEquivalent: "p")
        sandboxPreviewMenuItem.target = self
        statusMenu.addItem(sandboxPreviewMenuItem)
        
        // Developer Full Screen Test Toggle
        devTestMenuItem = NSMenuItem(title: "Simulate Bedtime Curfew (Full Screen Test)", action: #selector(toggleDevTestMode), keyEquivalent: "t")
        devTestMenuItem.target = self
        statusMenu.addItem(devTestMenuItem)
        
        // Fast 10-Second Test Countdown
        fastCountdownTestMenuItem = NSMenuItem(title: "Start 10-Second Expiry Test", action: #selector(startFastCountdownTest), keyEquivalent: "T")
        fastCountdownTestMenuItem.target = self
        statusMenu.addItem(fastCountdownTestMenuItem)
        
        statusMenu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit SmartScreenTime", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        statusMenu.addItem(quitItem)
        
        statusItem.menu = statusMenu
    }
    
    func updateMenuState() {
        let chime = ChimeTimerManager.shared
        let state = StorageManager.shared.state
        let isEmergencyActive = state.focusModeActive && state.currentSessionName.starts(with: "Emergency Override")
        
        // Determine Curfew Window (10:00 PM to 5:00 AM on Weeknights)
        let hour = Calendar.current.component(.hour, from: Date())
        let isWeekend = Calendar.current.isDateInWeekend(Date())
        let isWeeknight = !isWeekend
        let realCurfew = isWeeknight && (hour >= Config.weeknightBedtimeStartHour || hour < Config.weeknightBedtimeEndHour)
        let isCurfew = realCurfew || isSimulatingCurfew
        
        let curfewHourFormatted = Config.weeknightBedtimeStartHour > 12 ? "\(Config.weeknightBedtimeStartHour - 12):00 PM" : "\(Config.weeknightBedtimeStartHour):00 AM"
        
        // Global Lock Screen Overlay Controller
        if isCurfew && !chime.isSessionActive && !isEmergencyActive {
            CurfewLockScreenController.shared.lockAllScreens(isTestMode: isSimulatingCurfew)
        } else if !CurfewLockScreenController.shared.isPreviewMode {
            CurfewLockScreenController.shared.unlockAllScreens()
        }
        
        // Top Bar Icon / Text (Clean Native Text)
        if isEmergencyActive {
            statusItem.button?.title = "Emergency"
        } else if chime.isSessionActive {
            let mins = chime.secondsRemaining / 60
            let secs = chime.secondsRemaining % 60
            let timeStr = String(format: "%02d:%02d", mins, secs)
            statusItem.button?.title = timeStr
        } else if isCurfew {
            statusItem.button?.title = "Curfew"
        } else {
            statusItem.button?.title = "SST"
        }
        
        // Attributed Status Line
        if isEmergencyActive {
            let text = "Emergency Override Active"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 13),
                .foregroundColor: NSColor.systemRed
            ]
            statusAndCurfewMenuItem.attributedTitle = NSAttributedString(string: text, attributes: attrs)
        } else if chime.isSessionActive {
            let mins = chime.secondsRemaining / 60
            let secs = chime.secondsRemaining % 60
            let timeStr = String(format: "%02d:%02d", mins, secs)
            let text = "Active Task: \"\(chime.currentTaskName)\" (\(timeStr) left)"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 13),
                .foregroundColor: NSColor.systemBlue
            ]
            statusAndCurfewMenuItem.attributedTitle = NSAttributedString(string: text, attributes: attrs)
        } else if isCurfew {
            let text = isSimulatingCurfew ? "Bedtime Curfew Active (Test Mode)" : "Bedtime Curfew Active (Until 5:00 AM)"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 13),
                .foregroundColor: NSColor.systemRed
            ]
            statusAndCurfewMenuItem.attributedTitle = NSAttributedString(string: text, attributes: attrs)
        } else if isWeekend {
            let text = "Weekend Mode (Unrestricted)"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 13),
                .foregroundColor: NSColor.labelColor
            ]
            statusAndCurfewMenuItem.attributedTitle = NSAttributedString(string: text, attributes: attrs)
        } else {
            let text = "Unrestricted • Curfew at \(curfewHourFormatted)"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 13),
                .foregroundColor: NSColor.labelColor
            ]
            statusAndCurfewMenuItem.attributedTitle = NSAttributedString(string: text, attributes: attrs)
        }
        
        devTestMenuItem.state = isSimulatingCurfew ? .on : .off
        
        // Context-sensitive actions
        emergencyResolvedMenuItem.isHidden = !isEmergencyActive
        taskCompleteMenuItem.isHidden = !chime.isSessionActive
    }
    
    @objc private func openSandboxPreview() {
        CurfewLockScreenController.shared.showWindowedPreview()
    }
    
    @objc private func toggleDevTestMode() {
        isSimulatingCurfew.toggle()
        updateMenuState()
    }
    
    @objc private func startFastCountdownTest() {
        let task = "10s Expiry Test"
        CurfewLockScreenController.shared.unlockAllScreens()
        ChimeTimerManager.shared.startSession(seconds: 10, taskName: task)
        FloatingHUDController.shared.show(taskName: task, initialSeconds: 10)
        StorageManager.shared.update { s in
            s.focusModeActive = true
            s.currentSessionName = task
        }
        updateMenuState()
    }
    
    @objc private func taskCompleteAction() {
        FloatingHUDController.shared.hide()
        ChimeTimerManager.shared.markDoneEarly()
        StorageManager.shared.update { s in
            s.focusModeActive = false
        }
        updateMenuState()
    }
    
    @objc private func emergencyResolvedAction() {
        FloatingHUDController.shared.hide()
        StorageManager.shared.update { s in
            s.focusModeActive = false
            s.currentSessionName = "Deep Focus"
        }
        updateMenuState()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// Entry Point
@MainActor
func runMain() {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}

runMain()
