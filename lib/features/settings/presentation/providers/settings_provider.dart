import 'package:flutter/foundation.dart';
import 'package:fintrack/core/constants/app_constants.dart';
import 'package:fintrack/database/hive_service.dart';
import 'package:fintrack/features/subscription/data/models/subscription_category_model.dart';
import 'package:fintrack/services/notification_service.dart';

class SettingsProvider extends ChangeNotifier {
  static const List<String> _supportedOverviewItems = [
    'monthly_spending',
    'subscriptions',
    'portfolio_value',
    'outstanding_loans',
  ];

  bool _isDarkMode = false;
  bool _isBiometricEnabled = false;
  bool _isPINEnabled = false;
  bool _notificationsEnabled = true;
  bool _dailyReminderEnabled = true;
  int _dailyReminderHour = 9;
  int _dailyReminderMinute = 0;
  String _currency = 'USD';
  String _language = 'en';
  List<String> _bottomNavItems = ['expenses', 'budget', 'bills'];
  List<String> _quickActionItems = ['expenses', 'accounts', 'budget', 'bills'];
  List<String> _overviewItems = [
    'monthly_spending',
    'subscriptions',
    'portfolio_value',
    'outstanding_loans',
  ];
  List<String> _customCurrencies = [];
  Map<String, String> _customCurrencySymbols = {};
  List<SubscriptionCategoryModel> _subscriptionCategories =
      SubscriptionCategoryModel.getDefaultCategories();

  bool get isDarkMode => _isDarkMode;
  bool get biometricEnabled => _isBiometricEnabled;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get pinEnabled => _isPINEnabled;
  bool get isPINEnabled => _isPINEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get dailyReminderEnabled => _dailyReminderEnabled;
  int get dailyReminderHour => _dailyReminderHour;
  int get dailyReminderMinute => _dailyReminderMinute;
  String get currency => _currency;
  String get currencySymbol =>
      _customCurrencySymbols[_currency] ??
      AppUtils.currencySymbolForCode(_currency);
  String get language => _language;
  List<String> get bottomNavItems => List.unmodifiable(_bottomNavItems);
  List<String> get quickActionItems => List.unmodifiable(_quickActionItems);
  List<String> get overviewItems => List.unmodifiable(_overviewItems);
  List<SubscriptionCategoryModel> get subscriptionCategories =>
      List.unmodifiable(_subscriptionCategories);
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
    _notificationsEnabled =
        HiveService.getSetting('notifications_enabled', defaultValue: true);
    _dailyReminderEnabled =
        HiveService.getSetting('daily_reminder_enabled', defaultValue: true);
    _dailyReminderHour =
        HiveService.getSetting('daily_reminder_hour', defaultValue: 9);
    _dailyReminderMinute =
        HiveService.getSetting('daily_reminder_minute', defaultValue: 0);
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
          'outstanding_loans',
        ],
      ),
    );
    _overviewItems = _normalizeOverviewItems(_overviewItems);
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
    _loadSubscriptionCategories();
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
    if (value && _dailyReminderEnabled) {
      await NotificationService.scheduleDailyReminder(
        hour: _dailyReminderHour,
        minute: _dailyReminderMinute,
      );
    }

    if (!value) {
      await NotificationService.cancelDailyReminder();
    }

    _notificationsEnabled = value;
    await HiveService.saveSetting('notifications_enabled', value);
    notifyListeners();
  }

  Future<bool> setDailyReminderEnabled(bool value) async {
    try {
      if (value && _notificationsEnabled) {
        await NotificationService.scheduleDailyReminder(
          hour: _dailyReminderHour,
          minute: _dailyReminderMinute,
        );
      } else {
        await NotificationService.cancelDailyReminder();
      }

      _dailyReminderEnabled = value;
      await HiveService.saveSetting('daily_reminder_enabled', value);
      notifyListeners();
      return true;
    } catch (e) {
      _dailyReminderEnabled = false;
      await HiveService.saveSetting('daily_reminder_enabled', false);
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> setDailyReminderTime(int hour, int minute) async {
    try {
      _dailyReminderHour = hour;
      _dailyReminderMinute = minute;
      await HiveService.saveSetting('daily_reminder_hour', hour);
      await HiveService.saveSetting('daily_reminder_minute', minute);

      if (_dailyReminderEnabled && _notificationsEnabled) {
        await NotificationService.scheduleDailyReminder(
          hour: hour,
          minute: minute,
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      notifyListeners();
      rethrow;
    }
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
    _overviewItems = _normalizeOverviewItems(items);
    await HiveService.saveSetting('overview_items', _overviewItems);
    notifyListeners();
  }

  List<String> _normalizeOverviewItems(List<String> items) {
    final normalized = <String>[];
    for (final id in items) {
      if (_supportedOverviewItems.contains(id) && !normalized.contains(id)) {
        normalized.add(id);
      }
    }

    if (normalized.isEmpty) {
      return ['monthly_spending'];
    }

    return normalized;
  }

  Future<void> refreshSettings() async {
    _loadSettings();
    notifyListeners();
  }

  // Subscription Categories Management
  void _loadSubscriptionCategories() {
    final stored = HiveService.getSetting('subscription_categories');

    if (stored == null) {
      _subscriptionCategories =
          SubscriptionCategoryModel.getDefaultCategories();
      return;
    }

    try {
      if (stored is List) {
        if (stored.isEmpty) {
          _subscriptionCategories =
              SubscriptionCategoryModel.getDefaultCategories();
        } else if (stored.first is String) {
          // Old format - migrate from strings
          _subscriptionCategories = stored
              .map((item) =>
                  SubscriptionCategoryModel.fromString(item.toString()))
              .toList();
          _saveSubscriptionCategories(); // Save in new format
        } else if (stored.first is Map) {
          // New format
          _subscriptionCategories = stored
              .map((item) => SubscriptionCategoryModel.fromJson(
                  item as Map<String, dynamic>))
              .toList();
        } else {
          _subscriptionCategories =
              SubscriptionCategoryModel.getDefaultCategories();
        }
      } else {
        _subscriptionCategories =
            SubscriptionCategoryModel.getDefaultCategories();
      }
    } catch (e) {
      _subscriptionCategories =
          SubscriptionCategoryModel.getDefaultCategories();
    }

    _subscriptionCategories =
        _normalizeSubscriptionCategories(_subscriptionCategories);
  }

  List<SubscriptionCategoryModel> _normalizeSubscriptionCategories(
      List<SubscriptionCategoryModel> categories) {
    final normalized = <SubscriptionCategoryModel>[];
    final seenNames = <String>{};

    for (final category in categories) {
      final trimmed = category.name.trim();
      if (trimmed.isEmpty) continue;

      final lowerName = trimmed.toLowerCase();
      if (!seenNames.contains(lowerName)) {
        seenNames.add(lowerName);
        normalized.add(category);
      }
    }

    if (normalized.isEmpty) {
      return SubscriptionCategoryModel.getDefaultCategories();
    }

    if (!normalized.any((c) => c.name.toLowerCase() == 'other')) {
      normalized.add(SubscriptionCategoryModel(
        id: 'other',
        name: 'Other',
        icon: '📋',
      ));
    }

    return normalized;
  }

  Future<void> _saveSubscriptionCategories() async {
    final json = _subscriptionCategories.map((c) => c.toJson()).toList();
    await HiveService.saveSetting('subscription_categories', json);
  }

  Future<bool> addSubscriptionCategory(String name, [String? icon]) async {
    final trimmed = name.trim();
    final categoryIcon = icon?.trim() ?? '📱';

    if (trimmed.isEmpty) {
      return false;
    }

    final exists = _subscriptionCategories.any(
      (existing) => existing.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (exists) {
      return false;
    }

    _subscriptionCategories = [
      ..._subscriptionCategories,
      SubscriptionCategoryModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: trimmed,
        icon: categoryIcon,
      ),
    ];
    _subscriptionCategories =
        _normalizeSubscriptionCategories(_subscriptionCategories);
    await _saveSubscriptionCategories();
    notifyListeners();
    return true;
  }

  Future<bool> updateSubscriptionCategory(
    String oldCategoryName,
    String newName, {
    String? newIcon,
  }) async {
    final oldTrimmed = oldCategoryName.trim();
    final newTrimmed = newName.trim();

    if (oldTrimmed.isEmpty || newTrimmed.isEmpty) {
      return false;
    }

    if (oldTrimmed.toLowerCase() == 'other' &&
        newTrimmed.toLowerCase() != 'other') {
      return false;
    }

    final oldIndex = _subscriptionCategories.indexWhere(
      (category) => category.name.toLowerCase() == oldTrimmed.toLowerCase(),
    );
    if (oldIndex == -1) {
      return false;
    }

    final duplicateIndex = _subscriptionCategories.indexWhere(
      (category) => category.name.toLowerCase() == newTrimmed.toLowerCase(),
    );
    if (duplicateIndex != -1 && duplicateIndex != oldIndex) {
      return false;
    }

    final updated =
        List<SubscriptionCategoryModel>.from(_subscriptionCategories);
    updated[oldIndex] = SubscriptionCategoryModel(
      id: _subscriptionCategories[oldIndex].id,
      name: newTrimmed,
      icon: newIcon?.trim() ?? _subscriptionCategories[oldIndex].icon,
    );
    _subscriptionCategories = _normalizeSubscriptionCategories(updated);
    await _saveSubscriptionCategories();
    notifyListeners();
    return true;
  }

  Future<bool> deleteSubscriptionCategory(String categoryName) async {
    final trimmed = categoryName.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'other') {
      return false;
    }

    final oldLength = _subscriptionCategories.length;
    _subscriptionCategories = _subscriptionCategories
        .where((c) => c.name.toLowerCase() != trimmed.toLowerCase())
        .toList();

    if (_subscriptionCategories.length == oldLength) {
      return false;
    }

    _subscriptionCategories =
        _normalizeSubscriptionCategories(_subscriptionCategories);
    await _saveSubscriptionCategories();
    notifyListeners();
    return true;
  }
}
