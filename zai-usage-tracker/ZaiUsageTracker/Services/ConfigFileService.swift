import Foundation

// MARK: - Config File Service

final class ConfigFileService: APIKeyStorageProtocol {

    // MARK: - File Paths

    private let configDirectory: URL
    private let configFile: URL

    // MARK: - Initialization

    init() {
        // Get the config directory
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        self.configDirectory = homeDirectory.appendingPathComponent(".config").appendingPathComponent("zai-usage-tracker")

        // Create the config file path
        self.configFile = configDirectory.appendingPathComponent("config.json")
    }

    // MARK: - APIKeyStorageProtocol

    func saveAPIKey(_ apiKey: String) throws {
        // Ensure directory exists
        try ensureDirectoryExists()

        // Create config file struct
        let config = ConfigFile(apiKey: apiKey)

        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(config)

        // Write to file with proper permissions
        try data.write(to: configFile, options: [.atomic, .completeFileProtection])

        // Set file permissions to 0o600 (user read/write only)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: configFile.path
        )
    }

    func getAPIKey() -> String? {
        guard FileManager.default.fileExists(atPath: configFile.path) else {
            return nil
        }

        guard let data = try? Data(contentsOf: configFile) else {
            return nil
        }

        guard let config = try? JSONDecoder().decode(ConfigFile.self, from: data) else {
            return nil
        }

        return config.apiKey
    }

    func deleteAPIKey() throws {
        guard FileManager.default.fileExists(atPath: configFile.path) else {
            return
        }

        try FileManager.default.removeItem(at: configFile)
    }

    // MARK: - Private Methods

    private func ensureDirectoryExists() throws {
        var isDirectory: ObjCBool = false
        let directoryExists = FileManager.default.fileExists(atPath: configDirectory.path, isDirectory: &isDirectory)

        if !directoryExists || !isDirectory.boolValue {
            try FileManager.default.createDirectory(
                at: configDirectory,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
        }
    }
}

// MARK: - Config File Model

struct ConfigFile: Codable {
    var apiKey: String?
}
