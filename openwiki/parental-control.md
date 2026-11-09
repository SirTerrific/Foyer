---
type: "Reference"
title: "Parental control"
openwiki_generated: true
verified:
  - by: openwiki/0.7.3
    at: 2026-11-09T00:13:56.093Z
sources:
  - id: openwiki-source-2766998fb7950c123dd76b63
    resource: repo://lib/providers/parental_control_service.dart
  - id: openwiki-source-06e4a3564b239fd821346d2d
    resource: repo://lib/widgets/parental_gate.dart
generated: { by: "claude-code", at: "2026-11-09T00:13:56.093Z" }
---

# Parental control

Foyer can lock chosen apps, and optionally the launcher settings, behind a code entered with the remote's D-pad. The logic is in `lib/providers/parental_control_service.dart` (`ParentalControlService`, a `ChangeNotifier` backed by `SharedPreferences`). The UI is in `lib/widgets/parental_gate.dart`, `lib/widgets/parental_code_dialog.dart` and `lib/widgets/settings/parental_control_page.dart`.

## The code

A code is a sequence of symbols: the arrows Up, Down, Left, Right (stored as U, D, L, R) and digits. The minimum length is `minCodeLength` = 4. It is stored as a salted SHA-256 hash (preference keys `parental_control_salt` and `parental_control_hash`) and compared in constant time. The code itself is never stored.

## When the code is asked

- `isProtected(packageName)` is true when protection is enabled, the time window is active and the package is in the protected set (`parental_control_packages`).
- `requiresCode(packageName)` returns false while the grace period is active. For an unknown package (`null`, as with a Watch Next item that only carries an intent URI) it asks for the code whenever any app is protected.
- `settingsRequireCode` is true when protection is enabled, the window is active, settings protection is on and no grace period is running. Settings protection defaults to on once a code exists.
- The optional time window (`windowEnabled`, start and end minutes, wrapping over midnight) limits protection to part of the day; the default window is 08:00-20:00.

`ensureAppUnlocked(context, packageName)` and `ensureSettingsUnlocked(context)` in `parental_gate.dart` are the entry points used before launching an app or opening settings; they show the code dialog when needed.

## Verification, grace and lockout

`verify(code)` returns `ok`, `wrong` or `lockedOut`.

- A correct code clears the failure counters and opens a grace period of `graceDuration` = 15 minutes.
- After `maxFailuresBeforeLock` = 5 failures the entry is locked for 30 seconds, doubling with each further failure and capped at 900 seconds (15 minutes). The exponent is capped to avoid integer overflow, and a lockout refuses even the right code.
- `relock()` ends the grace period immediately.

## Tests

`test/providers/parental_control_service_test.dart` covers: nothing gated without a code, no clear-text storage, minimum length, grace after a correct code, wrong code, lockout and overflow, relock, the settings gate default, the time window wrapping midnight, and gating of unknown packages.

See also [Android native bridge](android-native-bridge.md) for Watch Next launching and [Settings UI and localization](settings-ui.md).
