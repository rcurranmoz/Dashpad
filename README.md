# Dashpad

**One list. Zero stress.**

A minimalist iOS reminders app that gets out of your way. No folders, no complexity, no guilt — just a single list that helps you remember what matters.

![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-green)

---

## Philosophy

Most reminder apps try to do too much. Dashpad does less, better:

- **One list** — No folders, no projects, no hierarchy
- **Speed first** — Add a reminder in under 2 seconds
- **No anxiety** — No overdue counts screaming at you, no streak guilt
- **Delightful** — Small celebrations when you complete things

---

## Features

### Smart Tags
Type "walk dog" and Dashpad suggests `pets`. Type "call mom" and it suggests `family`. Tags emerge naturally from what you write — no manual organization required.

### Natural Language Dates
Type "dentist tomorrow 3pm" or "buy groceries friday" — Dashpad parses it automatically. No date pickers, no extra taps.

### The Backburner 🔥
Items sitting for 2+ weeks quietly move to the Backburner. Out of sight, out of mind. When you're ready, revive them — or let them go guilt-free.

### Sorting Options
- **Newest first** — Fresh items at the top
- **Due date** — What's urgent rises up
- **Alphabetical** — When you need order

### Completion Celebrations
A subtle particle burst and haptic when you check something off. Small dopamine hits that make progress feel good.

---

## Design

Dashpad uses a dark, premium aesthetic inspired by Linear and Arc:

- Deep blacks (`#09090B`) with subtle purple accents (`#8B5CF6`)
- SF Pro typography for a clean, modern feel
- Ambient glow orbs in the background
- Spring animations throughout

---

## Tech Stack

- **SwiftUI** — Declarative UI
- **SwiftData** — Persistence (or custom store)
- **iOS 17+** — Modern APIs

---

## Project Structure

```
Dashpad/
├── DashpadApp.swift      # App entry point
├── ContentView.swift     # Main UI + components
├── DashItem.swift        # Data model
├── DashStore.swift       # State management
├── TagPredictor.swift    # Smart tag suggestions
├── DateParser.swift      # Natural language dates
├── SplashView.swift      # Launch screen
└── Assets.xcassets/      # App icons & colors
```

---

## Getting Started

1. Clone the repo
2. Open `Dashpad.xcodeproj` in Xcode
3. Build and run on simulator or device (iOS 17+)

---

## Roadmap

- [ ] Quick Capture widget
- [ ] Daily digest notification
- [ ] iCloud sync
- [ ] Voice input

---

## License

MIT

---

**Dashpad — Remember things. Then forget about them.**
