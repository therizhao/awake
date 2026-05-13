import Foundation
import IOKit.pwr_mgt

final class SleepManager {
    private(set) var isActive = false
    private var assertionID: IOPMAssertionID = 0
    private var timer: Timer?
    private(set) var endDate: Date?
    private(set) var activeDuration: TimeInterval?

    var onStateChange: (() -> Void)?

    var remainingTime: TimeInterval? {
        guard let endDate else { return nil }
        return max(0, endDate.timeIntervalSinceNow)
    }

    func enable(for duration: TimeInterval? = nil) {
        if isActive { disable() }
        guard setPmset(disableSleep: true) else { return }
        let reason = "Awake: User requested sleep prevention" as CFString
        IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoDisplaySleep as CFString,
            UInt32(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )
        isActive = true
        activeDuration = duration

        if let duration {
            endDate = Date().addingTimeInterval(duration)
            timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                self?.disable()
            }
        } else {
            endDate = nil
        }

        onStateChange?()
    }

    func disable() {
        guard isActive else { return }
        timer?.invalidate()
        timer = nil
        endDate = nil
        activeDuration = nil
        setPmset(disableSleep: false)
        if assertionID != 0 {
            IOPMAssertionRelease(assertionID)
            assertionID = 0
        }
        isActive = false
        onStateChange?()
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
        if isActive {
            timer?.invalidate()
            timer = nil
            setPmset(disableSleep: false)
            if assertionID != 0 {
                IOPMAssertionRelease(assertionID)
            }
        }
    }
}
