---
title: Android native bridge
type: "Reference"
openwiki_generated: true
verified:
  - by: openwiki/0.7.3
    at: 2026-11-09T00:13:56.093Z
sources:
  - id: openwiki-source-b849f76e187ecb8ae7a3ed77
    resource: repo://android/app/src/main/AndroidManifest.xml
  - id: openwiki-source-432e7d593efd81249e77ba22
    resource: repo://android/app/src/main/java/com/leanbitlab/ltvL/MainActivity.java
  - id: openwiki-source-ef35519c53f918acfbb31e2d
    resource: repo://lib/flauncher_channel.dart
  - id: openwiki-source-25f644bf7309741045bab2b1
    resource: repo://lib/providers/watch_next_service.dart
generated: { by: "claude-code", at: "2026-11-09T00:13:56.093Z" }
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

## Event channels

Two `EventChannel`s (`APPS_EVENT_CHANNEL` and `NETWORK_EVENT_CHANNEL`) push system changes to Dart. `LauncherAppsEventStreamHandler` reports app installs and removals. `NetworkEventStreamHandler` reports connectivity changes, using `NetworkChangeReceiver` and callbacks built on `ConnectivityManager`; `PhoneStateListenerImpl` and `TelephonyCallbackImpl` track cellular state.

## Screensaver

`ClockScreensaverService` is the Android dream (screensaver) service, bound with the `BIND_DREAM_SERVICE` permission.

## Watch Next

`WatchNextService` (a `ChangeNotifier`) loads `WatchNextItem` models from the TV provider. It needs the `READ_TV_LISTINGS` permission and tracks `hasPermission`, `isLoading` and an `activeHeroIndex` for the top carousel. Items start through native `launchWatchNextItem`. Parental control treats an item with an unknown package as protected; see [Parental control](parental-control.md).

## Manifest

`AndroidManifest.xml` declares the `LEANBACK_LAUNCHER` and `HOME` categories and permissions including `READ_EPG_DATA`, `WRITE_EPG_DATA`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`, `CHANGE_WIFI_STATE`, `REQUEST_DELETE_PACKAGES` and `WRITE_SETTINGS`. The app id remains `com.omeda.arc`.
