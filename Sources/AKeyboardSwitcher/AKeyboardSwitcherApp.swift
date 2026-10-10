import SwiftUI

@main
struct AKeyboardSwitcherApp: App {
    @StateObject private var manager = BluetoothDeviceManager()

    var body: some Scene {
        MenuBarExtra("Keyboard Switcher", systemImage: "keyboard.badge.ellipsis") {
            DeviceListView(manager: manager)
        }
        .menuBarExtraStyle(.window)

        Window("About AKeyboardSwitcher", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
    }
}
