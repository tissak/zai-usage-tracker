import SwiftUI
import Combine

struct PopoverView: View {
    @ObservedObject var viewModel: UsageViewModel
    @State private var updateTimer: Timer?
    @State private var timeUpdateTrigger = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Content
            contentView
                .padding()
            
            Divider()
            
            // Footer
            footerView
                .id(timeUpdateTrigger) // Forces re-render when timer fires
        }
        .frame(width: 300)
        .onAppear {
            viewModel.isPopoverOpen = true
            startUpdateTimer()
            Task {
                await viewModel.refresh()
            }
        }
        .onDisappear {
            viewModel.isPopoverOpen = false
            stopUpdateTimer()
        }
    }
    
    // MARK: - Timer Management
    
    private func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in
                timeUpdateTrigger.toggle()
            }
        }
    }
    
    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Image(systemName: "waveform.path")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(viewModel.statusColor))
            
            Text("Z.ai Usage Tracker")
                .font(.system(size: 14, weight: .semibold))
            
            Spacer()
            
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 20, height: 20)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.03))
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var contentView: some View {
        if !viewModel.hasAPIKey {
            noAPIKeyView
        } else if let error = viewModel.errorMessage {
            errorView(error)
        } else if let data = viewModel.usageData {
            usageDataView(data)
        } else {
            loadingView
        }
    }
    
    private var noAPIKeyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "key.fill")
                .font(.system(size: 32))
                .foregroundColor(.orange)
            
            Text("API Key Required")
                .font(.system(size: 14, weight: .semibold))
            
            Text("Add your Z.ai API key to start tracking usage.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Open Settings") {
                SettingsWindowController.shared.show(viewModel: viewModel)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundColor(.red)
            
            Text("Error Loading Usage")
                .font(.system(size: 14, weight: .semibold))
            
            Text(message)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                Task {
                    await viewModel.refresh()
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading usage data...")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private func usageDataView(_ data: UsageData) -> some View {
        VStack(spacing: 16) {
            // Platform indicator
            HStack {
                Text(viewModel.platform.displayName)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
                Text(DateHelper.formatDateTime(data.periodStart) + " → " + DateHelper.formatTime(data.periodEnd))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            // Quota sections
            if let tokenQuota = data.tokenQuota {
                QuotaSectionView(quota: tokenQuota)
            }

            WeeklyTokenSectionView(
                totalTokens: data.weeklyModelUsage.totalTokens,
                limit: viewModel.weeklyTokenLimit,
                apiResetTime: data.weeklyResetTime
            )

            if let mcpQuota = data.mcpQuota {
                QuotaSectionView(quota: mcpQuota)
            }
            
            // Model usage section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Model Usage", systemImage: "cpu")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Text("24h / 7d")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 4) {
                    DualPeriodRowView(
                        label: "Total Tokens",
                        value24h: data.modelUsage.formattedTokens,
                        value7d: DateHelper.formatCompact(data.weeklyModelUsage.totalTokens)
                    )

                    DualPeriodRowView(
                        label: "Total Calls",
                        value24h: data.modelUsage.formattedCalls,
                        value7d: DateHelper.formatCompact(data.weeklyModelUsage.totalCalls)
                    )
                }
            }
            .padding(12)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)

            // Tool usage section (if has data)
            if data.toolUsage.hasData || data.weeklyToolUsage.hasData {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Tool Usage", systemImage: "wrench.and.screwdriver")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Text("24h / 7d")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    VStack(spacing: 4) {
                        if data.toolUsage.networkSearches > 0 || data.weeklyToolUsage.networkSearches > 0 {
                            DualPeriodRowView(
                                label: "Network Searches",
                                value24h: data.toolUsage.formatted(data.toolUsage.networkSearches),
                                value7d: DateHelper.formatCompact(data.weeklyToolUsage.networkSearches)
                            )
                        }

                        if data.toolUsage.webReads > 0 || data.weeklyToolUsage.webReads > 0 {
                            DualPeriodRowView(
                                label: "Web Reads",
                                value24h: data.toolUsage.formatted(data.toolUsage.webReads),
                                value7d: DateHelper.formatCompact(data.weeklyToolUsage.webReads)
                            )
                        }

                        if data.toolUsage.zreadCalls > 0 || data.weeklyToolUsage.zreadCalls > 0 {
                            DualPeriodRowView(
                                label: "ZRead Calls",
                                value24h: data.toolUsage.formatted(data.toolUsage.zreadCalls),
                                value7d: DateHelper.formatCompact(data.weeklyToolUsage.zreadCalls)
                            )
                        }
                    }
                }
                .padding(12)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        HStack {
            Button(action: { NSApplication.shared.terminate(nil) }) {
                Image(systemName: "power")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .help("Quit")
            
            Spacer()
            
            Text("Updated: \(viewModel.lastUpdatedText)")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: { SettingsWindowController.shared.show(viewModel: viewModel) }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.03))
    }
    
}

private struct DualPeriodRowView: View {
    let label: String
    let value24h: String
    let value7d: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Spacer()
            Text(value24h)
                .font(.system(size: 12, weight: .medium))
            Text("/")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Text(value7d)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    PopoverView(viewModel: UsageViewModel())
}
