import SwiftUI
#if os(macOS)
import AppKit
#endif

enum UtilizationSeverity: Equatable {
    static let warningThreshold = 0.60
    static let criticalThreshold = 0.80

    case normal
    case warning
    case critical

    init(utilization: Double) {
        let clampedUtilization = max(0, min(utilization, 1))

        if clampedUtilization >= Self.criticalThreshold {
            self = .critical
        } else if clampedUtilization >= Self.warningThreshold {
            self = .warning
        } else {
            self = .normal
        }
    }

    func usageColor(
        normal normalColor: Color,
        warning warningColor: Color = ClaudeCodeTheme.Usage.warning,
        critical criticalColor: Color = ClaudeCodeTheme.Usage.critical
    ) -> Color {
        switch self {
        case .normal:
            normalColor
        case .warning:
            warningColor
        case .critical:
            criticalColor
        }
    }

    #if os(macOS)
    func usageColor(
        normal normalColor: NSColor,
        warning warningColor: NSColor = ClaudeCodeTheme.Usage.menuBarWarning,
        critical criticalColor: NSColor = ClaudeCodeTheme.Usage.menuBarCritical
    ) -> NSColor {
        switch self {
        case .normal:
            normalColor
        case .warning:
            warningColor
        case .critical:
            criticalColor
        }
    }
    #endif
}
