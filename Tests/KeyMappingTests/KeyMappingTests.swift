import Testing

@testable import KeyMapping

@Test func mapsJISKeysInBothDirections() {
    var mapping = KeyMapping()
    #expect(
        mapping.handle(keyCode: 0x66, isKeyDown: true, isRepeat: false, hasModifiers: false) == .switchWindow(.previous)
    )
    #expect(
        mapping.handle(keyCode: 0x68, isKeyDown: true, isRepeat: false, hasModifiers: false) == .switchWindow(.next))
}

@Test func preservesOtherKeysAndModifiedJISKeys() {
    var mapping = KeyMapping()
    for key: UInt16 in [0, 0x30, 0x66, 0x68] {
        #expect(mapping.handle(keyCode: key, isKeyDown: true, isRepeat: false, hasModifiers: true) == .passThrough)
        #expect(mapping.handle(keyCode: key, isKeyDown: false, isRepeat: false, hasModifiers: false) == .passThrough)
    }
    #expect(mapping.handle(keyCode: 0, isKeyDown: true, isRepeat: false, hasModifiers: false) == .passThrough)
}

@Test func suppressesRepeatAndReleaseEvenAfterModifiersChange() {
    var mapping = KeyMapping()
    _ = mapping.handle(keyCode: 0x66, isKeyDown: true, isRepeat: false, hasModifiers: false)
    #expect(mapping.handle(keyCode: 0x66, isKeyDown: true, isRepeat: true, hasModifiers: false) == .suppress)
    #expect(mapping.handle(keyCode: 0x66, isKeyDown: false, isRepeat: false, hasModifiers: true) == .suppress)
    #expect(
        mapping.handle(keyCode: 0x66, isKeyDown: true, isRepeat: false, hasModifiers: false) == .switchWindow(.previous)
    )
}

@Test func pauseDuringPressStillConsumesTheMatchingRelease() {
    var mapping = KeyMapping()
    _ = mapping.handle(keyCode: 0x68, isKeyDown: true, isRepeat: false, hasModifiers: false)
    mapping.isEnabled = false
    #expect(mapping.handle(keyCode: 0x68, isKeyDown: false, isRepeat: false, hasModifiers: false) == .suppress)
    #expect(mapping.handle(keyCode: 0x68, isKeyDown: true, isRepeat: false, hasModifiers: false) == .passThrough)
    #expect(mapping.handle(keyCode: 0x68, isKeyDown: false, isRepeat: false, hasModifiers: false) == .passThrough)
}

@Test func resumeDoesNotCaptureAnAlreadyHeldKey() {
    var mapping = KeyMapping()
    mapping.isEnabled = false
    _ = mapping.handle(keyCode: 0x68, isKeyDown: true, isRepeat: false, hasModifiers: false)
    mapping.isEnabled = true
    #expect(mapping.handle(keyCode: 0x68, isKeyDown: true, isRepeat: true, hasModifiers: false) == .passThrough)
    #expect(mapping.handle(keyCode: 0x68, isKeyDown: false, isRepeat: false, hasModifiers: false) == .passThrough)
}

@Test func resetClearsCapturedKeysAfterTapInterruption() {
    var mapping = KeyMapping()
    _ = mapping.handle(keyCode: 0x66, isKeyDown: true, isRepeat: false, hasModifiers: false)
    mapping.reset()
    #expect(mapping.handle(keyCode: 0x66, isKeyDown: false, isRepeat: false, hasModifiers: false) == .passThrough)
    #expect(mapping.handle(keyCode: 0x66, isKeyDown: true, isRepeat: true, hasModifiers: false) == .passThrough)
}
