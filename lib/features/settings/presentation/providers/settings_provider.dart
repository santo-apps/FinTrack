import 'package:flutter/foundation.dart';
import 'package:fintrack/core/constants/app_constants.dart';
import 'package:fintrack/database/hive_service.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _isBiometricEnabled = false;
  bool _isPINEnabled = false;
  bool _notificationsEnabled = true;
  String _currency = 'USD';
  String _language = 'en';
  List<String> _bottomNavItems = ['expenses', 'budget', 'bills'];
  List<String> _quickActionItems = ['expenses', 'accounts', 'budget', 'bills'];
  List<String> _overviewItems = [
    'monthly_spending',
    'subscriptions',
    'portfolio_value',
    'total_balance',
    'outstanding_loans',
    'unpaid_bills'
  ];
  List<String> _customCurrencies = [];
  Map<String, String> _customCurrencySymbols = {};

  bool get isDarkMode => _isDarkMode;
  bool get biometricEnabled => _isBiometricEnabled;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get pinEnabled => _isPINEnabled;
  bool get isPINEnabled => _isPINEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  String get currency => _currency;
  String get currencySymbol =>
      _customCurrencySymbols[_currency] ??
      AppUtils.currencySymbolForCode(_currency);
  String get language => _language;
  List<String> get bottomNavItems => List.unmodifiable(_bottomNavItems);
  List<String> get quickActionItems => List.unmodifiable(_quickActionItems);
  List<String> get overviewItems => List.unmodifiable(_overviewItems);
  Map<String, String> get customCurrencySymbols =>
      Map.unmodifiable(_customCurrencySymbols);
  List<String> get availableCurrencies {
    final currencies = [...AppConstants.supportedCurrencies];
    final customCodes = _customCurrencySymbols.keys.toList();
    for (final code in customCodes) {
      if (!currencies.contains(code)) {
        currencies.add(code);
      }
    }
    return currencies;
  }

  SettingsProvider() {
    _loadSettings();
  }

  void _loadSettings() {
    _isDarkMode = HiveService.getSetting('dark_mode', defaultValue: false);
    _isBiometricEnabled =
        HiveService.getSetting('biometric_enabled', defaultValue: false);
    _isPINEnabled = HiveService.getSetting('pin_enabled', defaultValue: false);
    _currency = HiveService.getSetting('currency', defaultValue: 'USD');
    _language = HiveService.getSetting('language', defaultValue: 'en');
    _bottomNavItems = List<String>.from(
      HiveService.getSetting(
        'bottom_nav_items',
        defaultValue: ['expenses', 'budget', 'bills'],
      ),
    );
    _quickActionItems = List<String>.from(
      HiveService.getSetting(
        'quick_action_items',
        defaultValue: ['expenses', 'accounts', 'budget', 'bills'],
      ),
    );
    _overviewItems = List<String>.from(
      HiveService.getSetting(
        'overview_items',
        defaultValue: [
          'monthly_spending',
          'subscriptions',
          'portfolio_value',
          'total_balance',
          'outstanding_loans',
          'unpaid_bills'
        ],
      ),
    );
    _customCurrencies = List<String>.from(
      HiveService.getSetting('custom_currencies', defaultValue: <String>[]),
    );
    final storedSymbols = HiveService.getSetting(
      'custom_currency_symbols',
      defaultValue: <String, String>{},
    );
    if (storedSymbols is Map) {
      _customCurrencySymbols = storedSymbols.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    }
    if (_customCurrencySymbols.isEmpty && _customCurrencies.isNotEmpty) {
      _customCurrencySymbols = {
        for (final code in _customCurrencies) code: code,
      };
    }
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    await HiveService.saveSetting('dark_mode', value);
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool value) async {
    _isBiometricEnabled = value;
    await HiveService.saveSetting('biometric_enabled', value);
    notifyListeners();
  }

  Future<void> setPinEnabled(bool value) async {
    _isPINEnabled = value;
    await HiveService.saveSetting('pin_enabled', value);
    if (!value) {
      // Clear PIN when disabled
      await HiveService.saveSetting('app_pin', '');
    }
    notifyListeners();
  }

  Future<void> setPin(String value) async {
    await HiveService.saveSetting('app_pin', value);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await HiveService.saveSetting('notifications_enabled', value);
    notifyListeners();
  }

  Future<void> setPINEnabled(bool value) async {
    _isPINEnabled = value;
    await HiveService.saveSetting('pin_enabled', value);
    notifyListeners();
  }

  Future<void> setCurrency(String value) async {
    _currency = value;
    await HiveService.saveSetting('currency', value);
    notifyListeners();
  }

  Future<void> addCustomCurrency(String code, String symbol) async {
    if (_customCurrencySymbols.containsKey(code) ||
        AppConstants.supportedCurrencies.contains(code)) {
      return;
    }
    _customCurrencySymbols = {
      ..._customCurrencySymbols,
      code: symbol,
    };
    await HiveService.saveSetting(
      'custom_currency_symbols',
      _customCurrencySymbols,
    );
    notifyListeners();
  }

  Future<void> updateCustomCurrencySymbol(String code, String symbol) async {
    if (!_customCurrencySymbols.containsKey(code)) {
      return;
    }
    _customCurrencySymbols = {
      ..._customCurrencySymbols,
      code: symbol,
    };
    await HiveService.saveSetting(
      'custom_currency_symbols',
      _customCurrencySymbols,
    );
    notifyListeners();
  }

  Future<void> removeCustomCurrency(String code) async {
    if (!_customCurrencySymbols.containsKey(code)) {
      return;
    }
    _customCurrencySymbols = Map<String, String>.from(_customCurrencySymbols)
      ..remove(code);
    await HiveService.saveSetting(
      'custom_currency_symbols',
      _customCurrencySymbols,
    );
    if (_currency == code) {
      _currency = AppConstants.defaultCurrency;
      await HiveService.saveSetting('currency', _currency);
    }
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    _language = value;
    await HiveService.saveSetting('language', value);
    notifyListeners();
  }

  Future<void> setBottomNavItems(List<String> items) async {
    _bottomNavItems = List<String>.from(items);
    await HiveService.saveSetting('bottom_nav_items', _bottomNavItems);
    notifyListeners();
  }

  Future<void> setQuickActionItems(List<String> items) async {
    _quickActionItems = List<String>.from(items);
    await HiveService.saveSetting('quick_action_items', _quickActionItems);
    notifyListeners();
  }

  Future<void> setOverviewItems(List<String> items) async {
    _overviewItems = List<String>.from(items);
    await HiveService.saveSetting('overview_items', _overviewItems);
    notifyListeners();
  }

  Future<void> refreshSettings() async {
    _loadSettings();
    notifyListeners();
  }
}
