import 'package:flauncher/providers/parental_control_service.dart';
import 'package:flauncher/widgets/parental_code_dialog.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Resolves true when [packageName] may be launched: not protected, or the
/// right code was just entered.
Future<bool> ensureAppUnlocked(BuildContext context, String? packageName) async {
  final service = context.read<ParentalControlService>();
  if (!service.requiresCode(packageName)) return true;
  return showParentalCodeDialog(context, mode: ParentalCodeDialogMode.verify);
}

/// Same, for entering launcher settings when "protect settings" is on.
Future<bool> ensureSettingsUnlocked(BuildContext context) async {
  final service = context.read<ParentalControlService>();
  if (!service.settingsRequireCode) return true;
  return showParentalCodeDialog(context, mode: ParentalCodeDialogMode.verify);
}

/// App info and uninstall open Android's own screens (force stop, clear data):
/// asked when the app is protected OR when the launcher settings are.
Future<bool> ensureAppAdminUnlocked(BuildContext context, String? packageName) async {
  final service = context.read<ParentalControlService>();
  if (!service.requiresCode(packageName) && !service.settingsRequireCode) return true;
  return showParentalCodeDialog(context, mode: ParentalCodeDialogMode.verify);
}
