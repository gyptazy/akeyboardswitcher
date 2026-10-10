import SwiftUI

struct DeviceListView: View {
    @ObservedObject var manager: BluetoothDeviceManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Bluetooth Devices").font(.headline)
                Spacer()
                Button {
                    manager.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Refresh")
            }

            Divider()

            if manager.devices.isEmpty {
                Text("No paired input devices found.")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(manager.devices) { device in
                    DeviceRow(
                        device: device,
                        isBusy: manager.busyDeviceIDs.contains(device.id),
                        onConnect: { manager.connect(device) },
                        onDisconnect: { manager.disconnect(device) }
                    )
                }
            }

            if let error = manager.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            HStack {
                Button("Connect All") { manager.connectAll() }
                Button("Release All") { manager.disconnectAll() }
            }

            Toggle("Show all paired devices", isOn: $manager.showAllDevices)
                .toggleStyle(.checkbox)
                .font(.caption)

            Divider()

            Button("Quit") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.borderless)
                .keyboardShortcut("q")
        }
        .padding(12)
        .frame(width: 320)
        .onAppear { manager.refresh() }
    }
}

private struct DeviceRow: View {
    let device: PeripheralDevice
    let isBusy: Bool
    let onConnect: () -> Void
    let onDisconnect: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: device.kind.symbolName)
                .frame(width: 24)
                .foregroundStyle(device.isConnected ? Color.accentColor : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(device.name).lineLimit(1)
                Text(device.isConnected ? "Connected to this Mac" : "Not connected")
                    .font(.caption)
                    .foregroundStyle(device.isConnected ? .green : .secondary)
            }

            Spacer()

            if isBusy {
                ProgressView().controlSize(.small)
            } else if device.isConnected {
                Button("Release", action: onDisconnect)
            } else {
                Button("Connect", action: onConnect)
            }
        }
        .padding(.vertical, 2)
    }
}
