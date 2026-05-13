import SwiftUI

@main
struct AwakeApp: App {
    @StateObject private var sleepManager = SleepManager()

    var body: some Scene {
        MenuBarExtra {
            ContentView(sleepManager: sleepManager)
        } label: {
            Image(systemName: sleepManager.isActive ? "cup.and.saucer.fill" : "cup.and.saucer")
        }
    }
}
