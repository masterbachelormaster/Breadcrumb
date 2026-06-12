# Breadcrumb

A macOS menu bar app for tracking what you're working on across projects, with a built-in Pomodoro timer.

Breadcrumb lives in your menu bar and lets you quickly log status updates — what you just did, what's next, and open questions — so you never lose track of where you left off.

## Features

### Project Management
- Create projects with custom names and SF Symbol icons
- Archive and restore projects
- Link files and URLs to projects with custom labels

### Status Tracking
- Log free-text status updates per project
- Optional structured fields: last action, next step, open questions
- AI-powered field extraction from free text (on-device Apple Intelligence or OpenRouter), with automatic cleanup of filler phrases
- Dictate updates with on-device speech-to-text (optional, German and English)
- Full history of all entries with timestamps

### Pomodoro Timer
- Configurable work sessions (5–60 min), short breaks (1–15 min), and long breaks (5–30 min)
- Automatic long break after a configurable number of sessions
- Start a timer for a specific project or standalone
- Live countdown in the menu bar with phase indicators (🍅 work / ☕ break)
- Collapsible timer banner — keep using the app while a session runs
- Snooze (+5/+10 min), skip breaks, or continue into overtime
- Session-end prompt in its own window or inside the popover — your choice
- Log a status entry at the end of each session
- Optional FocusMate mode: fixed end time with a configurable wrap-up buffer

### Notifications
- Separate alerts for "work done" and "break done"
- Pick any macOS system sound, with preview
- Optional banner notifications, shown even while the app is in front

### Stats & History
- View total completed sessions and focus time per project
- Browse and search past status entries across all projects
- Dedicated windows for history and stats

### Settings
- Four tabs: General, Timer, Notifications, AI
- Switch the whole app between German and English
- Launch at login

## Installation

Download the latest DMG from the [Releases page](https://github.com/masterbachelormaster/Breadcrumb/releases), open it, and drag Breadcrumb into your Applications folder.

Requires macOS 26 (Tahoe) or later.

## Building from Source

Requirements: Xcode 16+ and [xcodegen](https://github.com/yonaskolb/XcodeGen)

```bash
# Generate the Xcode project
xcodegen generate

# Build
xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Release build

# Run tests
xcodebuild test -project Breadcrumb.xcodeproj -scheme Breadcrumb

# Install
cp -R ~/Library/Developer/Xcode/DerivedData/Breadcrumb-*/Build/Products/Release/Breadcrumb.app /Applications/
open /Applications/Breadcrumb.app
```

## How It Works

Breadcrumb runs as a menu bar app (no dock icon). Click the bookmark icon to open the popover where you can manage projects, log status updates, and start Pomodoro sessions. Settings, history, and stats open in their own window when needed.

## Privacy

All data is stored locally using SwiftData — no account, no tracking. AI extraction is optional: it runs on-device via Apple Intelligence, or through OpenRouter if you provide your own API key (stored securely in the macOS Keychain). Dictation uses on-device speech recognition.

## Tech Stack

- Swift 6.0 (strict concurrency)
- SwiftUI with `@Observable` patterns
- SwiftData for persistence, with versioned schema migrations
- xcodegen for project generation
- No external dependencies
