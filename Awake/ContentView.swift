import SwiftUI

struct ContentView: View {
    @ObservedObject var sleepManager: SleepManager

    var body: some View {
        Text(sleepManager.isActive ? "Sleep Prevented" : "Sleep Allowed")

        Divider()

        Toggle("Prevent Sleep", isOn: Binding(
            get: { sleepManager.isActive },
            set: { _ in sleepManager.toggle() }
        ))

        Divider()

        Button("Quit Awake") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
