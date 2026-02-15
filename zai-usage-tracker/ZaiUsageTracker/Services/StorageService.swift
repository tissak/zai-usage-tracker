import Foundation

// MARK: - Storage Service

@MainActor
final class StorageService: ObservableObject {

    // MARK: - Published Properties

    @Published var currentBackend: StorageBackend = .keychain

    // MARK: - Initialization

    init() {
        loadBackendPreference()
    }

    // MARK: - Public Methods

    func saveAPIKey(_ apiKey: String) throws {
        let backend = getActiveBackend()
        try backend.saveAPIKey(apiKey)
    }

    func getAPIKey() -> String? {
        let backend = getActiveBackend()
        return backend.getAPIKey()
    }

    func deleteAPIKey() throws {
        let backend = getActiveBackend()
        try backend.deleteAPIKey()
    }

    func migrate(to newBackend: StorageBackend) throws {
        // Get the current backend
        let currentBackend = getBackend(for: self.currentBackend)

        // Get the API key from current backend
        guard let apiKey = currentBackend.getAPIKey() else {
            // No API key to migrate, just update the backend preference
            updateBackendPreference(to: newBackend)
            return
        }

        // Get the new backend instance
        let activeBackend = getBackend(for: newBackend)

        // Try to save to new backend
        do {
            try activeBackend.saveAPIKey(apiKey)
        } catch {
            // If save fails, the key remains in the current backend.
            // We might want to ensure the new backend is clean, but saveAPIKey should handle that.
            throw StorageError.migrationFailed(newBackend)
        }

        // Delete from old backend
        try currentBackend.deleteAPIKey()

        // Update backend preference
        updateBackendPreference(to: newBackend)
    }

    // MARK: - Private Methods

    private func loadBackendPreference() {
        if let rawValue = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.storageBackend),
           let backend = StorageBackend(rawValue: rawValue) {
            self.currentBackend = backend
        } else {
            self.currentBackend = .keychain
        }
    }

    private func updateBackendPreference(to newBackend: StorageBackend) {
        self.currentBackend = newBackend
        UserDefaults.standard.set(newBackend.rawValue, forKey: Constants.UserDefaultsKeys.storageBackend)
    }

    private func getActiveBackend() -> APIKeyStorageProtocol {
        return getBackend(for: currentBackend)
    }

    private func getBackend(for backend: StorageBackend) -> APIKeyStorageProtocol {
        switch backend {
        case .keychain:
            return KeychainService.shared
        case .configFile:
            return ConfigFileService()
        }
    }
}

// MARK: - Storage Error

enum StorageError: LocalizedError {
    case migrationFailed(StorageBackend)

    var errorDescription: String? {
        switch self {
        case .migrationFailed(let backend):
            return "Failed to migrate API key to \(backend.rawValue)"
        }
    }
}
