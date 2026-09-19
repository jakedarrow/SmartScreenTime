# ⚡️ SmartScreenTime

A hardcore, non-blocking Screen Time system designed specifically for macOS, creative workflows (Logic Pro), and zero-distraction YouTube searching on Mac and iPhone.

---

## 🎯 Hardcore YouTube Shield (Zero In-Browser Settings)

When the shield is enabled, **all YouTube clutter is unconditionally eliminated**:
1. **Home Feed:** Completely removed. Replaced by a clean, focused **Search Bar** (like Google Search for video).
2. **Shorts:** Completely blocked and intercepted (redirects to standard watch view without infinite vertical swipe).
3. **Up-Next / Sidebar Recommendations:** Completely stripped on watch pages.
4. **Comments & End-Screen Tiles:** Removed to eliminate rabbit holes.
5. **Autoplay:** Automatically disabled so videos never roll over.
6. **Zero In-Browser Settings:** No popups, no checkboxes, no ways to weaken your focus inside the browser.

---

## 📱 iPhone / iPad Setup (100% Free & Permanent)

To run the shield permanently on iOS Safari without paying Apple's $99/yr developer fee or dealing with 7-day sideloading expirations:

1. **Install Userscripts:** Download the free, open-source **[Userscripts app](https://apps.apple.com/app/userscripts/id1463298887)** from the iOS App Store.
2. **Enable in Safari:**
   * Go to iPhone **Settings > Safari > Extensions > Userscripts** and toggle it **ON**.
   * Tap **Permissions** and select **Always Allow** for `youtube.com` (or All Websites).
3. **1-Tap Install the Shield:**
   * Open this raw script link in Safari on your iPhone:  
     👉 **[Install SmartScreenTime Shield](https://raw.githubusercontent.com/jakedarrow/SmartScreenTime/main/smart-screentime.user.js)**
   * Tap the **Userscripts** extension icon in Safari's address bar and tap **Install**.
4. Open `m.youtube.com` — feeds, shorts, and comments are gone permanently.

---

## 💻 Desktop Quick Start

### 1. Load the Hardcore Extension (Chrome, Brave, Arc, Edge)
1. Open your browser and navigate to `chrome://extensions`
2. Enable **Developer mode** (top right toggle)
3. Click **Load unpacked**
4. Select the directory:
   ```
   SmartScreenTime-Extension
   ```
5. Navigate to [youtube.com](https://youtube.com) — you get a pure, minimalist search engine with zero feeds.

### 2. Native macOS Menu Bar App (Controls & Logic Pro Monitor)
All session management and controls live natively on your Mac menu bar, not in the browser:
```bash
cd SmartScreenTime-Mac
swift run
```
* Shows `⚡️ SST` in your macOS Menu Bar.
* Automatically detects when **Logic Pro** is active (`⚡️ Logic (Focus)`).
* Allows you to take intentional 5-minute breaks or check total watch time today.

---

## 📁 Repository Structure

```
SmartScreenTime/
├── smart-screentime.user.js       # Standalone Safari / Userscripts companion for iPhone & Mac
├── SmartScreenTime-Extension/     # Hardcore Manifest V3 browser companion (Chromium)
│   ├── manifest.json              # Extension manifest (No popup)
│   ├── background.js              # Watch telemetry & badge worker
│   ├── content_youtube.js         # Centered search engine & Shorts shield
│   ├── content_youtube.css        # Distraction-free CSS rules
│   └── icons/                     # Extension icons
│
└── SmartScreenTime-Mac/           # Native macOS Menu Bar App (Swift 6)
    ├── Package.swift              # Swift package configuration
    └── Sources/SmartScreenTimeMac/
        ├── main.swift             # Menu Bar extra & App Delegate
        ├── AppTracker.swift       # Frontmost app & Logic Pro detector
        ├── LocalBridgeServer.swift# Local HTTP API (localhost:48200)
        └── StorageManager.swift   # Local JSON & iCloud state store
```

---

## 📄 License
MIT License. Free and open source.
