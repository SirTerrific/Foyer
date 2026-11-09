---
type: "Reference"
title: "Data layer"
openwiki_generated: true
verified:
  - by: openwiki/0.7.3
    at: 2026-11-09T00:13:56.093Z
sources:
  - id: openwiki-source-5ec5d55a2e3f289066e4f057
    resource: repo://lib/database.dart
  - id: openwiki-source-81c59be75c6bf5d70ac6eb44
    resource: repo://lib/models/watch_next_item.dart
  - id: openwiki-source-7207b3270799be263d4a2e17
    resource: repo://lib/providers/settings_service.dart
generated: { by: "claude-code", at: "2026-11-09T00:13:56.093Z" }
---

# Data layer

Foyer keeps two kinds of persistent state: a Drift (SQLite) database for apps and categories, and `SharedPreferences` for settings.

## Drift database

`lib/database.dart` declares `FLauncherDatabase` with four tables:

- `Apps`
- `Categories`
- `AppsCategories` (links apps to categories with an order)
- `LauncherSpacers`

The schema version is `10`. The `onUpgrade` strategy applies one migration block per version step (for example `from < 9 && to >= 9`), and the migrations cover merging the "TV Apps" and "Non-TV Apps" categories into a single "All Apps" category and moving favorites out of "All Apps". Generated Drift code is in `lib/database.drift.dart`, and `drift_schemas/` holds schema snapshots used by `test/database_migration_test.dart`.

`AppsService` reads and writes these tables and merges them with the installed-app list from the native channel; see [Android native bridge](android-native-bridge.md).

## Models

- `lib/models/app.dart` and `lib/models/category.dart` wrap the Drift rows.
- `lib/models/watch_next_item.dart` defines `WatchNextItem` with `id`, `title`, `description`, `posterUri`, `backdropUri`, `packageName`, `contentId`, `progressPercent`, `duration`, `lastEngagementDate`, `intentUri`, `watchNextType` and `aspectRatio`. `packageName` is nullable, which parental control relies on.

## Settings

`SettingsService` wraps a `SharedPreferences` instance and notifies listeners on change. `ParentalControlService` also stores its state in `SharedPreferences` and needs no database migration; see [Parental control](parental-control.md).
