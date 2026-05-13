import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let sleepManager = SleepManager()
    private var statusMenuItem: NSMenuItem!
    private var deactivateItem: NSMenuItem!
    private var durationItems: [NSMenuItem] = []
    private var tickTimer: Timer?

    private static let durations: [(title: String, interval: TimeInterval?)] = [
        ("Indefinitely", nil),
        ("30 Minutes", 30 * 60),
        ("1 Hour", 60 * 60),
        ("2 Hours", 2 * 60 * 60),
        ("4 Hours", 4 * 60 * 60),
    ]

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        sleepManager.onStateChange = { [weak self] in
            DispatchQueue.main.async { self?.refreshUI() }
        }
        updateIcon()
        buildMenu()
    }

    private func buildMenu() {
        let menu = NSMenu()
        menu.delegate = self

        statusMenuItem = NSMenuItem(title: "Sleep Allowed", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        menu.addItem(.separator())

        for (title, interval) in Self.durations {
            let item = NSMenuItem(title: title, action: #selector(selectDuration(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = interval.map { NSNumber(value: $0) }
            durationItems.append(item)
            menu.addItem(item)
        }

        menu.addItem(.separator())

        deactivateItem = NSMenuItem(title: "Deactivate", action: #selector(deactivate), keyEquivalent: "d")
        deactivateItem.target = self
        deactivateItem.isHidden = true
        menu.addItem(deactivateItem)

        let quitSep = NSMenuItem.separator()
        menu.addItem(quitSep)

        let quitItem = NSMenuItem(title: "Quit Awake", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        updateMenu()
    }

    @objc private func selectDuration(_ sender: NSMenuItem) {
        let interval = (sender.representedObject as? NSNumber)?.doubleValue
        sleepManager.enable(for: interval)
    }

    @objc private func deactivate() {
        sleepManager.disable()
    }

    private func refreshUI() {
        updateIcon()
        updateMenu()
        updateTickTimer()
    }

    private func updateIcon() {
        guard let button = statusItem.button else { return }
        let name = sleepManager.isActive ? "bolt.fill" : "bolt.slash.fill"
        let image = NSImage(systemSymbolName: name, accessibilityDescription: "Awake")
        image?.isTemplate = true
        button.image = image

        if sleepManager.isActive, let remaining = sleepManager.remainingTime {
            button.title = " " + Self.formatShort(remaining)
            button.toolTip = "Awake — \(Self.formatLong(remaining)) remaining"
        } else if sleepManager.isActive {
            button.title = ""
            button.toolTip = "Awake — sleep prevented indefinitely"
        } else {
            button.title = ""
            button.toolTip = "Awake — sleep allowed"
        }
    }

    private func updateMenu() {
        if sleepManager.isActive {
            if let remaining = sleepManager.remainingTime {
                statusMenuItem.title = "Sleep Prevented \u{2014} \(Self.formatLong(remaining)) remaining"
            } else {
                statusMenuItem.title = "Sleep Prevented"
            }
        } else {
            statusMenuItem.title = "Sleep Allowed"
        }

        for item in durationItems {
            let interval = (item.representedObject as? NSNumber)?.doubleValue
            if sleepManager.isActive && sleepManager.activeDuration == interval {
                item.state = .on
            } else {
                item.state = .off
            }
        }

        deactivateItem.isHidden = !sleepManager.isActive
    }

    private func updateTickTimer() {
        tickTimer?.invalidate()
        tickTimer = nil

        guard sleepManager.isActive, sleepManager.endDate != nil else { return }

        tickTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateIcon()
        }
    }

    private static func formatShort(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 {
            return String(format: "%d:%02d", h, m)
        }
        return "\(m)m"
    }

    private static func formatLong(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 && m > 0 {
            return "\(h)h \(m)m"
        } else if h > 0 {
            return "\(h)h"
        }
        return "\(m)m"
    }

    private static func formatAccessible(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let h = total / 3600
        let m = (total % 3600) / 60
        var parts: [String] = []
        if h > 0 { parts.append("\(h) hour\(h == 1 ? "" : "s")") }
        if m > 0 { parts.append("\(m) minute\(m == 1 ? "" : "s")") }
        return parts.joined(separator: " and ")
    }

    @objc private func quit() {
        tickTimer?.invalidate()
        sleepManager.disable()
        NSApplication.shared.terminate(nil)
    }
}
