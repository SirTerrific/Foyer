---
type: "Reference"
title: "Settings UI and localization"
openwiki_generated: true
verified:
  - by: openwiki/0.7.3
    at: 2026-11-09T00:13:56.093Z
sources:
  - id: openwiki-source-4ead7baa3b3e5396f0a6a07e
    resource: repo://l10n.yaml
  - id: openwiki-source-7207b3270799be263d4a2e17
    resource: repo://lib/providers/settings_service.dart
  - id: openwiki-source-5debb80f8179d323cf091183
    resource: repo://lib/widgets/settings/settings_panel.dart
  - id: openwiki-source-ea20cfe01e671ffa34c636b0
    resource: repo://tool/gen_brand.dart
generated: { by: "claude-code", at: "2026-11-09T00:13:56.093Z" }
---

# Settings UI and localization

## Settings panel

`lib/widgets/settings/settings_panel.dart` defines `SettingsPanel`, a nested `Navigator` shown as a side panel. Its `initialRoute` defaults to `SettingsPanelPage.routeName`, and each page registers a `routeName`: general, interface, wallpaper, status bar, gradient, slideshow sources and others. The parental control page (`parental_control_page.dart`) is one of them; see [Parental control](parental-control.md).

Other pages in `lib/widgets/settings/` cover the accent color, back-button action, brightness, date and time format, focus border thickness, launcher sections, Reddit and Unsplash slideshows, screensaver clock style, updates and the About dialog.

## Accent colors

`SettingsService` stores the accent color as a hex string and falls back to `ACCENT_COLOR_FOYER` (`F59E0B`, amber). `accent_color_page.dart` lists the named presets (Purple, Teal, Blue, Orange, White, Indigo, Lime, Amber, Rose and others).

## Wallpapers

`WallpaperService` (a `ChangeNotifier` built from `SettingsService`) manages the gradient, image, video and slideshow backgrounds. Slideshows come from Reddit or Unsplash providers.

## Localization

Strings live in ARB files in `lib/l10n/`: `app_en.arb` (the template), `app_es.arb`, `app_fr.arb`, `app_tr.arb`, `app_vi.arb` and `app_zh.arb`. `l10n.yaml` sets the output file to `app_localizations.dart`. The generated `app_localizations*.dart` files are produced by `flutter gen-l10n` and must be regenerated after changing an ARB file; `test/localization_test.dart` checks the translations.

## Foyer branding

The app is branded Foyer, with an amber and dark palette (background `0xFF1C1917`, amber `0xFFF59E0B`, terracotta `0xFFEA580C`, cream `0xFFFDF6EC`). `tool/gen_brand.dart` generates the launcher icons, adaptive icon layers and TV banner. It is a `flutter_test` file so it can use `dart:ui` headlessly; run it from the project root with `flutter test tool/gen_brand.dart`.

See [Build, test and release](build-and-release.md) for the build steps.
