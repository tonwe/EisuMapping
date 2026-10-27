import Testing

@testable import KeyMapping

@Test func mapsJISKeysInBothDirections() {
    var mapping = KeyMapping()
    #expect(
        mapping.handle(keyCode: 0x66, isKeyDown: true, isRepeat: false, modifiers: []) == .switchWindow(.previous)
    )
    #expect(
        mapping.handle(keyCode: 0x68, isKeyDown: true, isRepeat: false, modifiers: []) == .switchWindow(.next))
}

@Test func preservesOtherKeysAndModifiedJISKeys() {
    var mapping = KeyMapping()
    for key: UInt16 in [0, 0x30, 0x66, 0x68] {
        #expect(mapping.handle(keyCode: key, isKeyDown: true, isRepeat: false, modifiers: .command) == .passThrough)
        #expect(mapping.handle(keyCode: key, isKeyDown: false, isRepeat: false, modifiers: []) == .passThrough)
    }
    #expect(mapping.handle(keyCode: 0, isKeyDown: true, isRepeat: false, modifiers: []) == .passThrough)
}

@Test func suppressesRepeatAndReleaseEvenAfterModifiersChange() {
    var mapping = KeyMapping()
    _ = mapping.handle(keyCode: 0x66, isKeyDown: true, isRepeat: false, modifiers: [])
    #expect(mapping.handle(keyCode: 0x66, isKeyDown: true, isRepeat: true, modifiers: []) == .suppress)
    #expect(mapping.handle(keyCode: 0x66, isKeyDown: false, isRepeat: false, modifiers: .command) == .suppress)
    #expect(
        mapping.handle(keyCode: 0x66, isKeyDown: true, isRepeat: false, modifiers: []) == .switchWindow(.previous)
    )
}

@Test func pauseDuringPressStillConsumesTheMatchingRelease() {
    var mapping = KeyMapping()
    _ = mapping.handle(keyCode: 0x68, isKeyDown: true, isRepeat: false, modifiers: [])
    mapping.isEnabled = false
    #expect(mapping.handle(keyCode: 0x68, isKeyDown: false, isRepeat: false, modifiers: []) == .suppress)
    #expect(mapping.handle(keyCode: 0x68, isKeyDown: true, isRepeat: false, modifiers: []) == .passThrough)
    #expect(mapping.handle(keyCode: 0x68, isKeyDown: false, isRepeat: false, modifiers: []) == .passThrough)
}

@Test func resumeDoesNotCaptureAnAlreadyHeldKey() {
    var mapping = KeyMapping()
    mapping.isEnabled = false
    _ = mapping.handle(keyCode: 0x68, isKeyDown: true, isRepeat: false, modifiers: [])
    mapping.isEnabled = true
    #expect(mapping.handle(keyCode: 0x68, isKeyDown: true, isRepeat: true, modifiers: []) == .passThrough)
    #expect(mapping.handle(keyCode: 0x68, isKeyDown: false, isRepeat: false, modifiers: []) == .passThrough)
}

@Test func resetClearsCapturedKeysAfterTapInterruption() {
    var mapping = KeyMapping()
    _ = mapping.handle(keyCode: 0x66, isKeyDown: true, isRepeat: false, modifiers: [])
    mapping.reset()
    #expect(mapping.handle(keyCode: 0x66, isKeyDown: false, isRepeat: false, modifiers: []) == .passThrough)
    #expect(mapping.handle(keyCode: 0x66, isKeyDown: true, isRepeat: true, modifiers: []) == .passThrough)
}
