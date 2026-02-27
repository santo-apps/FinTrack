import 'package:local_auth/local_auth.dart';
import '../database/hive_service.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> canUseBiometrics() async {
    try {
      final isDeviceSupported = await _auth.canCheckBiometrics;
      final availableBiometrics = await _auth.getAvailableBiometrics();
      final isDeviceSecure = availableBiometrics.isNotEmpty;
      return isDeviceSupported && isDeviceSecure;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> authenticate() async {
    try {
      final isBiometricEnabled =
          HiveService.getSetting('biometric_enabled', defaultValue: false);

      if (!isBiometricEnabled) {
        return false;
      }

      final isAuthenticated = await _auth.authenticate(
        localizedReason: 'Authenticate to access FinTrack',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      return isAuthenticated;
    } catch (e) {
      return false;
    }
  }

  static Future<void> enableBiometric() async {
    final canUse = await canUseBiometrics();
    if (canUse) {
      await HiveService.saveSetting('biometric_enabled', true);
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
    if (pin.length != 4 || !RegExp(r'^[0-9]+$').hasMatch(pin)) {
      throw Exception('PIN must be exactly 4 digits');
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
