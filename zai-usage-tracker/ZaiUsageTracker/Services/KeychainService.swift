import Foundation
import Security

enum KeychainError: LocalizedError {
    case encodingError
    case decodingError
    case unexpectedStatus(OSStatus)
    case itemNotFound

    var errorDescription: String? {
        switch self {
        case .encodingError: return "Failed to encode data for keychain"
        case .decodingError: return "Failed to decode data from keychain"
        case .unexpectedStatus(let status): return "Keychain error: \(status)"
        case .itemNotFound: return "Item not found in keychain"
        }
    }
}

// MARK: - Keychain Service

final class KeychainService {
    static let shared = KeychainService()

    private let service = "com.zaiusagetracker"
    private let apiKeyAccount = "apiKey"

    private init() {}

    // MARK: - API Key

    func saveAPIKey(_ apiKey: String) throws {
        try save(key: apiKeyAccount, value: apiKey)
    }

    func getAPIKey() -> String? {
        return try? get(key: apiKeyAccount)
    }

    func deleteAPIKey() throws {
        try delete(key: apiKeyAccount)
    }

    // MARK: - Generic Operations

    private func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingError
        }

        // Try to update first, if not found then add
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)

        if status == errSecSuccess {
            // Item exists, update it
            let updateQuery: [String: Any] = [
                kSecValueData as String: data
            ]
            let updateStatus = SecItemUpdate(query as CFDictionary, updateQuery as CFDictionary)
            if updateStatus != errSecSuccess {
                throw KeychainError.unexpectedStatus(updateStatus)
            }
        } else if status == errSecItemNotFound {
            // Item doesn't exist, add it
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key,
                kSecValueData as String: data
            ]
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            if addStatus != errSecSuccess {
                throw KeychainError.unexpectedStatus(addStatus)
            }
        } else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    private func get(key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }

        guard let data = result as? Data, let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.decodingError
        }

        return value
    }

    private func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}

// MARK: - API Key Storage Protocol

extension KeychainService: APIKeyStorageProtocol {}
