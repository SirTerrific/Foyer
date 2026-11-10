import 'dart:math';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/parental_control_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// recovery: draws a new recovery code and shows it once.
enum ParentalCodeDialogMode { verify, create, recovery }

const _arrows = {"U": "↑", "D": "↓", "L": "←", "R": "→"};

/// "↑↓←→  ↑↑←→  ..." in groups of four, easier to copy on paper.
String formatRecoveryCode(ParentalCode code) {
  final glyphs = code.map((s) => _arrows[s] ?? s).toList();
  final groups = <String>[];
  for (var i = 0; i < glyphs.length; i += 4) {
    groups.add(glyphs.sublist(i, min(i + 4, glyphs.length)).join());
  }
  return groups.join("  ");
}

String? _symbolFor(LogicalKeyboardKey key) {
  if (key == LogicalKeyboardKey.arrowUp) return "U";
  if (key == LogicalKeyboardKey.arrowDown) return "D";
  if (key == LogicalKeyboardKey.arrowLeft) return "L";
  if (key == LogicalKeyboardKey.arrowRight) return "R";
  const digits = [
    LogicalKeyboardKey.digit0, LogicalKeyboardKey.digit1, LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3, LogicalKeyboardKey.digit4, LogicalKeyboardKey.digit5,
    LogicalKeyboardKey.digit6, LogicalKeyboardKey.digit7, LogicalKeyboardKey.digit8,
    LogicalKeyboardKey.digit9,
  ];
  const numpad = [
    LogicalKeyboardKey.numpad0, LogicalKeyboardKey.numpad1, LogicalKeyboardKey.numpad2,
    LogicalKeyboardKey.numpad3, LogicalKeyboardKey.numpad4, LogicalKeyboardKey.numpad5,
    LogicalKeyboardKey.numpad6, LogicalKeyboardKey.numpad7, LogicalKeyboardKey.numpad8,
    LogicalKeyboardKey.numpad9,
  ];
  final d = digits.indexOf(key);
  if (d >= 0) return "$d";
  final n = numpad.indexOf(key);
  if (n >= 0) return "$n";
  return null;
}

bool _isValidate(LogicalKeyboardKey key) =>
    key == LogicalKeyboardKey.select ||
    key == LogicalKeyboardKey.enter ||
    key == LogicalKeyboardKey.numpadEnter ||
    key == LogicalKeyboardKey.gameButtonA;

/// Asks for the parental code with the remote (arrows / digits + OK).
/// The code is shown as dots only. Back cancels.
///
/// verify: resolves true once the code is accepted.
/// create: asks the code twice, stores it, shows a new recovery code, resolves true.
/// A valid recovery code in verify mode switches to create.
Future<bool> showParentalCodeDialog(BuildContext context, {required ParentalCodeDialogMode mode}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _ParentalCodeDialog(mode: mode),
  );
  return result ?? false;
}

class _ParentalCodeDialog extends StatefulWidget {
  final ParentalCodeDialogMode mode;

  const _ParentalCodeDialog({required this.mode});

  @override
  State<_ParentalCodeDialog> createState() => _ParentalCodeDialogState();
}

class _ParentalCodeDialogState extends State<_ParentalCodeDialog> {
  final List<String> _entered = [];
  List<String>? _firstEntry; // create mode, awaiting confirmation
  String? _error;
  bool _busy = false;
  bool _recovered = false; // verify mode, recovery code accepted: pick a new code
  ParentalCode? _shownRecovery; // last step: recovery code on screen

  bool get _creating => widget.mode == ParentalCodeDialogMode.create || _recovered;
  bool get _showingRecovery => _shownRecovery != null || widget.mode == ParentalCodeDialogMode.recovery;

  @override
  void initState() {
    super.initState();
    if (widget.mode == ParentalCodeDialogMode.recovery) {
      _busy = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showNewRecovery());
    }
  }

  Future<void> _showNewRecovery() async {
    final code = await context.read<ParentalControlService>().generateRecoveryCode();
    if (!mounted) return;
    setState(() {
      _shownRecovery = code;
      _busy = false;
    });
  }

  String get _title {
    final l = AppLocalizations.of(context)!;
    if (_showingRecovery) return l.parentalRecoveryTitle;
    if (!_creating) return l.parentalRestrictedAccess;
    return _firstEntry == null ? l.parentalNewCode : l.parentalConfirmCode;
  }

  String get _hint {
    final l = AppLocalizations.of(context)!;
    if (_showingRecovery) return l.parentalRecoveryHint;
    if (!_creating) {
      final hasRecovery = Provider.of<ParentalControlService>(context, listen: false).hasRecoveryCode;
      return hasRecovery ? "${l.parentalHintVerify}\n${l.parentalForgotHint}" : l.parentalHintVerify;
    }
    if (_recovered && _firstEntry == null) {
      return "${l.parentalRecoveryAccepted}\n${l.parentalHintCreate(ParentalControlService.minCodeLength)}";
    }
    return _firstEntry == null
        ? l.parentalHintCreate(ParentalControlService.minCodeLength)
        : l.parentalHintConfirm;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent || _busy) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (_shownRecovery != null) {
      if (_isValidate(key)) {
        if (event is KeyDownEvent) Navigator.of(context).pop(true);
        return KeyEventResult.handled;
      }
      // Arrows must not move focus out of the dialog; Back still closes it.
      return _symbolFor(key) != null ? KeyEventResult.handled : KeyEventResult.ignored;
    }

    final symbol = _symbolFor(key);
    if (symbol != null) {
      setState(() {
        _error = null;
        if (_entered.length < 16) _entered.add(symbol);
      });
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace || key == LogicalKeyboardKey.delete) {
      setState(() {
        if (_entered.isNotEmpty) _entered.removeLast();
      });
      return KeyEventResult.handled;
    }
    if (_isValidate(key)) {
      if (event is KeyDownEvent) _validate();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored; // Back etc. fall through to the dialog
  }

  Future<void> _validate() async {
    final service = context.read<ParentalControlService>();
    final code = List<String>.from(_entered);
    setState(() => _busy = true);

    if (!_creating) {
      final result = await service.verify(code);
      if (!mounted) return;
      switch (result) {
        case ParentalCheckResult.ok:
          Navigator.of(context).pop(true);
          return;
        case ParentalCheckResult.recovered:
          setState(() {
            _recovered = true;
            _entered.clear();
            _error = null;
            _busy = false;
          });
        case ParentalCheckResult.wrong:
          _fail(AppLocalizations.of(context)!.parentalWrongCode);
        case ParentalCheckResult.lockedOut:
          _fail(AppLocalizations.of(context)!.parentalLocked(service.lockRemaining.inSeconds + 1));
      }
      return;
    }

    if (code.length < ParentalControlService.minCodeLength) {
      _fail(AppLocalizations.of(context)!.parentalTooShort(ParentalControlService.minCodeLength));
      return;
    }
    if (_firstEntry == null) {
      setState(() {
        _firstEntry = code;
        _entered.clear();
        _busy = false;
      });
      return;
    }
    if (_firstEntry!.join() != code.join()) {
      setState(() => _firstEntry = null);
      _fail(AppLocalizations.of(context)!.parentalMismatch);
      return;
    }
    await service.setCode(code);
    if (!mounted) return;
    setState(() => _entered.clear());
    await _showNewRecovery();
  }

  void _fail(String message) {
    setState(() {
      _error = message;
      _entered.clear();
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: AlertDialog(
        title: Text(_title),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_hint, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              if (_showingRecovery)
                SizedBox(
                  height: 36,
                  child: Text(
                    _shownRecovery == null ? "" : formatRecoveryCode(_shownRecovery!),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 4),
                  ),
                )
              else
              SizedBox(
                height: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _entered.length; i++)
                      Container(
                        width: 14,
                        height: 14,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                      ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
