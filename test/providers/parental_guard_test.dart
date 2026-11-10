import 'dart:async';

import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/providers/parental_control_service.dart';
import 'package:flauncher/providers/parental_guard.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> resumed;
  late List<String?> pending;
  late ParentalGuard guard;

  setUp(() async {
    resumed = [];
    pending = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('me.efesser.flauncher/method'), (call) async {
      switch (call.method) {
        case 'takeParentalLock':
          return pending.isEmpty ? null : pending.removeAt(0);
        case 'resumeLockedApp':
          resumed.add(call.arguments as String);
          return true;
        case 'parentalGuardStatus':
          return {'available': true, 'enabled': true};
      }
      return null;
    });
    SharedPreferences.setMockInitialValues({});
    guard = ParentalGuard(FLauncherChannel(), ParentalControlService(await SharedPreferences.getInstance()));
  });

  test('right code reopens the app the guard covered', () async {
    pending = ['com.youtube'];
    await guard.handleLock(() async => true);
    expect(resumed, ['com.youtube']);
  });

  test('wrong or cancelled code reopens nothing', () async {
    pending = ['com.youtube'];
    await guard.handleLock(() async => false);
    expect(resumed, isEmpty);
  });

  test('a second trigger while the dialog is open does not stack a second dialog', () async {
    pending = ['com.youtube', 'com.netflix'];
    final answer = Completer<bool>();
    var dialogs = 0;
    Future<bool> ask() {
      dialogs++;
      return answer.future;
    }

    final first = guard.handleLock(ask);
    await Future<void>.delayed(Duration.zero);
    await guard.handleLock(ask); // second trigger: returns at once
    expect(dialogs, 1);

    answer.complete(true);
    await first;
    expect(resumed, ['com.youtube']);

    // Dialog closed: the guard works again.
    pending = ['com.netflix'];
    await guard.handleLock(() async => true);
    expect(resumed, ['com.youtube', 'com.netflix']);
  });

  test('nothing pending: no dialog', () async {
    var dialogs = 0;
    await guard.handleLock(() async {
      dialogs++;
      return true;
    });
    expect(dialogs, 0);
  });
}
