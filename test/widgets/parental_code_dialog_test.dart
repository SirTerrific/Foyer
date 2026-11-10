import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/parental_control_service.dart';
import 'package:flauncher/widgets/parental_code_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keys = {
  "U": LogicalKeyboardKey.arrowUp,
  "D": LogicalKeyboardKey.arrowDown,
  "L": LogicalKeyboardKey.arrowLeft,
  "R": LogicalKeyboardKey.arrowRight,
};

void main() {
  late ParentalControlService service;
  bool? result;

  Future<void> type(WidgetTester tester, ParentalCode code) async {
    for (final symbol in code) {
      await tester.sendKeyEvent(_keys[symbol]!);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
  }

  Future<void> openDialog(WidgetTester tester) async {
    result = null;
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: service,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            autofocus: true,
            onPressed: () async =>
                result = await showParentalCodeDialog(context, mode: ParentalCodeDialogMode.verify),
            child: const Text("open"),
          ),
        ),
      ),
    ));
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = ParentalControlService(await SharedPreferences.getInstance());
    await service.setCode(["U", "D", "L", "R"]);
  });

  testWidgets("backing out after the recovery code keeps both codes", (tester) async {
    final recovery = await service.generateRecoveryCode();
    await openDialog(tester);
    await type(tester, recovery);

    // Now on the "new code" step: leave without choosing one.
    Navigator.of(tester.element(find.byType(AlertDialog))).pop();
    await tester.pumpAndSettle();

    expect(result, isFalse);
    expect(service.hasRecoveryCode, isTrue);
    expect(await service.verify(recovery), ParentalCheckResult.recovered);
    expect(await service.verify(["U", "D", "L", "R"]), ParentalCheckResult.ok);
  });

  testWidgets("recovery code leads to a new code and a new recovery code", (tester) async {
    final recovery = await service.generateRecoveryCode();
    await openDialog(tester);
    await type(tester, recovery);
    await type(tester, ["L", "L", "R", "R"]);
    await type(tester, ["L", "L", "R", "R"]);

    // New recovery code on screen: OK closes the dialog.
    expect(service.hasRecoveryCode, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(await service.verify(["L", "L", "R", "R"]), ParentalCheckResult.ok);
    expect(await service.verify(["U", "D", "L", "R"]), ParentalCheckResult.wrong);
  });
}
