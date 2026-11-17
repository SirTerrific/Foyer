import 'package:flutter/widgets.dart';

/// Keeps the remote's focus inside [child] while its route is on top.
///
/// The home grid grabs the focus when the apps finish loading, which can
/// happen after a dialog opened (cold start): without this the keys typed by
/// the user go to the home screen behind the dialog.
class KeepFocus extends StatefulWidget {
  final Widget child;

  const KeepFocus({super.key, required this.child});

  @override
  State<KeepFocus> createState() => _KeepFocusState();
}

class _KeepFocusState extends State<KeepFocus> {
  final _scope = FocusScopeNode();

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_keepFocus);
  }

  /// Takes the focus back, unless another route (a dialog) is open above.
  void _keepFocus() {
    if (mounted && !_scope.hasFocus && (ModalRoute.of(context)?.isCurrent ?? false)) _scope.requestFocus();
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_keepFocus);
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FocusScope(node: _scope, child: widget.child);
}
