# Z.ai Usage Tracker

A macOS menu bar application for tracking Z.ai API usage, including quota limits, model usage, and tool usage.

## Features

- **Menu Bar Integration** - View usage at a glance from the macOS menu bar
- **Quota Tracking** - Monitor token and MCP quota limits
- **Model Usage** - Track total tokens and API calls over 24 hours
- **Tool Usage** - Monitor network searches, web reads, and ZRead calls
- **Auto Refresh** - Configurable automatic refresh interval (1-30 minutes)
- **Notifications** - Alert when usage exceeds a threshold
- **Secure Storage** - API key stored securely in macOS Keychain

## Requirements

- macOS 14.0+ (Sonoma)
- Xcode 15.0+
- Swift 5.9+

## Getting Started

### Build

```bash
cd zai-usage-tracker
xcodebuild -project ZaiUsageTracker.xcodeproj -scheme ZaiUsageTracker -configuration Debug build
```

Or open in Xcode:

```bash
open zai-usage-tracker/ZaiUsageTracker.xcodeproj
```

### Running the App

1. Build the project using the commands above
2. Open the built app from `~/Library/Developer/Xcode/DerivedData/ZaiUsageTracker-*/Build/Products/Debug/ZaiUsageTracker.app`
3. Or run directly from Xcode (Cmd+R)

### First-Time Setup

1. Click the menu bar icon (key icon)
2. Click "Open Settings" or the gear icon
3. Enter your Z.ai API key
4. Select your platform (Global or China)
5. Click Save

## Usage

### Menu Bar Icon

The menu bar displays your current token usage percentage:
- ✅ Green checkmark - Normal usage
- ⚠️ Yellow triangle - Warning (>75%)
- ⚠️ Yellow triangle - High (>90%)
- ❌ Red octagon - Critical (>95%)

### Popover View

Click the menu bar icon to see:
- Current quota limits (tokens, MCP)
- Model usage (24-hour tokens and calls)
- Tool usage (network searches, web reads, ZRead calls)
- Last updated timestamp
- Manual refresh button

### Settings

Configure:
- **API Key** - Your Z.ai API key (stored in Keychain)
- **Platform** - Global or China
- **Auto Refresh** - How often to fetch new data
- **Notifications** - Alerts when usage exceeds threshold

## Project Structure

```
zai-usage-tracker/ZaiUsageTracker/
├── ZaiUsageTrackerApp.swift    # App entry point
├── Models/                      # Data models
│   ├── UsageData.swift
│   ├── QuotaLimit.swift
│   ├── ModelUsage.swift
│   └── ToolUsage.swift
├── Services/                    # Business logic
│   ├── ZaiAPIClient.swift       # API client
│   ├── UsageService.swift       # Usage data service
│   └── KeychainService.swift    # Secure storage
├── ViewModels/                  # State management
│   └── UsageViewModel.swift
├── Views/                       # SwiftUI views
│   ├── PopoverView.swift
│   ├── SettingsView.swift
│   └── UsageRowView.swift
└── Utilities/                  # Helpers
    ├── Constants.swift
    └── DateHelper.swift
```

## Architecture

- **MVVM** - Model-View-ViewModel pattern
- **SwiftUI** - UI framework
- **Swift Concurrency** - async/await for async operations
- **Actor** - Thread-safe API client singleton

## License

MIT
