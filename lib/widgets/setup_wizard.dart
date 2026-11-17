/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/launcher_state.dart';
import 'package:flauncher/providers/parental_control_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/keep_focus.dart';
import 'package:flauncher/widgets/parental_code_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Shows the first-run setup once. Does nothing on later starts.
Future<void> maybeShowSetupWizard(BuildContext context) async {
  final settings = context.read<SettingsService>();
  if (settings.setupDone) return;
  // A code already exists: this install was set up before the wizard existed,
  // and the wizard must not become a way around the code.
  if (!context.read<ParentalControlService>().hasCode) {
    await showDialog<void>(context: context, barrierDismissible: false, builder: (_) => const SetupWizard());
  }
  await settings.setSetupDone();
}

/// Welcome, default launcher, wallpaper, parental code, done. Every step can be skipped.
class SetupWizard extends StatefulWidget {
  const SetupWizard({super.key});

  @override
  State<SetupWizard> createState() => _SetupWizardState();
}

class _SetupWizardState extends State<SetupWizard> with WidgetsBindingObserver {
  static const _lastStep = 4;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from Android's settings: the default launcher may have changed.
    if (state == AppLifecycleState.resumed) context.read<LauncherState>().refresh(context.read<AppsService>());
  }

  void _next() => _step == _lastStep ? Navigator.of(context).pop() : setState(() => _step++);

  Future<void> _useBing() async {
    await context.read<SettingsService>().setBingWallpaperEnabled(true);
    if (mounted) _next();
  }

  Future<void> _setCode() async {
    final service = context.read<ParentalControlService>();
    if (!await showParentalCodeDialog(context, mode: ParentalCodeDialogMode.create)) return;
    await service.setEnabled(true);
    if (mounted) _next();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final (IconData icon, String title, String text, List<Widget> buttons) = switch (_step) {
      0 => (Icons.home_rounded, l.setupWelcomeTitle, l.setupWelcomeText, [_button(l.setupStart, _next, primary: true)]),
      1 => (
          Icons.tv,
          l.setupDefaultTitle,
          "${l.setupDefaultText}\n\n"
              "${context.watch<LauncherState>().isDefaultLauncher ? l.setupDefaultYes : l.setupDefaultNo}",
          [
            _button(l.setupOpenSettings, context.read<AppsService>().openHomeSettings, primary: true),
            _button(l.setupNext, _next),
          ]
        ),
      2 => (
          Icons.wallpaper,
          l.wallpaper,
          l.setupWallpaperText,
          [_button(l.bingWallpaper, _useBing, primary: true), _button(l.gradient, _next)]
        ),
      3 => (
          Icons.lock_outline,
          l.parentalControl,
          l.setupParentalText,
          [_button(l.parentalSetCode, _setCode, primary: true), _button(l.setupNext, _next)]
        ),
      _ => (Icons.check_circle_outline, l.setupDoneTitle, l.setupDoneText, [_button(l.setupFinish, _next, primary: true)]),
    };

    return PopScope(
      canPop: false,
      // Back goes one step back; the wizard only closes through its buttons.
      onPopInvokedWithResult: (_, __) {
        if (_step > 0) setState(() => _step--);
      },
      child: Dialog.fullscreen(
        backgroundColor: const Color(0xF21C1917),
        child: KeepFocus(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              // Keyed by step so the first button of each step takes the focus.
              child: Column(
                key: ValueKey(_step),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 56, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(title, style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text(text, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
                  const SizedBox(height: 28),
                  Wrap(spacing: 16, runSpacing: 12, alignment: WrapAlignment.center, children: buttons),
                  const SizedBox(height: 20),
                  Text("${_step + 1} / ${_lastStep + 1}", style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _button(String label, VoidCallback onPressed, {bool primary = false}) {
    final accent = Theme.of(context).colorScheme.primary;
    return FilledButton(
      autofocus: primary,
      onPressed: onPressed,
      style: ButtonStyle(
        // The focused button must be obvious from the sofa.
        backgroundColor:
            WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.focused) ? accent : Colors.white12),
        foregroundColor:
            WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.focused) ? Colors.black : Colors.white),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 28, vertical: 16)),
      ),
      child: Text(label),
    );
  }
}
