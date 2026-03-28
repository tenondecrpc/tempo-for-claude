import SwiftUI

// MARK: - ClaudeTheme
// Design tokens for the Claude visual identity. Scoped to the macOS target.

enum ClaudeTheme {
    static let background    = Color(red: 0.118, green: 0.165, blue: 0.227)  // #1E2A3A
    static let surface       = Color(red: 0.149, green: 0.200, blue: 0.278)  // #263347
    static let accent        = Color(red: 0.878, green: 0.471, blue: 0.314)  // #E07850
    static let textPrimary   = Color.white
    static let textSecondary = Color(red: 0.533, green: 0.600, blue: 0.667)  // #8899AA
    static let progressTrack = Color(red: 0.227, green: 0.290, blue: 0.361)  // #3A4A5C
    static let destructive   = Color(red: 0.878, green: 0.314, blue: 0.314)  // #E05050
    static let lockIcon      = Color(red: 0.357, green: 0.608, blue: 0.835)  // #5B9BD5
}
