import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let sleepManager = SleepManager()
    private var toggleItem: NSMenuItem!
    private var statusMenuItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateIcon()
        buildMenu()
    }

    private func buildMenu() {
        let menu = NSMenu()

        statusMenuItem = NSMenuItem(title: "Sleep Allowed", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        menu.addItem(.separator())

        toggleItem = NSMenuItem(title: "Prevent Sleep", action: #selector(toggleSleep), keyEquivalent: "p")
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Awake", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func toggleSleep() {
        sleepManager.toggle()
        updateIcon()
        updateMenu()
    }

    private func updateIcon() {
        guard let button = statusItem.button else { return }
        let name = sleepManager.isActive ? "bolt.fill" : "bolt.slash.fill"
        let image = NSImage(systemSymbolName: name, accessibilityDescription: "Awake")
        image?.isTemplate = true
        button.image = image
    }

    private func updateMenu() {
        toggleItem.state = sleepManager.isActive ? .on : .off
        statusMenuItem.title = sleepManager.isActive ? "Sleep Prevented" : "Sleep Allowed"
    }

    @objc private func quit() {
        sleepManager.disable()
        NSApplication.shared.terminate(nil)
    }
}
