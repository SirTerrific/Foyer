import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/parental_control_service.dart';
import 'package:flauncher/providers/parental_guard.dart';
import 'package:flauncher/widgets/parental_code_dialog.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/settings_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Entry tile: asks the current code (if any) before opening the page.
Future<void> openParentalControlPage(BuildContext context) async {
  final service = context.read<ParentalControlService>();
  final navigator = Navigator.of(context);
  if (service.hasCode) {
    final ok = await showParentalCodeDialog(context, mode: ParentalCodeDialogMode.verify);
    if (!ok) return;
    // Codes set before recovery codes existed have none: hand one out now.
    if (!service.hasRecoveryCode && context.mounted) {
      await showParentalCodeDialog(context, mode: ParentalCodeDialogMode.recovery);
    }
  }
  navigator.pushNamed(ParentalControlPage.routeName);
}

String _formatMinutes(int minutes) {
  final h = (minutes ~/ 60).toString().padLeft(2, '0');
  final m = (minutes % 60).toString().padLeft(2, '0');
  return "$h:$m";
}

class ParentalControlPage extends StatelessWidget {
  static const String routeName = "parental_control_panel";

  /// OK on a time tile moves it forward by this many minutes (wraps at 24 h).
  static const int timeStepMinutes = 30;

  const ParentalControlPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<ParentalControlService>();
    final apps = context.watch<AppsService>().applications;
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    final protectedPackages = service.protectedPackages;
    ParentalGuard? guard;
    try {
      guard = context.watch<ParentalGuard>();
    } on ProviderNotFoundException {
      guard = null;
    }

    return Column(
      children: [
        SettingsPageHeader(title: l.parentalControl),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              FocusableSettingsTile(
                autofocus: true,
                leading: const Icon(Icons.pin_outlined),
                title: Text(service.hasCode ? l.parentalChangeCode : l.parentalSetCode, style: textStyle),
                onPressed: () async {
                  final created = await showParentalCodeDialog(context, mode: ParentalCodeDialogMode.create);
                  if (created) await service.setEnabled(true);
                },
              ),
              if (service.hasCode)
                FocusableSettingsTile(
                  leading: const Icon(Icons.key_outlined),
                  title: Text(l.parentalNewRecovery, style: textStyle),
                  trailing: Text(service.hasRecoveryCode ? "" : l.parentalNoRecovery, style: textStyle),
                  onPressed: () => showParentalCodeDialog(context, mode: ParentalCodeDialogMode.recovery),
                ),
              RoundedSwitchListTile(
                value: service.enabled,
                onChanged: (value) {
                  if (service.hasCode) service.setEnabled(value);
                },
                title: Text(l.parentalProtectApps, style: textStyle),
                secondary: const Icon(Icons.lock_outline),
              ),
              RoundedSwitchListTile(
                value: service.protectSettings,
                onChanged: (value) {
                  if (service.hasCode) service.setProtectSettings(value);
                },
                title: Text(l.parentalProtectSettings, style: textStyle),
                secondary: const Icon(Icons.settings_outlined),
              ),
              RoundedSwitchListTile(
                value: service.windowEnabled,
                onChanged: (value) {
                  if (service.hasCode) service.setWindowEnabled(value);
                },
                title: Text(l.parentalTimeWindow, style: textStyle),
                secondary: const Icon(Icons.schedule),
              ),
              if (service.windowEnabled) ...[
                FocusableSettingsTile(
                  leading: const Icon(Icons.hourglass_top),
                  title: Text(l.parentalTimeWindowStart, style: textStyle),
                  trailing: Text(_formatMinutes(service.windowStartMinutes), style: textStyle),
                  onPressed: () => service.setWindowStartMinutes(service.windowStartMinutes + timeStepMinutes),
                ),
                FocusableSettingsTile(
                  leading: const Icon(Icons.hourglass_bottom),
                  title: Text(l.parentalTimeWindowEnd, style: textStyle),
                  trailing: Text(_formatMinutes(service.windowEndMinutes), style: textStyle),
                  onPressed: () => service.setWindowEndMinutes(service.windowEndMinutes + timeStepMinutes),
                ),
              ],
              if (guard != null && guard.available)
                FocusableSettingsTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: Text(l.parentalGuard, style: textStyle),
                  trailing: Text(guard.enabled ? l.parentalGuardOn : l.parentalGuardOff, style: textStyle),
                  onPressed: () => guard?.openAccessibilitySettings(),
                ),
              const SettingsSectionDivider(),
              for (final app in apps)
                RoundedSwitchListTile(
                  value: protectedPackages.contains(app.packageName),
                  onChanged: (value) => service.setPackageProtected(app.packageName, value),
                  title: Text(app.name, style: textStyle),
                  secondary: const Icon(Icons.apps),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
