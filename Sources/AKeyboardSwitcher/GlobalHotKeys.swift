import Carbon.HIToolbox

/// System-wide hotkeys via Carbon's RegisterEventHotKey. Unlike an NSEvent global monitor,
/// this needs no Accessibility permission and works while the app is in the background.
final class GlobalHotKeys {
    private struct Registration {
        let ref: EventHotKeyRef
        let action: () -> Void
    }

    private static let signature: OSType = 0x414B_5357 // "AKSW"

    private var registrations: [UInt32: Registration] = [:]
    private var nextID: UInt32 = 1
    private var eventHandler: EventHandlerRef?

    init() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            guard let event, let userData else { return OSStatus(eventNotHandledErr) }

            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            guard status == noErr else { return status }

            let hotKeys = Unmanaged<GlobalHotKeys>.fromOpaque(userData).takeUnretainedValue()
            hotKeys.registrations[hotKeyID.id]?.action()
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)
    }

    deinit {
        unregisterAll()
        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }

    /// Registers `keyCode` (a `kVK_*` constant) with Carbon `modifiers` (e.g. `cmdKey | optionKey`).
    /// Returns false if the combination is already taken by another app.
    @discardableResult
    func register(keyCode: Int, modifiers: Int, action: @escaping () -> Void) -> Bool {
        let id = EventHotKeyID(signature: Self.signature, id: nextID)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(keyCode), UInt32(modifiers), id, GetApplicationEventTarget(), 0, &ref
        )
        guard status == noErr, let ref else { return false }

        registrations[nextID] = Registration(ref: ref, action: action)
        nextID += 1
        return true
    }

    func unregisterAll() {
        registrations.values.forEach { UnregisterEventHotKey($0.ref) }
        registrations.removeAll()
    }
}
