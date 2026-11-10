---
type: "Reference"
title: "App architecture and state"
openwiki_generated: true
sources:
  - id: openwiki-source-bdf660d029923d2d5c2cfb25
    resource: repo://lib/actions.dart
  - id: openwiki-source-f8bb6375c37036a0396684c2
    resource: repo://lib/custom_traversal_policy.dart
  - id: openwiki-source-d1d82248fd190cf516d65121
    resource: repo://lib/main.dart
  - id: openwiki-source-9a52d8ee972137c97c51aa8e
    resource: repo://lib/providers/bing_wallpaper.dart
generated: { by: "claude-code", at: "2026-11-10T16:49:31.024Z" }
verified:
  - by: openwiki/0.7.3
    at: 2026-11-10T16:49:31.024Z
---

# App architecture and state

Foyer is a single Flutter app. State lives in `ChangeNotifier` services exposed with the `provider` package, and widgets read them with `Consumer`, `Selector` and `context.read`.

## Startup

`lib/main.dart` runs `main()`, which opens `SharedPreferences`, creates the Drift `FLauncherDatabase` and the `FLauncherChannel`, then calls `runApp` with a `MultiProvider`. The providers are:

- `SettingsService` (backed by `SharedPreferences`)
- `ParentalControlService` (see [Parental control](parental-control.md))
- `ParentalGuard` (bridge to the native accessibility guard, in `lib/providers/parental_guard.dart`)
- `AppsService` (uses the channel and the database)
- `LauncherState`
- `NetworkService`
- `WallpaperService` (built from `SettingsService`; it also runs the Bing image-of-the-day wallpaper through `BingWallpaper`, whose HTTP requests time out after 30 seconds so a hung request cannot freeze it)
- `BrightnessService`
- `WatchNextService` (channel plus `SettingsService`)

`FLauncherApp` in `lib/flauncher_app.dart` builds the `MaterialApp` and rebuilds the theme from the accent color held in `SettingsService`.

## Home screen

`lib/flauncher.dart` holds the `FLauncher` widget, the main screen. It stacks the wallpaper and gradient layers with the app bar and the category rows, using `Consumer3` and `Selector` so only the affected parts rebuild. It also bakes the hero backdrop textures and a cinematic scrim for the Watch Next carousel.

## Focus and remote navigation

The app is driven by a TV remote. `lib/actions.dart` defines `SoundFeedbackDirectionalFocusAction`, `BackAction` and the `BackIntent` and `MoveFocusToSettingsIntent` intents. `lib/custom_traversal_policy.dart` provides `RowByRowTraversalPolicy`, a D-pad traversal policy that moves focus row by row using `NodeSearcher` and `CandidateNode`.

## Native side and persistence

Calls to Android go through `FLauncherChannel`; see [Android native bridge](android-native-bridge.md). Apps and categories are stored by Drift; see [Data layer](data-layer.md).
