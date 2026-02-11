import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "General"
    case notifications = "Notifications"
    case account = "Account"
    case data = "Data"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .notifications: return "bell"
        case .account: return "key"
        case .data: return "externaldrive"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: UsageViewModel
    var onClose: () -> Void

    @State private var selectedTab: SettingsTab = .general
    @State private var newSessionKey: String = ""
    @State private var showResetConfirm = false

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(spacing: 2) {
                ForEach(SettingsTab.allCases) { tab in
                    sidebarButton(tab)
                }
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .frame(width: 160)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))

            Divider()

            // Content
            VStack(alignment: .leading, spacing: 0) {
                Text(selectedTab.rawValue)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.bottom, 16)

                ScrollView {
                    tabContent
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer(minLength: 8)

                HStack {
                    Spacer()
                    Button("Done") { onClose() }
                        .keyboardShortcut(.return)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 540, height: 480)
        .alert("Reset all data?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset Everything", role: .destructive) {
                viewModel.resetAllData()
                onClose()
            }
        } message: {
            Text("This deletes all Claudephobia data including your session key from Keychain and removes the LaunchAgent.")
        }
    }

    // MARK: - Sidebar Button

    private func sidebarButton(_ tab: SettingsTab) -> some View {
        Button(action: { selectedTab = tab }) {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .frame(width: 18)
                    .foregroundColor(selectedTab == tab ? .white : .secondary)
                Text(tab.rawValue)
                    .foregroundColor(selectedTab == tab ? .white : .primary)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(selectedTab == tab ? Color.accentColor : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .general:
            generalTab
        case .notifications:
            notificationsTab
        case .account:
            accountTab
        case .data:
            dataTab
        }
    }

    // MARK: - General

    private var generalTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Text display")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Picker("Display", selection: Binding(
                    get: { viewModel.menuBarDisplayMode },
                    set: { viewModel.setMenuBarDisplayMode($0) }
                )) {
                    Text("Icon only").tag(0)
                    Text("Icon + percentages").tag(1)
                    Text("Icon + compact").tag(2)
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Auto-refresh interval")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Picker("Interval", selection: Binding(
                    get: { viewModel.refreshInterval },
                    set: { viewModel.setRefreshInterval($0) }
                )) {
                    Text("Every 1 minute").tag(60)
                    Text("Every 5 minutes").tag(300)
                    Text("Every 10 minutes").tag(600)
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Toggle("Launch at login", isOn: Binding(
                    get: { viewModel.launchAtLogin },
                    set: { _ in viewModel.toggleLaunchAtLogin() }
                ))

                Text("Creates a LaunchAgent to start Claudephobia on login")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Notifications

    private var notificationsTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            Toggle("Enable notifications", isOn: Binding(
                get: { viewModel.notificationsEnabled },
                set: { _ in viewModel.toggleNotifications() }
            ))

            if viewModel.notificationsEnabled {
                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Thresholds")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                                .frame(width: 18)
                            Text("Warning at")
                                .frame(width: 80, alignment: .leading)
                            Picker("", selection: Binding(
                                get: { viewModel.warningThreshold },
                                set: { viewModel.setWarningThreshold($0) }
                            )) {
                                Text("75%").tag(0.75)
                                Text("80%").tag(0.80)
                                Text("90%").tag(0.90)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 180)
                        }

                        HStack {
                            Image(systemName: "flame")
                                .foregroundColor(.red)
                                .frame(width: 18)
                            Text("Critical at")
                                .frame(width: 80, alignment: .leading)
                            Picker("", selection: Binding(
                                get: { viewModel.criticalThreshold },
                                set: { viewModel.setCriticalThreshold($0) }
                            )) {
                                Text("90%").tag(0.90)
                                Text("95%").tag(0.95)
                                Text("100%").tag(1.00)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 180)
                        }
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Toggle("Notify when limits reset", isOn: Binding(
                        get: { viewModel.notifyOnReset },
                        set: { _ in viewModel.toggleNotifyOnReset() }
                    ))

                    Text("Get notified when a rate limit window resets and your usage is restored.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Monitored limits")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    VStack(alignment: .leading, spacing: 4) {
                        Label("5-hour session", systemImage: "clock")
                        Label("7-day weekly", systemImage: "calendar")
                        Label("Opus weekly (when available)", systemImage: "sparkles")
                        Label("Sonnet weekly (when available)", systemImage: "sparkles")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Button("Send Test Notification") {
                        viewModel.sendTestNotification()
                    }

                    Text("Notifications are sent via native macOS alerts. No permission required.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Account

    private var accountTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Session key")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 4) {
                    Image(systemName: "lock.shield")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("Stored securely in macOS Keychain")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                SecureField("Paste new session key...", text: $newSessionKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))

                Button("Update Session Key") {
                    let key = newSessionKey.trimmingCharacters(in: .whitespaces)
                    if !key.isEmpty {
                        viewModel.updateSessionKey(key)
                        newSessionKey = ""
                    }
                }
                .disabled(newSessionKey.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("About")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("Claudephobia reads your usage data directly from the Claude API using your session cookie. No data is sent to any third party. No cost involved.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Data

    private var dataTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Export")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("Save current usage data as a JSON file for external tools or dashboards.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Export Usage JSON...") {
                    viewModel.exportToFile()
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Reset")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("Remove all Claudephobia data including session key, settings, and LaunchAgent.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Reset All Data...") {
                    showResetConfirm = true
                }
                .foregroundColor(.red)
            }
        }
    }
}
