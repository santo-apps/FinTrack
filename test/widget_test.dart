// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fintrack/database/hive_service.dart';
import 'package:fintrack/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:fintrack/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('fintrack_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (methodCall) async {
      switch (methodCall.method) {
        case 'getApplicationDocumentsDirectory':
        case 'getApplicationSupportDirectory':
        case 'getTemporaryDirectory':
          return tempDir.path;
        default:
          return tempDir.path;
      }
    });

    await HiveService.init();
    await HiveService.saveSetting('onboarding_completed', false);
    await HiveService.saveSetting('pin_enabled', false);
    await HiveService.saveSetting('biometric_enabled', false);
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });

  testWidgets('FinTrack smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FinTrack());
    await tester.pumpAndSettle();

    // Verify app boots and shows onboarding when not completed.
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}
