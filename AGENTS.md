# AGENTS.md - Z.ai Usage Tracker

A macOS menu bar application for tracking Z.ai API usage, built with SwiftUI.

## Project Overview

- **Language**: Swift 5.9+
- **Platform**: macOS 14.0+ (Sonoma)
- **Framework**: SwiftUI + AppKit
- **Architecture**: MVVM (Model-View-ViewModel)
- **Build System**: Xcode 15.0+
- **Concurrency**: Swift Concurrency (async/await, actors)

## Build Commands

```bash
# Build the project
xcodebuild -project zai-usage-tracker/ZaiUsageTracker.xcodeproj -scheme ZaiUsageTracker build

# Build for Debug configuration
xcodebuild -project zai-usage-tracker/ZaiUsageTracker.xcodeproj -scheme ZaiUsageTracker -configuration Debug build

# Build for Release configuration  
xcodebuild -project zai-usage-tracker/ZaiUsageTracker.xcodeproj -scheme ZaiUsageTracker -configuration Release build

# Clean build folder
xcodebuild -project zai-usage-tracker/ZaiUsageTracker.xcodeproj clean
```

> **Note**: This project has no test infrastructure configured. Tests should be added using XCTest framework.

## Project Structure

```
zai-usage-tracker/
├── ZaiUsageTracker.xcodeproj/    # Xcode project
└── ZaiUsageTracker/              # Main app target
    ├── ZaiUsageTrackerApp.swift  # App entry point (@main)
    ├── Info.plist                # Bundle configuration
    ├── Models/                   # Data models (Codable structs, enums)
    ├── Services/                 # Business logic & API clients
    ├── ViewModels/               # Observable state management
    ├── Views/                    # SwiftUI views
    ├── Utilities/                # Helpers & constants
    └── Resources/                # Assets.xcassets
```

## Code Style Guidelines

### Imports

- Group imports by category, sorted alphabetically
- Order: Foundation → SwiftUI → AppKit → Other frameworks

```swift
import Foundation
import Combine
import AppKit
import UserNotifications
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Classes/Structs/Enums | PascalCase | `UsageViewModel`, `QuotaLimitItem` |
| Properties/Variables | camelCase | `refreshInterval`, `apiKey` |
| Private properties | Underscore prefix | `_apiClient`, `_refreshTimer` |
| Constants | PascalCase in struct | `Constants.RefreshInterval.default` |
| Enums | PascalCase cases | `.normal`, `.warning`, `.critical` |
| Error types | Enum with `Error` suffix | `APIError`, `KeychainError` |

### MARK Comments

Use `// MARK: -` comments to organize code into logical sections:

```swift
// MARK: - Published Properties
// MARK: - Private Properties
// MARK: - Computed Properties
// MARK: - Initialization
// MARK: - Public Methods
// MARK: - Private Methods
// MARK: - Body (in Views)
// MARK: - API Response Models
// MARK: - Domain Models
```

### ViewModels

- Annotate with `@MainActor` and make `final`
- Conform to `ObservableObject`
- Use `@Published` for reactive state

```swift
@MainActor
final class UsageViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var state: LoadingState = .idle
    @Published var isLoading: Bool = false
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    
    func refresh() async {
        // Implementation
    }
}
```

### Views (SwiftUI)

- Use `struct` with `View` protocol
- Group view components with `// MARK: -` comments
- Include `#Preview` blocks for each view

```swift
struct PopoverView: View {
    @StateObject private var viewModel = UsageViewModel()
    
    // MARK: - Body
    
    var body: some View {
        // View implementation
    }
    
    // MARK: - Private Views
    
    @ViewBuilder
    private var headerSection: some View {
        // Section implementation
    }
}

#Preview {
    PopoverView()
}
```

### Services

- Use `actor` for shared mutable state (thread-safe singletons)
- Use `static let shared` for singleton pattern

```swift
actor ZaiAPIClient {
    static let shared = ZaiAPIClient()
    
    private let session: URLSession
    
    private init() {
        // Configuration
    }
    
    func fetchData() async throws -> Response {
        // Implementation
    }
}
```

### Error Handling

Define custom error types as enums conforming to `LocalizedError`:

```swift
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        // ...
        }
    }
}
```

### Async/Await Patterns

- Use `async func` for asynchronous operations
- Use `Task` blocks to call async from sync contexts
- Use `async let` for parallel async calls

```swift
// Parallel fetching
func fetchAll() async throws -> (A, B, C) {
    async let a = fetchA()
    async let b = fetchB()
    async let c = fetchC()
    return try await (a, b, c)
}

// Task from sync context
Task {
    await viewModel.refresh()
}
```

### Models

- Separate API response models from domain models
- Use `Codable` for serialization
- Domain models transform API models in `init(from:)`:

```swift
// API Response Model
struct QuotaLimitItem: Codable {
    let type: String
    let percentage: Double
}

// Domain Model
struct QuotaInfo: Identifiable {
    let id = UUID()
    let type: QuotaType
    let percentage: Double
    
    init(from item: QuotaLimitItem) {
        self.type = item.type == "TOKENS_LIMIT" ? .tokens : .time
        self.percentage = item.percentage
    }
}
```

### Constants

Centralize all constants in `Constants.swift`:

```swift
struct Constants {
    struct RefreshInterval {
        static let `default`: TimeInterval = 300
        static let minimum: TimeInterval = 60
    }
    
    struct UserDefaultsKeys {
        static let platform = "platform"
        static let refreshInterval = "refreshInterval"
    }
}
```

### Keychain / Security

- Never log sensitive data (API keys, tokens)
- Use `KeychainService` for secure storage
- Always use HTTPS for API calls

## Common Patterns

### Loading State

```swift
enum LoadingState: Equatable {
    case idle
    case loading
    case loaded(UsageData)
    case error(String)
    
    var isLoading: Bool { self == .loading }
    var data: UsageData? { if case .loaded(let d) = self { return d }; return nil }
    var errorMessage: String? { if case .error(let m) = self { return m }; return nil }
}
```

### UserDefaults Persistence

```swift
// Save
UserDefaults.standard.set(value, forKey: Constants.UserDefaultsKeys.key)

// Load with default
let value = defaults.object(forKey: Constants.UserDefaultsKeys.key) as? Type
    ?? Constants.DefaultValue
```

## Important Files

| File | Purpose |
|------|---------|
| `ZaiUsageTrackerApp.swift` | App entry point, MenuBarExtra setup |
| `UsageViewModel.swift` | Main state management |
| `ZaiAPIClient+Fetch.swift` | HTTP client with async/await |
| `KeychainService.swift` | Secure API key storage |
| `Constants.swift` | All app constants |
| `PopoverView.swift` | Main UI popover |
| `SettingsView.swift` | Settings/preferences UI |
