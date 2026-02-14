import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: UsageViewModel
    var onClose: (() -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var apiKey: String = ""
    @State private var showingAPIKey: Bool = false
    @State private var saveError: String?
    @State private var isSaving: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Button(action: { close() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.gray.opacity(0.03))
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // API Key Section
                    apiKeySection
                    
                    Divider()
                    
                    // Platform Section
                    platformSection
                    
                    Divider()
                    
                    // Refresh Section
                    refreshSection
                    
                    Divider()
                    
                    // Notifications Section
                    notificationsSection
                }
                .padding()
            }
            
            Divider()
            
            // Footer
            HStack {
                if let error = saveError {
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                Button("Cancel") {
                    close()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Save") {
                    Task {
                        await saveSettings()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(isSaving)
            }
            .padding()
        }
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    // MARK: - API Key Section
    
    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("API Key")
                .font(.system(size: 13, weight: .semibold))
            
            Text("Your Z.ai API key is stored securely in the system keychain.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            HStack {
                if showingAPIKey {
                    TextField("API Key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                } else {
                    SecureField("API Key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                }
                
                Button(action: { showingAPIKey.toggle() }) {
                    Image(systemName: showingAPIKey ? "eye.slash" : "eye")
                }
                .buttonStyle(.bordered)
                .help(showingAPIKey ? "Hide API Key" : "Show API Key")
            }
            
            if viewModel.hasAPIKey {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("API key is configured")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Remove", role: .destructive) {
                        viewModel.deleteAPIKey()
                        apiKey = ""
                    }
                    .controlSize(.small)
                }
            }
        }
    }
    
    // MARK: - Platform Section
    
    private var platformSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Platform")
                .font(.system(size: 13, weight: .semibold))
            
            Picker("Platform", selection: $viewModel.platform) {
                ForEach(Platform.allCases, id: \.self) { platform in
                    Text(platform.displayName).tag(platform)
                }
            }
            .pickerStyle(.radioGroup)
        }
    }
    
    // MARK: - Refresh Section
    
    private var refreshSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Auto Refresh")
                .font(.system(size: 13, weight: .semibold))
            
            Picker("Refresh Interval", selection: $viewModel.refreshInterval) {
                ForEach(Constants.RefreshInterval.all, id: \.self) { interval in
                    Text(Constants.RefreshInterval.label(interval)).tag(interval)
                }
            }
            .pickerStyle(.menu)
        }
    }
    
    // MARK: - Notifications Section
    
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notifications")
                .font(.system(size: 13, weight: .semibold))
            
            Toggle("Enable notifications", isOn: $viewModel.notificationsEnabled)
                .font(.system(size: 12))
            
            if viewModel.notificationsEnabled {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Alert when usage exceeds:")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    Picker("Threshold", selection: $viewModel.notificationThreshold) {
                        ForEach(Constants.NotificationThreshold.all, id: \.self) { threshold in
                            Text(Constants.NotificationThreshold.label(threshold)).tag(threshold)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadCurrentSettings() {
        apiKey = viewModel.cachedAPIKey ?? ""
    }
    
    private func saveSettings() async {
        isSaving = true
        saveError = nil
        
        do {
            if !apiKey.isEmpty {
                try await viewModel.saveAPIKey(apiKey)
            }
            viewModel.updatePlatform(viewModel.platform)
            viewModel.updateRefreshInterval(viewModel.refreshInterval)
            viewModel.updateNotificationThreshold(viewModel.notificationThreshold)
            viewModel.toggleNotifications(viewModel.notificationsEnabled)
            close()
        } catch {
            saveError = error.localizedDescription
        }
        
        isSaving = false
    }
    
    private func close() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }
}

#Preview {
    SettingsView(viewModel: UsageViewModel())
}
