import Carbon.HIToolbox
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
    let isInput: Bool       // keyboard / mouse / trackpad (Bluetooth "peripheral" class)
    let isConnected: Bool
}

/// Lists paired Bluetooth input devices and connects/disconnects them via IOBluetooth.
@MainActor
final class BluetoothDeviceManager: ObservableObject {
    /// All paired devices, regardless of `showAllDevices`.
    @Published private(set) var allDevices: [PeripheralDevice] = []
    @Published private(set) var busyDeviceIDs: Set<String> = []
    @Published var lastError: String?

    /// When false, only keyboards / mice / trackpads (Bluetooth "peripheral" class) are shown.
    @Published var showAllDevices = false

    var devices: [PeripheralDevice] {
        showAllDevices ? allDevices : allDevices.filter(\.isInput)
    }

    // MARK: Device group

    @Published var groupName: String {
        didSet { defaults.set(groupName, forKey: Keys.groupName) }
    }

    /// Bluetooth addresses of the devices in the group.
    @Published private(set) var groupDeviceIDs: Set<String> {
        didSet { defaults.set(Array(groupDeviceIDs), forKey: Keys.groupDeviceIDs) }
    }

    /// Enables the global hotkeys ⌘⌥C (connect group) and ⌘⌥R (release group).
    @Published var hotKeysEnabled: Bool {
        didSet {
            defaults.set(hotKeysEnabled, forKey: Keys.hotKeysEnabled)
            updateHotKeys()
        }
    }

    @Published private(set) var hotKeyError: String?

    var groupDevices: [PeripheralDevice] {
        allDevices.filter { groupDeviceIDs.contains($0.id) }
    }

    private enum Keys {
        static let groupName = "groupName"
        static let groupDeviceIDs = "groupDeviceIDs"
        static let hotKeysEnabled = "hotKeysEnabled"
    }

    private let defaults = UserDefaults.standard
    private let hotKeys = GlobalHotKeys()
    private var connectNotification: IOBluetoothUserNotification?
    private var disconnectNotifications: [String: IOBluetoothUserNotification] = [:]
    private let workQueue = DispatchQueue(label: "akeyboardswitcher.bluetooth")

    init() {
        groupName = defaults.string(forKey: Keys.groupName) ?? "My Devices"
        groupDeviceIDs = Set(defaults.stringArray(forKey: Keys.groupDeviceIDs) ?? [])
        hotKeysEnabled = defaults.object(forKey: Keys.hotKeysEnabled) as? Bool ?? true

        connectNotification = IOBluetoothDevice.register(
            forConnectNotifications: self,
            selector: #selector(deviceDidConnect(_:device:))
        )
        refresh()
        updateHotKeys()
    }

    func refresh() {
        let paired = (IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice]) ?? []
        allDevices = paired
            .map { device in
                PeripheralDevice(
                    id: device.addressString ?? UUID().uuidString,
                    name: device.nameOrAddress ?? "Unknown device",
                    kind: Self.kind(of: device),
                    isInput: Self.isInputPeripheral(device),
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

    func isInGroup(_ device: PeripheralDevice) -> Bool {
        groupDeviceIDs.contains(device.id)
    }

    func setDevice(_ device: PeripheralDevice, inGroup: Bool) {
        if inGroup {
            groupDeviceIDs.insert(device.id)
        } else {
            groupDeviceIDs.remove(device.id)
        }
    }

    func connectGroup() {
        refresh()
        groupDevices.filter { !$0.isConnected }.forEach(connect)
    }

    func releaseGroup() {
        refresh()
        groupDevices.filter(\.isConnected).forEach(disconnect)
    }

    // MARK: - Private

    private func updateHotKeys() {
        hotKeys.unregisterAll()
        hotKeyError = nil
        guard hotKeysEnabled else { return }

        let modifiers = cmdKey | optionKey
        let connectOK = hotKeys.register(keyCode: kVK_ANSI_C, modifiers: modifiers) { [weak self] in
            Task { @MainActor in self?.connectGroup() }
        }
        let releaseOK = hotKeys.register(keyCode: kVK_ANSI_R, modifiers: modifiers) { [weak self] in
            Task { @MainActor in self?.releaseGroup() }
        }

        let taken = [connectOK ? nil : "⌘⌥C", releaseOK ? nil : "⌘⌥R"].compactMap { $0 }
        if !taken.isEmpty {
            hotKeyError = "\(taken.joined(separator: " and ")) already in use by another app."
        }
    }

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
