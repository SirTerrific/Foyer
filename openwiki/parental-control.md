---
type: "Reference"
title: "Parental control"
openwiki_generated: true
sources:
  - id: openwiki-source-2766998fb7950c123dd76b63
    resource: repo://lib/providers/parental_control_service.dart
  - id: openwiki-source-f77a2b5fa0d2f6ae7b404df6
    resource: repo://lib/providers/parental_guard.dart
  - id: openwiki-source-06e4a3564b239fd821346d2d
    resource: repo://lib/widgets/parental_gate.dart
generated: { by: "claude-code", at: "2026-11-10T16:49:31.024Z" }
verified:
  - by: openwiki/0.7.3
    at: 2026-11-10T16:49:31.024Z
---

# Parental control

Foyer can lock chosen apps, and optionally the launcher settings, behind a code entered with the remote's D-pad. The logic is in `lib/providers/parental_control_service.dart` (`ParentalControlService`, a `ChangeNotifier` backed by `SharedPreferences`). The UI is in `lib/widgets/parental_gate.dart`, `lib/widgets/parental_code_dialog.dart` and `lib/widgets/settings/parental_control_page.dart`.

## The code

A code is a sequence of symbols: the arrows Up, Down, Left, Right (stored as U, D, L, R) and digits. The minimum length is `minCodeLength` = 4. It is stored as a salted SHA-256 hash (preference keys `parental_control_salt` and `parental_control_hash`) and compared in constant time. The code itself is never stored.

## When the code is asked

There is no grace period: the code is asked at every launch of a protected app and every entry into the launcher settings, with no unlocked state kept on disk.

- `isProtected(packageName)` is true when protection is enabled, the time window is active and the package is in the protected set (`parental_control_packages`).
- `requiresCode(packageName)` is `isProtected`. For an unknown package (`null`, as with a Watch Next item that only carries an intent URI) it asks for the code whenever protection is on, the window is active and any app is protected.
- `settingsRequireCode` is true when protection is enabled, the window is active and settings protection is on. Settings protection defaults to on once a code exists.
- The optional time window (`windowEnabled`, start and end minutes, wrapping over midnight) limits protection to part of the day; the default window is 08:00-20:00.

`ensureAppUnlocked(context, packageName)` and `ensureSettingsUnlocked(context)` in `parental_gate.dart` are the entry points used before launching an app or opening settings. `ensureAppAdminUnlocked` does the same for an app's Info and Uninstall actions (asked when the app is protected or when launcher settings are protected). The app bar's Wi-Fi and network entries use `ensureSettingsUnlocked`. The guard (below) re-asks the code when the user comes back to Foyer.

## Verification and lockout

`verify(code)` returns `ok`, `wrong`, `lockedOut` or `recovered`.

- A correct code clears the failure counters.
- After `maxFailuresBeforeLock` = 5 failures the entry is locked for 30 seconds, doubling with each further failure and capped at 900 seconds (15 minutes). The exponent is capped to avoid integer overflow, and a lockout refuses even the right code.

## Recovery code

`generateRecoveryCode()` makes a one-time code of `recoveryCodeLength` = 12 arrows. It is stored only as a salted hash (`hasRecoveryCode` tells whether one exists) and the dialog shows it once, when the code is created or from Parental control > New recovery code. Entering it in `verify` returns `recovered`: the recovery code is burnt and the caller must let the user choose a new code, with no lockout. `setCode` replaces the old code and removes the recovery hash.

## Guard when leaving and returning

`ParentalGuard` (`lib/providers/parental_guard.dart`) bridges the native `ParentalGuardService` (GitHub flavor, see [Android native bridge](android-native-bridge.md)). When a protected app opens outside Foyer (recents, another app, voice assistant) it asks Dart for the code and then resumes that app. `lib/flauncher.dart` also re-asks when the launcher comes back to the foreground, after standby and after a reboot, because nothing is remembered between uses.

## Tests

`test/providers/parental_control_service_test.dart` covers: nothing gated without a code, no clear-text storage, minimum length, no grace after a correct code, wrong code, lockout and overflow, the recovery code (single use, replaced by a new code), the settings gate default, the time window wrapping midnight, and gating of unknown packages.

See also [Android native bridge](android-native-bridge.md) for Watch Next launching and [Settings UI and localization](settings-ui.md).
