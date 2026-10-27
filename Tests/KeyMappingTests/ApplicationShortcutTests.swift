import Testing

@testable import KeyMapping

@Test func shiftSwitchesApplicationsInBothDirections() {
    var mapping = KeyMapping()
    #expect(
        mapping.handle(keyCode: 0x66, isKeyDown: true, isRepeat: false, modifiers: .shift)
            == .switchApplication(.previous))
    #expect(
        mapping.handle(keyCode: 0x68, isKeyDown: true, isRepeat: false, modifiers: .shift) == .switchApplication(.next))
}

@Test func shiftWithAnotherModifierIsNotCaptured() {
    for other: KeyMapping.Modifiers in [.command, .control, .option, .function] {
        for key: UInt16 in [0x66, 0x68] {
            var mapping = KeyMapping()
            #expect(
                mapping.handle(keyCode: key, isKeyDown: true, isRepeat: false, modifiers: [.shift, other])
                    == .passThrough)
            #expect(mapping.handle(keyCode: key, isKeyDown: false, isRepeat: false, modifiers: []) == .passThrough)
        }
    }
}

@Test func heldWindowKeyCannotTurnIntoAnApplicationShortcut() {
    var mapping = KeyMapping()
    _ = mapping.handle(keyCode: 0x68, isKeyDown: true, isRepeat: false, modifiers: [])
    #expect(mapping.handle(keyCode: 0x68, isKeyDown: true, isRepeat: true, modifiers: .shift) == .suppress)
    #expect(mapping.handle(keyCode: 0x68, isKeyDown: false, isRepeat: false, modifiers: .shift) == .suppress)
    #expect(
        mapping.handle(keyCode: 0x68, isKeyDown: true, isRepeat: false, modifiers: .shift) == .switchApplication(.next))
}

@Test func releasingShiftDoesNotLeakAnApplicationShortcutRelease() {
    var mapping = KeyMapping()
    _ = mapping.handle(keyCode: 0x66, isKeyDown: true, isRepeat: false, modifiers: .shift)
    #expect(mapping.handle(keyCode: 0x66, isKeyDown: true, isRepeat: true, modifiers: []) == .suppress)
    #expect(mapping.handle(keyCode: 0x66, isKeyDown: false, isRepeat: false, modifiers: []) == .suppress)
    #expect(mapping.handle(keyCode: 0x66, isKeyDown: true, isRepeat: false, modifiers: []) == .switchWindow(.previous))
}

@Test func pausedApplicationShortcutsPassThrough() {
    var mapping = KeyMapping()
    mapping.isEnabled = false
    #expect(mapping.handle(keyCode: 0x66, isKeyDown: true, isRepeat: false, modifiers: .shift) == .passThrough)
    #expect(mapping.handle(keyCode: 0x66, isKeyDown: false, isRepeat: false, modifiers: .shift) == .passThrough)
}

@Test func pausingDuringAnApplicationShortcutConsumesItsRelease() {
    var mapping = KeyMapping()
    _ = mapping.handle(keyCode: 0x68, isKeyDown: true, isRepeat: false, modifiers: .shift)
    mapping.isEnabled = false
    #expect(mapping.handle(keyCode: 0x68, isKeyDown: false, isRepeat: false, modifiers: []) == .suppress)
    #expect(mapping.handle(keyCode: 0x68, isKeyDown: true, isRepeat: false, modifiers: .shift) == .passThrough)
}

@Test func shiftDoesNotCaptureOtherKeys() {
    var mapping = KeyMapping()
    for key: UInt16 in [0, 0x30, 0x38] {
        #expect(mapping.handle(keyCode: key, isKeyDown: true, isRepeat: false, modifiers: .shift) == .passThrough)
        #expect(mapping.handle(keyCode: key, isKeyDown: false, isRepeat: false, modifiers: []) == .passThrough)
    }
}
