import SwiftUI
import AppKit

struct WindowAppearanceModifier: ViewModifier {
    let appearanceMode: AppearanceMode

    func body(content: Content) -> some View {
        content
            .background(WindowAppearanceAccessor(appearanceMode: appearanceMode))
    }
}

extension View {
    func syncWindowAppearance(_ appearanceMode: AppearanceMode) -> some View {
        modifier(WindowAppearanceModifier(appearanceMode: appearanceMode))
    }
}

private struct WindowAppearanceAccessor: NSViewRepresentable {
    let appearanceMode: AppearanceMode

    func makeNSView(context: Context) -> NSView {
        AppearanceTrackingView(appearanceMode: appearanceMode)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let view = nsView as? AppearanceTrackingView else { return }
        view.appearanceMode = appearanceMode
        view.apply()
    }
}

private final class AppearanceTrackingView: NSView {
    var appearanceMode: AppearanceMode

    init(appearanceMode: AppearanceMode) {
        self.appearanceMode = appearanceMode
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        apply()
    }

    func apply() {
        let targetAppearance = appearanceMode.nsAppearance

        // Align the app-level appearance so surfaces that do not own a
        // standard window (MenuBarExtra popover, some panels) follow the
        // selected mode. Passing nil here lets AppKit fall back to the
        // system appearance, which is what System mode expects.
        if NSApp.appearance?.name != targetAppearance?.name {
            NSApp.appearance = targetAppearance
        }

        guard let window else { return }
        if targetAppearance?.name != window.appearance?.name {
            window.appearance = targetAppearance
            window.contentView?.needsDisplay = true
            window.invalidateShadow()
        }
    }
}
