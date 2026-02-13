import SwiftUI

struct PopoverView: View {
    @ObservedObject var viewModel: UsageViewModel
    @State private var showingSettings = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Content
            ScrollView {
                contentView
                    .padding()
            }
            .frame(maxHeight: 400)
            
            Divider()
            
            // Footer
            footerView
        }
        .frame(width: 300)
        .sheet(isPresented: $showingSettings) {
            SettingsView(viewModel: viewModel)
        }
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
                showingSettings = true
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
            
            if let mcpQuota = data.mcpQuota {
                QuotaSectionView(quota: mcpQuota)
            }
            
            // Model usage section
            VStack(alignment: .leading, spacing: 8) {
                Label("Model Usage (24h)", systemImage: "cpu")
                    .font(.system(size: 13, weight: .semibold))
                
                VStack(spacing: 4) {
                    UsageRowView(
                        label: "Total Tokens",
                        value: data.modelUsage.formattedTokens
                    )
                    
                    UsageRowView(
                        label: "Total Calls",
                        value: data.modelUsage.formattedCalls
                    )
                }
            }
            .padding(12)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            
            // Tool usage section (if has data)
            if data.toolUsage.hasData {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Tool Usage (24h)", systemImage: "wrench.and.screwdriver")
                        .font(.system(size: 13, weight: .semibold))
                    
                    VStack(spacing: 4) {
                        if data.toolUsage.networkSearches > 0 {
                            UsageRowView(
                                label: "Network Searches",
                                value: data.toolUsage.formatted(data.toolUsage.networkSearches)
                            )
                        }
                        
                        if data.toolUsage.webReads > 0 {
                            UsageRowView(
                                label: "Web Reads",
                                value: data.toolUsage.formatted(data.toolUsage.webReads)
                            )
                        }
                        
                        if data.toolUsage.zreadCalls > 0 {
                            UsageRowView(
                                label: "ZRead Calls",
                                value: data.toolUsage.formatted(data.toolUsage.zreadCalls)
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
            Text("Updated: \(viewModel.lastUpdatedText)")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: {
                showingSettings = true
            }) {
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

#Preview {
    PopoverView(viewModel: UsageViewModel())
}
