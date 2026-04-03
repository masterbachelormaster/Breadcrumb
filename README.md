# Breadcrumb

A macOS menu bar app for tracking what you're working on across projects, with a built-in Pomodoro timer.

Breadcrumb lives in your menu bar and lets you quickly log status updates — what you just did, what's next, and open questions — so you never lose track of where you left off.

## Features

- **Menu bar popover** — quick access without leaving your current workflow
- **Project management** — organize work by project with custom icons
- **Status entries** — log free-text updates with optional structured fields (last action, next step, open questions)
- **Pomodoro timer** — configurable work/break cycles with notifications
- **History & stats** — review past entries and focus time per project
- **Breakout windows** — settings, history, and stats open in their own window when needed
- **Bilingual UI** — German and English

## Requirements

- macOS 14+
- Xcode 16+
- [xcodegen](https://github.com/yonaskolb/XcodeGen)

## Getting Started

```bash
# Generate the Xcode project
xcodegen generate

# Build
xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Debug build

# Run tests
xcodebuild test -project Breadcrumb.xcodeproj -scheme Breadcrumb
```

## Tech Stack

- Swift 6.0 (strict concurrency)
- SwiftUI with `@Observable` patterns
- SwiftData for persistence
- xcodegen for project generation
- No external dependencies
