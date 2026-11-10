import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/providers/parental_control_service.dart';
import 'package:flutter/foundation.dart';

/// Bridge to the native accessibility guard, which asks the code when a
/// protected app opens without going through Foyer (recents, another app,
/// voice assistant). GitHub build only; [available] is false elsewhere.
class ParentalGuard extends ChangeNotifier {
  final FLauncherChannel _channel;
  final ParentalControlService _service;

  bool available = false;
  bool enabled = false;

  /// Set by the home screen, which owns the dialog context.
  VoidCallback? onLockRequested;

  ParentalGuard(this._channel, this._service) {
    _service.addListener(_sync);
    _channel.setParentalLockListener(() => onLockRequested?.call());
    _sync();
    refreshStatus();
  }

  Future<void> _sync() async {
    try {
      await _channel.syncParentalGuard(
        active: _service.enabled,
        packages: _service.protectedPackages.toList(),
        // Same rule as settingsRequireCode: also locks Android settings (force-stop, accessibility).
        protectSettings: _service.protectSettings,
        windowEnabled: _service.windowEnabled,
        windowStart: _service.windowStartMinutes,
        windowEnd: _service.windowEndMinutes,
      );
    } catch (_) {
      // Older native side: the guard simply stays off.
    }
  }

  Future<void> refreshStatus() async {
    try {
      final status = await _channel.parentalGuardStatus();
      available = status['available'] == true;
      enabled = status['enabled'] == true;
    } catch (_) {
      available = false;
      enabled = false;
    }
    notifyListeners();
  }

  Future<void> openAccessibilitySettings() => _channel.openAccessibilitySettings();

  Future<String?> takePendingLock() async {
    try {
      return await _channel.takeParentalLock();
    } catch (_) {
      return null;
    }
  }

  bool _asking = false;

  /// Takes the app the guard covered, asks the code with [askCode], and
  /// reopens the app when it is right. A second trigger while the dialog is
  /// open (voice button, remote shortcut) must not stack a second dialog.
  Future<void> handleLock(Future<bool> Function() askCode) async {
    final packageName = await takePendingLock();
    if (packageName == null || _asking) return;
    _asking = true;
    final bool ok;
    try {
      ok = await askCode();
    } finally {
      _asking = false;
    }
    if (ok) await resume(packageName);
  }

  Future<void> resume(String packageName) => _channel.resumeLockedApp(packageName);

  @override
  void dispose() {
    _service.removeListener(_sync);
    super.dispose();
  }
}
