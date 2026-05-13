import Foundation
import IOKit.pwr_mgt

final class SleepManager: ObservableObject {
    @Published private(set) var isActive = false
    private var assertionID: IOPMAssertionID = 0

    func toggle() {
        if isActive {
            disable()
        } else {
            enable()
        }
    }

    func enable() {
        guard !isActive else { return }
        let reason = "Awake: User requested sleep prevention" as CFString
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoDisplaySleep as CFString,
            UInt32(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )
        isActive = (result == kIOReturnSuccess)
    }

    func disable() {
        guard isActive else { return }
        IOPMAssertionRelease(assertionID)
        assertionID = 0
        isActive = false
    }

    deinit {
        disable()
    }
}
