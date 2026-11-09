---
type: "Reference"
title: "Build, test and release"
openwiki_generated: true
verified:
  - by: openwiki/0.7.3
    at: 2026-11-09T00:13:56.093Z
sources:
  - id: openwiki-source-b6b49801c13abd2765d578db
    resource: repo://.fvmrc
  - id: openwiki-source-4d1d392666be6dfdd7a91a2e
    resource: repo://.github/workflows/release.yml
  - id: openwiki-source-c2285fe9fbba68070682bc2f
    resource: repo://android/app/build.gradle
  - id: openwiki-source-0b2af1e64e7db22d7729827f
    resource: repo://lib/providers/update_service.dart
  - id: openwiki-source-429b743e157b356f0cca4982
    resource: repo://pubspec.yaml
generated: { by: "claude-code", at: "2026-11-09T00:13:56.093Z" }
---

# Build, test and release

## Toolchain

The Dart package is still named `flauncher` and the version in `pubspec.yaml` is `1.2.1+4128`. Flutter is pinned to `3.41.9` in `pubspec.yaml` and `.fvmrc`. Android builds use JDK 17.

## Flavors and app id

`android/app/build.gradle` declares one flavor dimension, `store`, with two flavors: `play` and `github`. The application id is `com.sirterrific.foyer` for both, and debug builds add the suffix `.debug`.

Build steps:

```bash
flutter pub get
flutter gen-l10n
flutter build apk --flavor github
```

The generated localization files are not committed, so `flutter gen-l10n` must run first; see [Settings UI and localization](settings-ui.md).

## Tests

Tests are in `test/`: `database_test.dart`, `database_migration_test.dart` (with `generated_migrations/`), `flauncher_channel_test.dart`, `flauncher_test.dart`, `localization_test.dart`, plus `providers/` and `widgets/` suites. Mocks are generated into `test/mocks.mocks.dart`. Parental control has its own provider test; see [Parental control](parental-control.md).

## In-app updater

`lib/providers/update_service.dart` checks the GitHub releases API of the fork (`SirTerrific/Foyer`), picks an APK asset suited to the device, and downloads and installs it through the native `installApk` call.

## CI

`.github/workflows/release.yml` is a `Release` workflow. It builds on `ubuntu-latest` with Temurin JDK 17 and the pinned Flutter version, sets up signing, and can publish a GitHub Release by version tag or deploy and promote the Play Store build. `lint-pr-title.yml` checks pull request titles.
