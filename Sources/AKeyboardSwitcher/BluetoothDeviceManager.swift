import Foundation
@preconcurrency import IOBluetooth

enum PeripheralKind {
    case keyboard, mouse, trackpad, other

    var symbolName: String {
        switch self {
        case .keyboard: return "keyboard"
        case .mouse: return "magicmouse"
        case .trackpad: return "rectangle.and.hand.point.up.left"
        case .other: return "dot.radiowaves.left.and.right"
        }
    }
}

struct PeripheralDevice: Identifiable, Equatable {
    let id: String          // Bluetooth address, e.g. "aa-bb-cc-dd-ee-ff"
    let name: String
    let kind: PeripheralKind
    let isConnected: Bool
}

/// Lists paired Bluetooth input devices and connects/disconnects them via IOBluetooth.
@MainActor
final class BluetoothDeviceManager: ObservableObject {
    @Published private(set) var devices: [PeripheralDevice] = []
    @Published private(set) var busyDeviceIDs: Set<String> = []
    @Published var lastError: String?

    /// When false, only keyboards / mice / trackpads (Bluetooth "peripheral" class) are shown.
    @Published var showAllDevices = false {
        didSet { refresh() }
    }

    private var connectNotification: IOBluetoothUserNotification?
    private var disconnectNotifications: [String: IOBluetoothUserNotification] = [:]
    private let workQueue = DispatchQueue(label: "akeyboardswitcher.bluetooth")

    init() {
        connectNotification = IOBluetoothDevice.register(
            forConnectNotifications: self,
            selector: #selector(deviceDidConnect(_:device:))
        )
        refresh()
    }

    func refresh() {
        let paired = (IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice]) ?? []
        devices = paired
            .filter { showAllDevices || Self.isInputPeripheral($0) }
            .map { device in
                PeripheralDevice(
                    id: device.addressString ?? UUID().uuidString,
                    name: device.nameOrAddress ?? "Unknown device",
                    kind: Self.kind(of: device),
                    isConnected: device.isConnected()
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        for device in paired where device.isConnected() {
            watchDisconnect(of: device)
        }
    }

    func connect(_ device: PeripheralDevice) {
        perform(on: device) { $0.openConnection() }
    }

    func disconnect(_ device: PeripheralDevice) {
        perform(on: device) { $0.closeConnection() }
    }

    func connectAll() {
        devices.filter { !$0.isConnected }.forEach(connect)
    }

    func disconnectAll() {
        devices.filter(\.isConnected).forEach(disconnect)
    }

    // MARK: - Private

    /// openConnection/closeConnection block for several seconds, so run them off the main thread.
    private func perform(on device: PeripheralDevice, _ action: @escaping (IOBluetoothDevice) -> IOReturn) {
        guard !busyDeviceIDs.contains(device.id),
              let btDevice = IOBluetoothDevice(addressString: device.id) else { return }

        busyDeviceIDs.insert(device.id)
        lastError = nil

        workQueue.async {
            let result = action(btDevice)
            DispatchQueue.main.async {
                self.busyDeviceIDs.remove(device.id)
                if result != kIOReturnSuccess {
                    self.lastError = "\(device.name): failed (\(String(format: "0x%08x", result))). "
                        + "If it is connected to another Mac, disconnect it there first."
                }
                self.refresh()
            }
        }
    }

    private func watchDisconnect(of device: IOBluetoothDevice) {
        guard let address = device.addressString, disconnectNotifications[address] == nil else { return }
        disconnectNotifications[address] = device.register(
            forDisconnectNotification: self,
            selector: #selector(deviceDidDisconnect(_:device:))
        )
    }

    @objc private func deviceDidConnect(_ notification: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        refresh()
    }

    @objc private func deviceDidDisconnect(_ notification: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        notification.unregister()
        if let address = device.addressString {
            disconnectNotifications[address] = nil
        }
        refresh()
    }

    private static func isInputPeripheral(_ device: IOBluetoothDevice) -> Bool {
        device.deviceClassMajor == BluetoothDeviceClassMajor(kBluetoothDeviceClassMajorPeripheral)
    }

    private static func kind(of device: IOBluetoothDevice) -> PeripheralKind {
        let name = (device.name ?? "").lowercased()
        if name.contains("trackpad") { return .trackpad }
        if name.contains("mouse") { return .mouse }
        if name.contains("keyboard") { return .keyboard }

        guard isInputPeripheral(device) else { return .other }
        // Peripheral minor class: bit 4 = keyboard, bit 5 = pointing device.
        let minor = device.deviceClassMinor
        if minor & 0x10 != 0 { return .keyboard }
        if minor & 0x20 != 0 { return .mouse }
        return .other
    }
}
