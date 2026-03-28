import SwiftUI

// MARK: - UsageProgressBar

struct UsageProgressBar: View {
    let progress: Double  // 0.0 to 1.0
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(ClaudeTheme.progressTrack)
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(ClaudeTheme.accent)
                    .frame(width: max(height, geo.size.width * min(max(progress, 0), 1)))
            }
        }
        .frame(height: height)
    }
}

// MARK: - MenuBarHeaderView

struct MenuBarHeaderView: View {
    var onRefresh: (() -> Void)? = nil
    var isPolling: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text("Usage for Claude")
                    .font(.headline)
                    .foregroundStyle(ClaudeTheme.textPrimary)
                Spacer()
                Button { } label: {
                    Image(systemName: "questionmark.circle")
                        .foregroundStyle(ClaudeTheme.textSecondary)
                }
                .buttonStyle(.plain)
                Button { } label: {
                    Image(systemName: "message")
                        .foregroundStyle(ClaudeTheme.textSecondary)
                }
                .buttonStyle(.plain)
                if let onRefresh {
                    Button {
                        guard !isPolling else { return }
                        onRefresh()
                    } label: {
                        if isPolling {
                            ProgressView()
                                .controlSize(.small)
                                .tint(ClaudeTheme.textSecondary)
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(ClaudeTheme.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            Divider()
                .overlay(ClaudeTheme.progressTrack)
        }
    }
}
