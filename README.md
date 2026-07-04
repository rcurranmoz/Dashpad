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

### On-Device Intelligence 🧠
Dashpad uses Apple's Foundation Models framework — the on-device LLM behind Apple Intelligence — to *understand* what you capture. No server, no API key, no idea ever leaves your phone.

- **Magic filing** — Capture is instant. A sparkle pulses on the card while the model reads it, then the right category and due date pop in a beat later. "salmon, arugula, that pinot bethany likes" files itself into Grocery Run — no keywords required.
- **Live smart chips** — Pause while typing and the model's category pick joins the suggestion chips above the keyboard (keyword matches still appear instantly).
- **Spark ✨** — Open any idea and tap *Spark next steps*: the model turns a raw thought into 2–4 concrete next steps, appended to your notes.
- **Smart Siri capture** — "Add to Dashpad" from Siri or the Action Button gets the same brain: filed and dated before you unlock your phone.
- **Graceful fallback** — On devices without Apple Intelligence, everything falls back to the original keyword + regex engine. The app never blocks on the model.

### Smart Tag Suggestions
Type "tomatoes onions" and a Grocery suggestion appears above the keyboard. Tap it — the item is tagged and filed in one shot, keyboard gone. Ideas you don't tag stay on the main screen as your inbox.

### Category Groups
Tagged items live in their category, completely off the main screen. Tap a category emoji pill to open that group as a sheet. The main screen stays clean.

### Natural Language Dates
Type "dentist tomorrow 3pm", "flight friday 6am", "renew registration before june 12", or "car inspection next month" — Dashpad parses it automatically. Three layers deep: fast regexes, the system data detector, and the on-device model for anything else. No date pickers, no extra taps.

### The Backburner 🔥
Ideas sitting for 4+ weeks quietly move to the Backburner — out of sight, out of mind. When you're ready, revive them or let them go guilt-free.

### iCloud Sync
Everything syncs automatically via iCloud Key-Value Storage. Add an idea on your phone, see it on your iPad.

### Sorting Options
- **Newest first** — Fresh ideas at the top
- **Due date** — What's urgent rises up
- **Alphabetical** — When you need order

### The Boot
A two-second story: a lightbulb flickers to life in the dark — the idea strikes — then a hand-drawn ember underline scribbles itself beneath the wordmark: jotted down before it escapes. Cards cascade onto the pad as the splash hands off.

---

## Design

**Embers in the dark.** Warm ink-black paper, ideas typeset in serif, a single ember accent. A midnight notebook, not a dashboard:

- Warm near-black ground (`#0D0A08`) lit faintly from below, ember accent (`#FF9F45`)
- Serif (New York) for everything you write — chrome stays sans; your thoughts read like set type
- Dusty ink category colors and margin-note tags instead of neon badges
- Liquid Glass chrome (header, capture bar, chips) on iOS 26 materials
- Spring choreography and haptics throughout; sparks fly when you finish something

---

## Tech Stack

- **SwiftUI** — Declarative UI with `@Observable`, Liquid Glass materials
- **FoundationModels** — On-device LLM with `@Generable` structured output; private by construction
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
├── DashStore.swift       # State management + iCloud sync + enrichment
├── Intelligence.swift    # On-device Foundation Models engine
├── DateParser.swift      # Natural language date parsing (regex + data detector)
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

- [ ] Quick Capture widget + Control Center control
- [ ] Daily digest notification
- [ ] Voice input
- [x] Siri / Shortcuts integration (with on-device smart filing)
- [ ] Semantic search — find "fish" when you typed "salmon"
- [ ] "Sound familiar?" — on-device near-duplicate detection at capture time

---

## License

MIT

---

**Dashpad — Capture it. Then forget about it.**
