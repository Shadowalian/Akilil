# Akilil User App — Unified UI Redesign Plan

## Problem
The app feels **distorted, bland, and not unified** because:
- Only 4/24 screens use the new layout (`FriendTabScaffold` + `FriendPageHeader`)
- 16+ screens still use legacy `AppBar` + plain `Scaffold` on a **transparent** theme → no background
- **Double headers** (AppBar + CandyGradientHeader) on community, wallet, goals, vents
- **Floating dock overlaps** content on journal, booking, messaging (missing 104px clearance)
- **Dark ink dock** clashes with cream wellness palette
- **accentStripe** Row stretch causes layout distortion on short cards
- Mixed padding (16/20/24px), mixed buttons (FilledButton vs FriendGlowButton)

## Design Direction: "Calm Studio"
Blend **23.dev** (refined components, subtle atmosphere, purposeful motion) with **Higgsfield structure** (strong typographic hierarchy, uppercase micro-labels) — adapted for a **warm wellness app**, not dark cinematic.

**Palette (locked):** cream `#FBF7F1`, aqua `#3DB8C5`, soft green `#8FD4A8`, ink text `#1A2E2B`

**Key decision:** Light glass dock (not dark ink). One atmosphere layer at shell level.

## Architecture

### 1. Single shell owns chrome
`MainShell` provides:
- `FriendAtmosphere` once (not per-screen)
- Light frosted floating dock
- Route-aware dock hiding (session room, full-bleed video)

### 2. Two page primitives
| Primitive | Use |
|-----------|-----|
| `FriendTabScaffold` | Bottom-nav tabs (Today, Discover, Sessions, Journal, You) |
| `FriendPageScaffold` | Pushed routes (wallet, community, booking, messages, editor) — back button + header + dock clearance |

Both: zero AppBar, 24px horizontal grid, 104px bottom clearance.

### 3. Fix core components
- Fix `CandyCard` accentStripe (IntrinsicHeight / fixed stripe, no stretch distortion)
- Replace dark `FriendFloatingDock` with light cream-glass dock
- Remove dead `CandyGradientHeader.hue` param
- Add `FriendListTile` for consistent rows (replaces ListTile)

### 4. Migrate ALL screens (24 files)

**Phase A — Core + shell**
- `design_tokens.dart`, `app_theme.dart`, `candy_widgets.dart`
- `main_shell.dart`, `router.dart` (immersive route flag)

**Phase B — Tab screens (5)**
- today, discovery, appointments, profile, **journal_list** (critical — dock tab #4)

**Phase C — Pushed routes (11)**
- journal editor, mood log, mood analytics
- conversations, conversation
- community, community feed, vents
- wallet, goals, booking

**Phase D — Special (4)**
- professional_detail (FriendPageScaffold + hero)
- session_room (hide dock, full bleed)
- login, register, 2fa (auth outside shell, matching Calm Studio)

## Verification
1. `flutter analyze` on user_app
2. `flutter test` in core + user_app
3. Chrome: walk every tab + push wallet, community, book flow, messages
4. Confirm no dock overlap, no double headers, consistent background on all routes
