import SwiftUI

@main
struct AKeyboardSwitcherApp: App {
    @StateObject private var manager = BluetoothDeviceManager()

    var body: some Scene {
        MenuBarExtra("Keyboard Switcher", systemImage: "keyboard.badge.ellipsis") {
            DeviceListView(manager: manager)
        }
        .menuBarExtraStyle(.window)

        Window("AKeyboardSwitcher Options", id: "options") {
            OptionsView(manager: manager)
        }
        .windowResizability(.contentSize)

        Window("About AKeyboardSwitcher", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
    }
}
