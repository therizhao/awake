import Foundation
import IOKit.pwr_mgt

final class SleepManager {
    private(set) var isActive = false
    private var assertionID: IOPMAssertionID = 0

    func toggle() {
        if isActive { disable() } else { enable() }
    }

    func enable() {
        guard !isActive else { return }
        guard setPmset(disableSleep: true) else { return }
        let reason = "Awake: User requested sleep prevention" as CFString
        IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoDisplaySleep as CFString,
            UInt32(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )
        isActive = true
    }

    func disable() {
        guard isActive else { return }
        setPmset(disableSleep: false)
        if assertionID != 0 {
            IOPMAssertionRelease(assertionID)
            assertionID = 0
        }
        isActive = false
    }

    @discardableResult
    private func setPmset(disableSleep: Bool) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        process.arguments = ["/usr/bin/pmset", "disablesleep", disableSleep ? "1" : "0"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    deinit {
        disable()
    }
}
