import SwiftUI

extension Color {
    // MARK: - Accents
    /// Primary brand accent — Claude terracotta #C15F3C
    static let claudeAccent      = Color(red: 0.757, green: 0.373, blue: 0.235)
    /// Darker accent for hover/pressed states — #A14A2F
    static let claudeAccentDark  = Color(red: 0.631, green: 0.290, blue: 0.184)
    /// Lighter warm accent — #D4916A
    static let claudeAccentLight = Color(red: 0.831, green: 0.569, blue: 0.416)

    // MARK: - Backgrounds
    /// Deepest background — #1a1815
    static let claudeBgDeep     = Color(red: 0.102, green: 0.094, blue: 0.082)
    /// Elevated surface (sidebars, cards) — #201d18
    static let claudeBgElevated = Color(red: 0.125, green: 0.114, blue: 0.094)
    /// Surface layer (activity bar, inactive tabs) — #2a251d
    static let claudeBgSurface  = Color(red: 0.165, green: 0.145, blue: 0.114)
    /// Dividers and borders — #3a352b
    static let claudeBorder     = Color(red: 0.227, green: 0.208, blue: 0.169)

    // MARK: - Text
    /// Primary text — warm off-white #e8e6e3
    static let claudeTextPrimary   = Color(red: 0.910, green: 0.902, blue: 0.890)
    /// Secondary / muted text — #9a9389
    static let claudeTextSecondary = Color(red: 0.604, green: 0.576, blue: 0.537)
    /// Tertiary / dim text — #6a6158
    static let claudeTextTertiary  = Color(red: 0.416, green: 0.380, blue: 0.345)

    // MARK: - Status
    /// Success / low utilization — #4caf50
    static let claudeGreen  = Color(red: 0.298, green: 0.686, blue: 0.314)
    /// Warning / medium utilization — #f3df31
    static let claudeYellow = Color(red: 0.953, green: 0.875, blue: 0.192)
    /// Critical / high utilization — #ff6b6b
    static let claudeRed    = Color(red: 1.000, green: 0.420, blue: 0.420)
    /// Informational / 7d ring — #42a5f5
    static let claudeBlue   = Color(red: 0.259, green: 0.647, blue: 0.961)

    // MARK: - Ring Tracks
    /// Outer ring track background
    static let claudeRingTrack      = Color.white.opacity(0.15)
    /// Inner ring track background
    static let claudeRingTrackInner = Color.white.opacity(0.10)
}
