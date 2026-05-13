# Awake

A lightweight macOS menu bar app that prevents your Mac from sleeping — including when the lid is closed.

## Features

- Toggle sleep prevention from the menu bar
- Prevents system sleep even with lid closed (`pmset disablesleep`)
- Prevents display sleep when lid is open (IOKit assertion)
- Bolt icon shows state at a glance: **bolt** = awake, **bolt with slash** = sleep allowed
- No password prompts per toggle (one-time sudoers setup)

## Setup

Requires macOS 13+ and Xcode Command Line Tools.

### 1. One-time sudoers setup

This allows the app to run `pmset disablesleep` without a password prompt:

```bash
make setup
```

You'll be prompted for your password once. After this, toggles are instant.

> **Note:** On machines with corporate sudoers configs (e.g., files in `/etc/sudoers.d/` that define `(ALL) ALL`), the file must sort last alphabetically. The setup target creates `zzz-awake` for this reason.

### 2. Build

```bash
make
```

### 3. Run

```bash
make run
```

The app appears in your menu bar as a bolt icon. Click it to toggle sleep prevention.

## How it works

Two layers of sleep prevention:

| Layer | What it does | API |
|-------|-------------|-----|
| System sleep | Prevents sleep even with lid closed | `sudo pmset disablesleep 1` |
| Display sleep | Keeps display on while lid is open | `IOPMAssertionCreateWithName` |

Both are released when you toggle off or quit the app.

## Verify

Check that sleep prevention is active:

```bash
pmset -g | grep SleepDisabled     # should show 1
pmset -g assertions | grep Awake  # should show NoDisplaySleepAssertion
```
