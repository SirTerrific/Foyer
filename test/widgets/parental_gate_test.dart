import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/parental_control_service.dart';
import 'package:flauncher/widgets/parental_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ParentalControlService service;
  late BuildContext context;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = ParentalControlService(await SharedPreferences.getInstance());
    await service.setCode(["U", "D", "L", "R"]);
    await service.setEnabled(true);
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(ChangeNotifierProvider.value(
        value: service,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(builder: (c) {
            context = c;
            return const SizedBox();
          }),
        ),
      ));

  testWidgets("app info of an unprotected app asks the code while settings are protected", (tester) async {
    await pump(tester);
    var done = false;
    ensureAppAdminUnlocked(context, "com.other").then((_) => done = true);
    await tester.pump();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(done, isFalse);
  });

  testWidgets("app info of an unprotected app is free once settings are not protected", (tester) async {
    await service.setProtectSettings(false);
    await pump(tester);
    expect(await ensureAppAdminUnlocked(context, "com.other"), isTrue);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets("app info of a protected app asks the code even if settings are not protected", (tester) async {
    await service.setProtectSettings(false);
    await service.setPackageProtected("com.youtube", true);
    await pump(tester);
    ensureAppAdminUnlocked(context, "com.youtube");
    await tester.pump();
    expect(find.byType(AlertDialog), findsOneWidget);
  });
}
