# Dashpad

**Capture ideas. Act on them.**

A minimalist iOS app for capturing ideas and thoughts the moment they strike. Smart categories, zero clutter, no stress.

![iOS 26+](https://img.shields.io/badge/iOS-26%2B-blue)
![Swift](https://img.shields.io/badge/Swift-6-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-green)
![iCloud](https://img.shields.io/badge/iCloud-Sync-lightblue)

---

## Philosophy

Most capture apps try to do too much. Dashpad does less, better:

- **Inbox first** — Untagged ideas land on the main screen, ready to act on
- **Categories emerge naturally** — Tag suggestions appear as you type; one tap files the idea away
- **No anxiety** — No overdue counts screaming at you, no guilt
- **Delightful** — Animations that make capturing feel good

---

## Features

### Smart Tag Suggestions
Type "tomatoes onions" and a Grocery suggestion appears above the keyboard. Tap it — the item is tagged and filed in one shot, keyboard gone. Ideas you don't tag stay on the main screen as your inbox.

### Category Groups
Tagged items live in their category, completely off the main screen. Tap a category emoji pill to open that group as a sheet. The main screen stays clean.

### Natural Language Dates
Type "dentist tomorrow 3pm" or "flight friday 6am" — Dashpad parses it automatically. No date pickers, no extra taps.

### The Backburner 🔥
Ideas sitting for 4+ weeks quietly move to the Backburner — out of sight, out of mind. When you're ready, revive them or let them go guilt-free.

### iCloud Sync
Everything syncs automatically via iCloud Key-Value Storage. Add an idea on your phone, see it on your iPad.

### Sorting Options
- **Newest first** — Fresh ideas at the top
- **Due date** — What's urgent rises up
- **Alphabetical** — When you need order

### Flame Splash
A quick, over-the-top flame animation opens the app. Big to small, wobble, glow — done in under 2 seconds.

---

## Design

Deep navy-black palette with electric sky-blue accents. Minimalist, premium, and fast:

- Dark backgrounds (`#070A10`) with sky-blue accent (`#0EA5E9`)
- SF Pro Black for the wordmark, rounded typography throughout
- Ambient glow orbs in the background
- Spring animations and haptic feedback throughout
- Emoji-first category pills — no label clutter

---

## Tech Stack

- **SwiftUI** — Declarative UI with `@Observable`
- **NSUbiquitousKeyValueStore** — iCloud sync
- **iOS 26+** — Modern APIs, MainActor isolation
- **Swift 6** — Strict concurrency

---

## Project Structure

```
Dashpad/
├── DashpadApp.swift      # App entry point + splash gate
├── ContentView.swift     # Main screen, input bar, category pills
├── IdeaCard.swift        # Card component with archive animation
├── IdeaGroup.swift       # Category group model + GroupView sheet
├── TagViews.swift        # Tag pills, suggestion chips
├── TagPredictor.swift    # Smart tag suggestions + keyword mappings
├── EditIdeaView.swift    # Edit sheet
├── BackburnerView.swift  # 4-week backburner sheet
├── ArchivedView.swift    # Archive history
├── DashItem.swift        # Data model
├── DashStore.swift       # State management + iCloud sync
├── DateParser.swift      # Natural language date parsing
├── DesignSystem.swift    # Colors, typography, spacing tokens
├── SplashView.swift      # Flame launch animation
└── Assets.xcassets/      # App icons & colors
```

---

## Getting Started

1. Clone the repo
2. Open `Dashpad.xcodeproj` in Xcode
3. Add your Apple ID in Signing & Capabilities
4. Ensure iCloud → Key-Value Storage is enabled in capabilities
5. Build and run on simulator or device (iOS 26+)

---

## Roadmap

- [ ] Quick Capture widget
- [ ] Daily digest notification
- [ ] Voice input
- [ ] Siri / Shortcuts integration

---

## License

MIT

---

**Dashpad — Capture it. Then forget about it.**
