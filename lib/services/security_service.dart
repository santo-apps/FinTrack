import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database/hive_service.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<(bool, String)> getBiometricStatusForSettings() async {
    try {
      final isDeviceSupported = await _auth.isDeviceSupported();
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final availableBiometrics = await _auth.getAvailableBiometrics();

      if (!isDeviceSupported) {
        return (
          false,
          'Biometric authentication is not supported on this device'
        );
      }

      if (!canCheckBiometrics || availableBiometrics.isEmpty) {
        return (
          false,
          'No fingerprint/face enrolled. Add it in device settings'
        );
      }

      return (true, 'Use fingerprint or face ID');
    } on PlatformException catch (e) {
      if (e.code == 'passcodeNotSet') {
        return (false, 'Set device PIN/pattern/password first');
      }
      if (e.code == 'notEnrolled') {
        return (
          false,
          'No biometrics enrolled. Add fingerprint/face in settings'
        );
      }
      if (e.code == 'noBiometricHardware') {
        return (false, 'This device has no biometric hardware');
      }
      return (false, 'Biometric is unavailable on this device');
    } catch (_) {
      return (false, 'Biometric status unavailable');
    }
  }

  static Future<bool> canUseBiometrics() async {
    try {
      final isDeviceSupported = await _auth.canCheckBiometrics;
      final availableBiometrics = await _auth.getAvailableBiometrics();
      final isDeviceSecure = availableBiometrics.isNotEmpty;

      print(
          '[BiometricService] Device supported: $isDeviceSupported, Secure: $isDeviceSecure, Available: $availableBiometrics');

      return isDeviceSupported && isDeviceSecure;
    } catch (e) {
      print('[BiometricService] Error checking biometrics: $e');
      return false;
    }
  }

  static Future<bool> authenticate() async {
    try {
      print('[BiometricService] Starting authenticate()');
      final isAuthenticated = await _auth.authenticate(
        localizedReason: 'Authenticate to access FinTrack',
        options: const AuthenticationOptions(
          stickyAuth: true,
          useErrorDialogs: true,
          biometricOnly: true,
        ),
      );

      print('[BiometricService] Authentication result: $isAuthenticated');
      return isAuthenticated;
    } catch (e) {
      print('[BiometricService] Authentication error: $e');
      return false;
    }
  }

  /// Enable biometric authentication
  /// This will request device permissions and require user authentication
  /// Returns a tuple (success, errorMessage, shouldOpenSettings)
  static Future<(bool, String?, bool)> enableBiometric() async {
    try {
      final isDeviceSupported = await _auth.isDeviceSupported();
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final availableBiometrics = await _auth.getAvailableBiometrics();

      print(
          '[BiometricService] Precheck -> supported: $isDeviceSupported, canCheck: $canCheckBiometrics, available: $availableBiometrics');

      if (!isDeviceSupported) {
        return (
          false,
          'Biometric authentication is not supported on this device.',
          false,
        );
      }

      if (!canCheckBiometrics || availableBiometrics.isEmpty) {
        return (
          false,
          'No fingerprint or face is set up on this device. Please enroll biometrics in system settings first.',
          true,
        );
      }

      final authenticated = await authenticate();
      if (!authenticated) {
        print('[BiometricService] User cancelled or authentication failed');
        return (
          false,
          'Authentication cancelled or failed. Please try again.',
          false
        );
      }

      // Save the setting if authentication was successful
      await HiveService.saveSetting('biometric_enabled', true);
      print('[BiometricService] Biometric enabled successfully');
      return (true, null, false);
    } on PlatformException catch (e) {
      final code = e.code;
      print('[BiometricService] PlatformException: $code - ${e.message}');

      if (code == 'noBiometricHardware') {
        return (false, 'This device has no biometric hardware.', false);
      }
      if (code == 'notEnrolled') {
        return (
          false,
          'No biometrics enrolled. Add fingerprint/face in device settings and try again.',
          true,
        );
      }
      if (code == 'passcodeNotSet') {
        return (
          false,
          'Device screen lock is not set. Set a PIN/pattern/password first, then enable biometric.',
          true,
        );
      }
      if (code == 'lockedOut' || code == 'permanentlyLockedOut') {
        return (
          false,
          'Biometric is temporarily locked. Unlock your device and try again.',
          true,
        );
      }
      if (code == 'no_fragment_activity') {
        return (
          false,
          'Android activity is not configured for biometrics. Please reinstall the app and try again.',
          false,
        );
      }

      return (false, e.message ?? 'Biometric authentication failed.', false);
    } catch (e) {
      print('[BiometricService] Exception in enableBiometric: $e');
      return (false, 'An unexpected error occurred: $e', false);
    }
  }

  static Future<void> openBiometricSettings() async {
    try {
      if (Platform.isAndroid) {
        const intent =
            AndroidIntent(action: 'android.settings.SECURITY_SETTINGS');
        await intent.launch();
        return;
      }

      final settingsUri = Uri.parse('app-settings:');
      if (await canLaunchUrl(settingsUri)) {
        await launchUrl(settingsUri);
      }
    } catch (e) {
      print('[BiometricService] Failed to open settings: $e');
    }
  }

  static Future<void> disableBiometric() async {
    await HiveService.saveSetting('biometric_enabled', false);
  }

  static Future<bool> isBiometricEnabled() async {
    return HiveService.getSetting('biometric_enabled', defaultValue: false);
  }
}

class PINService {
  static Future<void> setPIN(String pin) async {
    final pinLength = pin.length;
    if ((pinLength != 4 && pinLength != 6) ||
        !RegExp(r'^[0-9]+$').hasMatch(pin)) {
      throw Exception('PIN must be exactly 4 or 6 digits');
    }
    await HiveService.saveSetting('app_pin', pin);
    await HiveService.saveSetting('pin_enabled', true);
  }

  static Future<bool> isPINEnabled() async {
    return HiveService.getSetting('pin_enabled', defaultValue: false);
  }

  static Future<bool> verifyPIN(String pin) async {
    final savedPIN = HiveService.getSetting('app_pin');
    return pin == savedPIN;
  }

  static Future<void> disablePIN() async {
    await HiveService.saveSetting('pin_enabled', false);
    await HiveService.saveSetting('app_pin', null);
  }
}
