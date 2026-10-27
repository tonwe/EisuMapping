import Testing

@testable import KeyMapping

@Test func acceptsAppWindowsWithMissingOrUnknownSubroles() {
    for subrole: String? in [nil, "AXUnknown", "AXStandardWindow"] {
        #expect(WindowEligibility.isSwitchable(role: "AXWindow", subrole: subrole, minimized: false, modal: false))
    }
}

@Test func skipsPanelsDialogsAndMinimizedWindows() {
    for subrole in ["AXFloatingWindow", "AXDialog", "AXSystemFloatingWindow", "AXSystemDialog"] {
        #expect(!WindowEligibility.isSwitchable(role: "AXWindow", subrole: subrole, minimized: false, modal: false))
    }
    #expect(
        !WindowEligibility.isSwitchable(role: "AXWindow", subrole: "AXStandardWindow", minimized: true, modal: false))
    #expect(
        !WindowEligibility.isSwitchable(role: "AXWindow", subrole: "AXStandardWindow", minimized: false, modal: true))
    #expect(!WindowEligibility.isSwitchable(role: "AXSheet", subrole: nil, minimized: false, modal: false))
}
