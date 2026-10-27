public enum WindowEligibility {
    /// Some apps report AXUnknown or omit their window subrole. Only exclude
    /// known non-document windows, rather than requiring AXStandardWindow.
    public static func isSwitchable(role: String?, subrole: String?, minimized: Bool?, modal: Bool?) -> Bool {
        guard role == "AXWindow", minimized != true, modal != true else { return false }
        let excluded = ["AXFloatingWindow", "AXDialog", "AXSystemFloatingWindow", "AXSystemDialog"]
        return !excluded.contains(subrole ?? "")
    }
}
