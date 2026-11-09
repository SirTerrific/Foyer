---
type: "Reference"
title: "Quickstart"
openwiki_generated: true
verified:
  - by: openwiki/0.7.3
    at: 2026-11-09T00:13:56.093Z
sources:
  - id: openwiki-source-d1d82248fd190cf516d65121
    resource: repo://lib/main.dart
  - id: openwiki-source-429b743e157b356f0cca4982
    resource: repo://pubspec.yaml
  - id: openwiki-source-23775c3de52f3ab95a13cb8b
    resource: repo://README.md
generated: { by: "claude-code", at: "2026-11-09T00:13:56.093Z" }
---

# Quickstart

Foyer is an open-source Android TV launcher built with Flutter. It is a fork of Arc Launcher (itself based on LTvLauncher and FLauncher) that adds a parental control: chosen apps are locked behind a code entered with the remote's D-pad. The app id is still `com.omeda.arc`.

## Repository layout

- `lib/` - Dart app: `main.dart`, `flauncher.dart` (home screen), `providers/` (services), `widgets/`, `models/`, `database.dart`, `l10n/`.
- `android/` - Android project and the Java native side (`MainActivity`, network and screensaver handlers).
- `test/` - unit and widget tests.
- `tool/gen_brand.dart` - generates the launcher icons and banner.
- `drift_schemas/` - database schema snapshots for migration tests.

## Build and run

```bash
flutter pub get
flutter gen-l10n
flutter run --flavor github
```

Use Flutter `3.41.9` and JDK 17. Run `flutter test` for the tests. Details: [Build, test and release](build-and-release.md).

## Where to read next

- [App architecture and state](architecture.md) - providers, home screen, D-pad focus.
- [Parental control](parental-control.md) - the code, grace period, lockout and gating rules.
- [Data layer](data-layer.md) - Drift tables and settings storage.
- [Android native bridge](android-native-bridge.md) - method and event channels, Watch Next.
- [Settings UI and localization](settings-ui.md) - settings pages, translations, branding.
