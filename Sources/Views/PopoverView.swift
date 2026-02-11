import SwiftUI

struct PopoverView: View {
    @ObservedObject var viewModel: UsageViewModel

    var body: some View {
        if viewModel.isSetupComplete {
            usageView
        } else {
            setupView
        }
    }

    // MARK: - Setup

    @State private var sessionKey: String = ""
    @State private var isTesting: Bool = false
    @State private var errorMessage: String? = nil

    private var setupView: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 28))
                .foregroundColor(.blue)

            Text("Claudephobia")
                .font(.headline)

            Text("Fear of hitting Claude limits")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()

            Text("Paste your session key to get started.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            SecureField("sk-ant-sid01-...", text: $sessionKey)
                .textFieldStyle(.roundedBorder)
                .font(.system(.caption, design: .monospaced))

            VStack(alignment: .leading, spacing: 3) {
                Text("How to get it:")
                    .font(.caption2)
                    .fontWeight(.medium)
                Text("1. Open claude.ai in your browser")
                Text("2. DevTools (Cmd+Opt+I) \u{2192} Application")
                Text("3. Cookies \u{2192} claude.ai \u{2192} sessionKey")
            }
            .font(.caption2)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("No cost. Uses your existing session cookie.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .italic()

            if let error = errorMessage {
                Text(error)
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .lineLimit(2)
            }

            Button(action: connect) {
                if isTesting {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 60, height: 14)
                } else {
                    Text("Connect")
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(sessionKey.trimmingCharacters(in: .whitespaces).isEmpty || isTesting)
        }
        .padding(16)
        .frame(width: 280)
    }

    private func connect() {
        let key = sessionKey.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { return }

        isTesting = true
        errorMessage = nil

        let client = ClaudeAPIClient(sessionKey: key)
        Task { @MainActor in
            do {
                _ = try await client.testConnection()
                viewModel.completeSetup(sessionKey: key)
            } catch {
                errorMessage = error.localizedDescription
            }
            isTesting = false
        }
    }

    // MARK: - Usage View

    private var usageView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Claudephobia")
                        .font(.headline)
                    if let tier = viewModel.rateLimitTier {
                        Text(tierDisplayName(tier))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Button(action: { viewModel.showSettingsWindow = true }) {
                    Image(systemName: "gear")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 14)

            // 5-hour session
            usageRow(
                title: "5-hour session",
                percent: viewModel.sessionPercent,
                resetDescription: viewModel.sessionResetDescription,
                tint: barColor(viewModel.sessionPercent)
            )

            Divider().padding(.vertical, 10)

            // 7-day weekly
            usageRow(
                title: "7-day weekly",
                percent: viewModel.weeklyPercent,
                resetDescription: viewModel.weeklyResetDescription,
                tint: barColor(viewModel.weeklyPercent)
            )

            // Model-specific limits (only shown when available)
            if let opusPct = viewModel.opusPercent {
                Divider().padding(.vertical, 10)
                usageRow(
                    title: "Weekly \u{2014} Opus",
                    percent: opusPct,
                    resetDescription: viewModel.opusResetDescription ?? "",
                    tint: barColor(opusPct)
                )
            }

            if let sonnetPct = viewModel.sonnetPercent {
                Divider().padding(.vertical, 10)
                usageRow(
                    title: "Weekly \u{2014} Sonnet",
                    percent: sonnetPct,
                    resetDescription: viewModel.sonnetResetDescription ?? "",
                    tint: barColor(sonnetPct)
                )
            }

            // Extra usage
            if let extraPct = viewModel.extraUsagePercent {
                Divider().padding(.vertical, 10)
                usageRow(
                    title: "Extra usage",
                    percent: extraPct,
                    resetDescription: viewModel.extraUsageResetDescription ?? "",
                    tint: .purple
                )
            }

            Divider().padding(.vertical, 10)

            // Error
            if let error = viewModel.errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.orange)
                        .lineLimit(2)
                }
                .padding(.bottom, 8)
            }

            // Footer
            HStack(spacing: 6) {
                if let updated = viewModel.lastUpdated {
                    Text(timeAgo(updated))
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.6))
                }
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.4)
                        .frame(width: 10, height: 10)
                }
                Spacer()

                Menu {
                    Button { viewModel.pendingShareAction = .shareImage } label: {
                        Label("Share Image\u{2026}", systemImage: "photo")
                    }
                    Button { viewModel.pendingShareAction = .copyImage } label: {
                        Label("Copy to Clipboard", systemImage: "doc.on.doc")
                    }
                    Button { viewModel.pendingShareAction = .saveImage } label: {
                        Label("Save as PNG\u{2026}", systemImage: "arrow.down.doc")
                    }
                    Divider()
                    Button { viewModel.pendingShareAction = .exportJSON } label: {
                        Label("Export JSON\u{2026}", systemImage: "curlybraces")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 16)
                .help("Share usage card")

                Button(action: { viewModel.fetchUsage() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Refresh")

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary.opacity(0.6))
                .font(.caption)
            }
        }
        .padding(16)
        .frame(width: 300)
    }

    // MARK: - Usage Row

    private func usageRow(title: String, percent: Double, resetDescription: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .font(.system(.subheadline, weight: .medium))
                Spacer()
                Text("\(Int(percent * 100))%")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundColor(tint)
            }

            UsageProgressBar(value: percent, tint: tint)
                .frame(height: 6)

            if !resetDescription.isEmpty {
                Text(resetDescription)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Helpers

    private func barColor(_ percent: Double) -> Color {
        if percent >= 0.9 { return .red }
        if percent >= 0.7 { return .orange }
        return .blue
    }

    private func tierDisplayName(_ tier: String) -> String {
        tier.replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "claude ai", with: "Claude AI")
            .capitalized
    }

    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 60 { return "just now" }
        let minutes = seconds / 60
        if minutes == 1 { return "1 min ago" }
        if minutes < 60 { return "\(minutes) min ago" }
        let hours = minutes / 60
        if hours == 1 { return "1 hr ago" }
        return "\(hours) hr ago"
    }
}

// MARK: - Progress Bar

struct UsageProgressBar: View {
    let value: Double
    var tint: Color = .blue

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.15))

                Capsule()
                    .fill(tint)
                    .frame(width: max(0, geo.size.width * CGFloat(min(1, value))))
            }
        }
    }
}
