import SwiftUI

struct OptionsView: View {
    @ObservedObject var manager: BluetoothDeviceManager

    /// Input devices, plus everything else when "Show all paired devices" is on,
    /// plus any group member that would otherwise be hidden.
    private var listedDevices: [PeripheralDevice] {
        manager.allDevices.filter { $0.isInput || manager.showAllDevices || manager.isInGroup($0) }
    }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $manager.groupName)

                if listedDevices.isEmpty {
                    Text("No paired input devices found.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(listedDevices) { device in
                        Toggle(isOn: Binding(
                            get: { manager.isInGroup(device) },
                            set: { manager.setDevice(device, inGroup: $0) }
                        )) {
                            Label(device.name, systemImage: device.kind.symbolName)
                        }
                    }
                }
            } header: {
                Text("Device Group")
            } footer: {
                Text("Devices in the group are connected or released together.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Enable global hotkeys", isOn: $manager.hotKeysEnabled)
                LabeledContent("Connect group", value: "⌘ ⌥ C")
                LabeledContent("Release group", value: "⌘ ⌥ R")

                if let error = manager.hotKeyError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Hotkeys")
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { manager.refresh() }
    }
}
