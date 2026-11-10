---
title: Android native bridge
type: "Reference"
openwiki_generated: true
verified:
  - by: openwiki/0.7.3
    at: 2026-11-10T16:49:31.024Z
sources:
  - id: openwiki-source-0e16dfd6d4995b1bd6e1a95b
    resource: repo://android/app/src/github/AndroidManifest.xml
  - id: openwiki-source-b849f76e187ecb8ae7a3ed77
    resource: repo://android/app/src/main/AndroidManifest.xml
  - id: openwiki-source-432e7d593efd81249e77ba22
    resource: repo://android/app/src/main/java/com/leanbitlab/ltvL/MainActivity.java
  - id: openwiki-source-f48cc2aef766bf6d8d5e1c1f
    resource: repo://android/app/src/main/java/com/leanbitlab/ltvL/ParentalGuardService.java
  - id: openwiki-source-ef35519c53f918acfbb31e2d
    resource: repo://lib/flauncher_channel.dart
  - id: openwiki-source-25f644bf7309741045bab2b1
    resource: repo://lib/providers/watch_next_service.dart
generated: { by: "claude-code", at: "2026-11-10T16:49:31.024Z" }
---

# Android native bridge

Foyer is a Flutter app, but launching apps, reading icons and banners, and reacting to system events need Android APIs. The Java side lives in `android/app/src/main/java/com/leanbitlab/ltvL/` and `MainActivity` extends `FlutterActivity`. The Dart side of the bridge is `lib/flauncher_channel.dart`.

## Method channel

`MainActivity` registers a `MethodChannel` named by `METHOD_CHANNEL` (`me.efesser.flauncher/method`) with `setMethodCallHandler`. Many calls are run off the main thread through `runAsync`.

`FLauncherChannel` wraps `invokeMethod` calls such as:

- `getApplications`, `applicationExists`
- `getApplicationBanner`, `getApplicationIcon` (return `Uint8List` bytes)
- `launchApp`, `launchActivityFromAction`
- `openSettings`, `openAppInfo`, `uninstallApp`
- `isDefaultLauncher`, `checkForGetContentAvailability`
- `startAmbientMode`, `openScreensaverSettings`, `requestInstallUnknownAppsPermission`
- `getActiveNetworkInformation`, `getDailyWifiUsage`, `getWeeklyWifiUsage`
- `installApk`
- `syncParentalGuard`, `takeParentalLock`, `resumeLockedApp`, `openAccessibilitySettings` (parental guard, see below)

## Event channels

Two `EventChannel`s (`APPS_EVENT_CHANNEL` and `NETWORK_EVENT_CHANNEL`) push system changes to Dart. `LauncherAppsEventStreamHandler` reports app installs and removals. `NetworkEventStreamHandler` reports connectivity changes, using `NetworkChangeReceiver` and callbacks built on `ConnectivityManager`; `PhoneStateListenerImpl` and `TelephonyCallbackImpl` track cellular state.

## Screensaver

`ClockScreensaverService` is the Android dream (screensaver) service, bound with the `BIND_DREAM_SERVICE` permission.

## Parental guard

`ParentalGuardService` is an Android `AccessibilityService` that exists only in the GitHub flavor (`android/app/src/github/AndroidManifest.xml`, with `parental_guard.xml` and its strings in `res/`). The Play Store flavor does not declare it, because Google Play restricts accessibility services. It watches full-screen window changes. When a protected package comes to the foreground and Foyer has not just unlocked it, it brings `MainActivity` forward with `EXTRA_LOCKED_PACKAGE` (`foyer.parental_locked_package`) so Dart can ask for the code.

Dart pushes the configuration with `syncParentalGuard` (active flag, protected packages, the time window, and whether launcher settings are protected). The native side stores it in SharedPreferences (`foyer_parental_guard`) so it survives a process restart. The calls work as follows:

- `takeParentalLock` returns and clears the package waiting for a code, or null.
- `resumeLockedApp` is called after a correct code. It reopens the app and lets it through (`allow`).
- `openAccessibilitySettings` opens Android's accessibility screen so the user can turn the service on.
- `isAvailable` and `isEnabled` report whether this build declares the service and whether the user switched it on.

A force stop switches the service off. With the `WRITE_SECURE_SETTINGS` permission, granted once over adb, `tryReenable` turns it back on when the app starts. Settings-type packages (Android Settings, the TV settings app) are guarded only when the user chose to protect launcher settings.

The channel `me.efesser.flauncher/screen` (`SCREEN_CHANNEL`) tells Dart when the TV screen turns off, so the code is asked again after standby.

## Watch Next

`WatchNextService` (a `ChangeNotifier`) loads `WatchNextItem` models from the TV provider. It needs the `READ_TV_LISTINGS` permission and tracks `hasPermission`, `isLoading` and an `activeHeroIndex` for the top carousel. Items start through native `launchWatchNextItem`. Parental control treats an item with an unknown package as protected; see [Parental control](parental-control.md).

## Manifest

`AndroidManifest.xml` declares the `LEANBACK_LAUNCHER` and `HOME` categories and permissions including `READ_EPG_DATA`, `WRITE_EPG_DATA`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`, `CHANGE_WIFI_STATE`, `REQUEST_DELETE_PACKAGES` and `WRITE_SETTINGS`. The app id remains `com.sirterrific.foyer`.
