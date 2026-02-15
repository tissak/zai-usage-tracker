import Foundation

// MARK: - API Key Storage Protocol

protocol APIKeyStorageProtocol {
    /// Save an API key to storage
    func saveAPIKey(_ apiKey: String) throws

    /// Retrieve an API key from storage
    func getAPIKey() -> String?

    /// Delete the stored API key
    func deleteAPIKey() throws
}

// MARK: - Storage Backend

enum StorageBackend: String, CaseIterable, Codable {
    case keychain = "keychain"
    case configFile = "configFile"

    static let `default` = StorageBackend.keychain

    var localizedName: String {
        switch self {
        case .keychain:
            return "Keychain"
        case .configFile:
            return "Config File"
        }
    }
}
