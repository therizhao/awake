# Mac Menu Bar App UI/UX Guidelines

Use this skill when designing or modifying the UI/UX of Awake or any macOS menu bar utility app. These guidelines are drawn from Apple HIG, established patterns in popular utilities (Amphetamine, Caffeine, KeepingYouAwake, Lungo), and macOS platform conventions.

## Core Principles

### 1. Invisible Until Needed
- Menu bar apps should be **ambient** — present but not demanding attention.
- The icon is the primary interface. It must communicate state at a glance.
- Reserve the dropdown menu for configuration and detail; the icon itself conveys status.

### 2. One-Click for the Common Action
- The most frequent action should be the easiest to perform.
- Popular pattern: **left-click opens menu**, selecting a duration activates immediately.
- Alternative: click icon to toggle (Caffeine-style) — simpler but less discoverable for options.
- Awake uses left-click → menu, which is the better pattern when offering duration choices.

### 3. Progressive Disclosure
- Show the most important options first; hide advanced settings behind submenus or preferences.
- Duration presets > custom time picker. Users want quick selection, not precision.

## Menu Bar Icon Guidelines

### State Communication
- Use **SF Symbols** (Apple's system icon set) for consistency with macOS.
- Mark icons as `isTemplate = true` so they adapt to light/dark mode and menu bar tinting.
- Two clearly distinguishable states: **active** vs **inactive**.
  - Active: filled/solid variant (e.g., `bolt.fill`)
  - Inactive: slashed/empty variant (e.g., `bolt.slash.fill`)
- Optional: show remaining time as text next to the icon using `statusItem.button.title`.
  - Keep it short: "1:23" not "1 hour 23 minutes remaining".
  - Use a fixed-width format to prevent icon jumping as digits change.

### Icon Sizing
- Menu bar icons should be 18×18 points (36×36 @2x).
- `NSStatusItem.squareLength` handles this automatically for SF Symbols.

## Menu Structure Patterns

### Recommended Layout for Timer/Toggle Apps
```
┌─────────────────────────────────┐
│ Status Line (disabled)          │  ← Current state + remaining time
├─────────────────────────────────┤
│ ✓ Indefinitely                  │  ← Duration options with
│   30 Minutes                    │     checkmark on active selection
│   1 Hour                        │
│   2 Hours                       │
│   4 Hours                       │
├─────────────────────────────────┤
│   Deactivate                    │  ← Only shown when active
├─────────────────────────────────┤
│   Quit App                  ⌘Q  │
└─────────────────────────────────┘
```

### Duration Presets (Industry Standard)
Based on analysis of Amphetamine, Caffeine, KeepingYouAwake, and Lungo:
- **Indefinitely** — always include, always first or last
- **30 Minutes** — shortest useful duration
- **1 Hour** — most commonly selected
- **2 Hours** — popular for meetings/focus blocks
- **4 Hours** — half-day coverage

Why these specifically:
- 5/10/15 minute options are rarely used and add clutter.
- Custom duration pickers are overkill for a menu bar utility.
- These 5 options cover 95%+ of use cases.
- Odd numbers (3hr, 5hr) feel arbitrary; round numbers feel intentional.

### Selection Indication
- Use `NSMenuItem.state = .on` (checkmark) on the active duration.
- Only one duration can be active at a time (radio-button semantics).
- Selecting a new duration while one is active should **switch** to the new duration.
- When inactive, no items should have checkmarks.

### Status Line
- First item in the menu, always disabled (`isEnabled = false`).
- When inactive: "Sleep Allowed"
- When active indefinitely: "Sleep Prevented"
- When active with timer: "Sleep Prevented — 1:23 remaining"
- Use an em dash (—), not a hyphen, for visual polish.

## Timer Display Patterns

### In-Menu Countdown
- Update the status line periodically (every 60 seconds is sufficient for hour-scale timers; every second only for the final minute).
- Format: "H:MM" for durations ≥ 1 hour, "MM min" for shorter.
- When timer expires, disable sleep prevention and update all UI state.

### Menu Bar Title (Optional)
- Some apps show remaining time next to the icon: `⚡ 1:23`
- Pros: visible without opening the menu.
- Cons: uses menu bar real estate, can feel noisy.
- Good middle ground: show countdown in menu bar only during the final 5 minutes.

## Interaction Conventions

### Keyboard Shortcuts
- Assign single-letter key equivalents to menu items for power users.
- Don't conflict with system shortcuts (⌘Q for quit is standard).
- Duration items: no shortcut needed (mouse selection is fine for infrequent choices).

### Menu Item Behavior
- Clicking a duration item when **inactive**: activates with that duration.
- Clicking a duration item when **active with same duration**: no-op (already selected).
- Clicking a duration item when **active with different duration**: switches to new duration, resets timer.
- "Deactivate" item: only visible when active, disables everything.

### Quit Behavior
- Always disable sleep prevention before quitting.
- Don't prompt for confirmation — menu bar apps should quit instantly.

## AppKit Implementation Notes

### NSMenu Updates
- Menus are built once and mutated in place — don't rebuild on every open.
- Use `NSMenuDelegate.menuWillOpen(_:)` to refresh dynamic content (like countdown) just before display.
- For periodic updates to menu bar title text, use a `Timer` (not `DispatchSourceTimer`).

### Timer Implementation
- Use `Timer.scheduledTimer` on the main run loop for UI countdown updates.
- Store the target `Date` (fire date), not a decrementing counter — resilient to system sleep/wake.
- When the timer fires, call the same disable path as manual deactivation.
- Invalidate the timer on deactivation or app quit.

### State Transitions
```
INACTIVE → (user selects duration) → ACTIVE (timed or indefinite)
ACTIVE   → (user selects Deactivate) → INACTIVE
ACTIVE   → (timer expires) → INACTIVE
ACTIVE   → (user selects different duration) → ACTIVE (reset timer)
ACTIVE   → (app quits) → cleanup → exit
```

## Accessibility

- Set `accessibilityDescription` on the status item button.
- Menu items get VoiceOver support automatically from NSMenu.
- Avoid conveying state through color alone — use text labels and checkmarks.

## Anti-Patterns to Avoid

- **Confirmation dialogs** for simple toggle actions — kills the quick-utility feel.
- **Preferences windows** for < 5 settings — put them in the menu.
- **Custom drawn menus** — native NSMenu looks and feels right; custom menus feel foreign.
- **Dock icon** — menu bar apps should set `LSUIElement = true` and have no dock presence.
- **Too many duration options** — 5-7 max. Don't offer every possible interval.
- **Imprecise timer display** — "about 2 hours" is worse than "1:58".
