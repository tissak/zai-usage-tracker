# Z.ai Usage Tracker - macOS Menu Bar App

## Overview

A native macOS menu bar application for monitoring Z.ai GLM Coding Plan usage limits in real-time.

## Tech Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Minimum macOS Version**: macOS 14.0 (Sonoma)
- **Architecture**: MVVM

## API Reference

### Base URLs
- **Global**: `https://api.z.ai`
- **China**: `https://open.bigmodel.cn`

### Endpoints

| Endpoint | Purpose | Query Params |
|----------|---------|--------------|
| `/api/monitor/usage/quota/limit` | Current quota percentages | None |
| `/api/monitor/usage/model-usage` | Model usage (24h window) | `startTime`, `endTime` |
| `/api/monitor/usage/tool-usage` | MCP tool usage (24h window) | `startTime`, `endTime` |

### Authentication
```
Authorization: {api_key}  // No "Bearer" prefix
Accept-Language: en-US,en
Content-Type: application/json
```

### Response Models

#### Quota Limit Response
```json
{
  "limits": [
    {
      "type": "TOKENS_LIMIT",
      "percentage": 45.5,
      "nextResetTime": 1705555200000
    },
    {
      "type": "TIME_LIMIT",
      "percentage": 12.3,
      "currentValue": 123,
      "total": 1000,
      "usageDetails": [
        { "modelCode": "web_search", "usage": 50 },
        { "modelCode": "web_reader", "usage": 30 }
      ]
    }
  ]
}
```

#### Model Usage Response
```json
{
  "totalUsage": {
    "totalTokensUsage": 12500000,
    "totalModelCallCount": 1234
  }
}
```

#### Tool Usage Response
```json
{
  "totalUsage": {
    "totalNetworkSearchCount": 5678,
    "totalWebReadMcpCount": 2345,
    "totalZreadMcpCount": 890
  }
}
```

## Project Structure

```
zai-usage-tracker/
├── ZaiUsageTracker.xcodeproj
├── ZaiUsageTracker/
│   ├── ZaiUsageTrackerApp.swift      # App entry point
│   ├── Models/
│   │   ├── QuotaLimit.swift          # Quota limit data models
│   │   ├── ModelUsage.swift          # Model usage data models
│   │   ├── ToolUsage.swift           # Tool usage data models
│   │   └── UsageData.swift           # Aggregated usage data
│   ├── Services/
│   │   ├── ZaiAPIClient.swift        # HTTP client for API calls
│   │   ├── UsageService.swift        # Business logic for fetching usage
│   │   └── KeychainService.swift     # Secure API key storage
│   ├── ViewModels/
│   │   └── UsageViewModel.swift      # Observable state management
│   ├── Views/
│   │   ├── MenuBarView.swift         # Menu bar icon & status
│   │   ├── PopoverView.swift         # Dropdown panel content
│   │   ├── QuotaSectionView.swift    # Quota display section
│   │   ├── UsageRowView.swift        # Individual usage row
│   │   └── SettingsView.swift        # Settings/preferences window
│   ├── Utilities/
│   │   ├── DateHelper.swift          # Date formatting utilities
│   │   └── Constants.swift           # App constants
│   ├── Resources/
│   │   └── Assets.xcassets/          # App icons, colors
│   └── Info.plist
└── docs/
    └── outline.md
```

## Features

### 1. Menu Bar Display
- Status icon with color indicator (green/yellow/red)
- Current token usage percentage text
- Click to toggle popover

### 2. Popover Panel
- **Quota Limits Section**
  - Token usage (5-hour cycle) with progress bar
  - Time until token reset
  - MCP usage (monthly) with progress bar
  - MCP breakdown by tool
- **Model Usage Section (24h)**
  - Total tokens used
  - Total API calls
- **Tool Usage Section (24h)**
  - Network searches
  - Web reads
  - ZRead calls
- **Last Updated timestamp**
- **Refresh button**
- **Settings button**

### 3. Settings Window
- API Key input (stored in Keychain)
- Platform selection (Global/China)
- Refresh interval (5/10/15/30 minutes)
- Notification threshold (50/70/80/90%)
- Enable/disable notifications toggle
- Launch at login toggle

### 4. Background Monitoring
- Timer-based polling at configurable interval
- Background URL session for reliability
- Update badge on usage changes

### 5. Notifications
- Local push notification when usage exceeds threshold
- Actionable notification with "View Details" button
- Silent mode option

## Implementation Phases

### Phase 1: Core Structure
- [ ] Create Xcode project with SwiftUI
- [ ] Set up menu bar app template
- [ ] Create data models for API responses
- [ ] Implement Keychain service

### Phase 2: API Integration
- [ ] Build HTTP client with async/await
- [ ] Implement quota limit endpoint
- [ ] Implement model usage endpoint
- [ ] Implement tool usage endpoint
- [ ] Add error handling and retry logic

### Phase 3: UI Implementation
- [ ] Build menu bar status view
- [ ] Create popover container
- [ ] Implement quota section with progress bars
- [ ] Add usage statistics sections
- [ ] Style and polish

### Phase 4: Settings & Persistence
- [ ] Create settings window
- [ ] Implement API key input with validation
- [ ] Add platform toggle
- [ ] Store preferences in UserDefaults
- [ ] Secure API key in Keychain

### Phase 5: Background Features
- [ ] Add timer-based refresh
- [ ] Implement local notifications
- [ ] Add launch-at-login support
- [ ] Handle app lifecycle events

### Phase 6: Polish & Testing
- [ ] Add loading states
- [ ] Error state UI
- [ ] Empty state UI
- [ ] Test on macOS 14+
- [ ] Performance optimization

## Usage Thresholds

| Percentage | Color | Alert Level |
|------------|-------|-------------|
| 0-50% | Green | Normal |
| 50-70% | Yellow | Warning |
| 70-90% | Orange | High |
| 90%+ | Red | Critical |

## Time Calculations

- **Token Reset**: 5-hour rolling window
- **MCP Reset**: Monthly (calendar month)
- **Usage Stats**: 24-hour rolling window (yesterday at current hour → today)

## Security Considerations

- API key stored in macOS Keychain (not UserDefaults)
- No logging of API keys
- HTTPS-only API communication
- Network requests use App Transport Security
