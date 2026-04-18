import SwiftUI

private struct ClaudeAppearanceScope<Content: View>: View {
    let appearanceMode: AppearanceMode
    @ViewBuilder let content: () -> Content
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        #if os(watchOS)
        // watchOS has no platform dynamic color provider, so mirror the
        // effective appearance into the process-wide fallback. Tagging
        // the subtree with `.id(appearanceMode)` forces SwiftUI to rebuild
        // views that would otherwise cache the previous palette (the
        // theme's static-var resolution is invisible to the diffing pass).
        ClaudeCodeTheme.setResolvedAppearanceMode(appearanceMode.resolved(for: colorScheme))
        return content()
            .id(appearanceMode)
            .preferredColorScheme(appearanceMode.colorScheme)
        #elseif os(macOS)
        // `.preferredColorScheme(nil)` does not clear `NSApp.appearance` once
        // a concrete scheme has been applied, which strands the window on the
        // previous mode when the user picks System. `syncWindowAppearance`
        // owns both window and app appearance on macOS, so skip the modifier.
        return content()
        #else
        return content()
            .preferredColorScheme(appearanceMode.colorScheme)
        #endif
    }
}

extension View {
    func applyClaudeAppearance(_ appearanceMode: AppearanceMode) -> some View {
        ClaudeAppearanceScope(appearanceMode: appearanceMode) {
            self
        }
    }
}
