import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/launcher_state.dart';
import 'package:flauncher/providers/parental_control_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/setup_wizard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks.mocks.dart';

void main() {
  late SettingsService settings;
  late ParentalControlService parental;
  late MockAppsService apps;
  late BuildContext context;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    settings = SettingsService(prefs);
    parental = ParentalControlService(prefs);
    apps = MockAppsService();
    when(apps.openHomeSettings()).thenAnswer((_) async => true);
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: parental),
          ChangeNotifierProvider<AppsService>.value(value: apps),
          ChangeNotifierProvider(create: (_) => LauncherState()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(builder: (c) {
            context = c;
            return const SizedBox();
          }),
        ),
      ));

  Future<void> tap(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets("first run walks the five steps, then never shows again", (tester) async {
    await pump(tester);
    final shown = maybeShowSetupWizard(context);
    await tester.pumpAndSettle();
    expect(find.text("Welcome to Foyer"), findsOneWidget);

    await tap(tester, "Let's go");
    expect(find.text("Foyer is not the default home app yet."), findsNothing); // part of a longer text
    expect(find.textContaining("Foyer is not the default home app yet."), findsOneWidget);
    await tap(tester, "Open settings");
    verify(apps.openHomeSettings()).called(1);
    await tap(tester, "Next");
    await tap(tester, "Gradient");
    expect(settings.bingWallpaperEnabled, isFalse);
    await tap(tester, "Next");
    expect(settings.setupDone, isFalse);
    await tap(tester, "Finish");
    await shown;
    expect(settings.setupDone, isTrue);
    expect(find.byType(SetupWizard), findsNothing);

    await maybeShowSetupWizard(context);
    await tester.pumpAndSettle();
    expect(find.byType(SetupWizard), findsNothing);
  });

  testWidgets("choosing Bing turns the Bing wallpaper on", (tester) async {
    await pump(tester);
    maybeShowSetupWizard(context);
    await tester.pumpAndSettle();
    await tap(tester, "Let's go");
    await tap(tester, "Next");
    await tap(tester, "Bing image of the day");
    expect(settings.bingWallpaperEnabled, isTrue);
    expect(find.text("Parental control"), findsOneWidget);
  });

  testWidgets("Back goes one step back and never closes the wizard", (tester) async {
    await pump(tester);
    maybeShowSetupWizard(context);
    await tester.pumpAndSettle();
    await tap(tester, "Let's go");
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text("Welcome to Foyer"), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(SetupWizard), findsOneWidget);
    expect(settings.setupDone, isFalse);
  });

  testWidgets("an install that already has a code skips the wizard", (tester) async {
    await parental.setCode(["U", "D", "L", "R"]);
    await pump(tester);
    await maybeShowSetupWizard(context);
    await tester.pumpAndSettle();
    expect(find.byType(SetupWizard), findsNothing);
    expect(settings.setupDone, isTrue);
  });
}
