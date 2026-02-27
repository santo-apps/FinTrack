import 'package:flutter/foundation.dart';
import 'package:fintrack/features/accounts/data/models/account_type_model.dart';
import 'package:fintrack/database/hive_service.dart';

class AccountTypeProvider with ChangeNotifier {
  List<AccountTypeModel> _accountTypes = [];

  AccountTypeProvider() {
    _loadAccountTypes();
    initializeDefaultTypes();
  }

  List<AccountTypeModel> get accountTypes => List.unmodifiable(_accountTypes);
  List<AccountTypeModel> get activeAccountTypes {
    final active = _accountTypes.where((type) => type.isActive).toList();
    // Remove duplicates by name
    final seen = <String>{};
    final unique = <AccountTypeModel>[];
    for (final type in active) {
      if (seen.add(type.name)) {
        unique.add(type);
      }
    }
    return unique;
  }

  Future<void> _loadAccountTypes() async {
    _accountTypes = await HiveService.getAllAccountTypes();
    _accountTypes.sort((a, b) => a.order.compareTo(b.order));
    notifyListeners();
  }

  Future<void> addAccountType(AccountTypeModel type) async {
    await HiveService.addAccountType(type);
    await _loadAccountTypes();
  }

  Future<void> updateAccountType(AccountTypeModel type) async {
    await HiveService.updateAccountType(type);
    await _loadAccountTypes();
  }

  Future<void> deleteAccountType(String id) async {
    await HiveService.deleteAccountType(id);
    await _loadAccountTypes();
  }

  Future<void> reorderAccountTypes(
      List<AccountTypeModel> reorderedTypes) async {
    for (int i = 0; i < reorderedTypes.length; i++) {
      final updatedType = reorderedTypes[i].copyWith(order: i);
      await HiveService.updateAccountType(updatedType);
    }
    await _loadAccountTypes();
  }

  Future<void> initializeDefaultTypes() async {
    final existingTypes = await HiveService.getAllAccountTypes();
    if (existingTypes.isEmpty) {
      final defaultTypes = [
        {'name': 'Bank Account', 'icon': '🏦', 'color': '#2196F3'},
        {'name': 'Credit Card', 'icon': '💳', 'color': '#F44336'},
        {'name': 'Debit Card', 'icon': '💎', 'color': '#9C27B0'},
        {'name': 'Wallet', 'icon': '👛', 'color': '#FF9800'},
        {'name': 'Cash', 'icon': '💵', 'color': '#4CAF50'},
        {'name': 'Savings Account', 'icon': '💰', 'color': '#00BCD4'},
        {'name': 'Investment Account', 'icon': '📈', 'color': '#673AB7'},
        {'name': 'Loan Account', 'icon': '🏠', 'color': '#795548'},
        {'name': 'Other', 'icon': '⚡', 'color': '#9E9E9E'},
      ];

      for (int i = 0; i < defaultTypes.length; i++) {
        final typeData = defaultTypes[i];
        final type = AccountTypeModel(
          id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
          name: typeData['name'] as String,
          icon: typeData['icon'] as String,
          color: typeData['color'] as String,
          isDefault: true,
          order: i,
          createdAt: DateTime.now(),
          isActive: true,
        );
        await addAccountType(type);
      }
    }
  }

  AccountTypeModel? getAccountTypeById(String id) {
    try {
      return _accountTypes.firstWhere((type) => type.id == id);
    } catch (e) {
      return null;
    }
  }

  AccountTypeModel? getAccountTypeByName(String name) {
    try {
      return _accountTypes.firstWhere((type) => type.name == name);
    } catch (e) {
      return null;
    }
  }
}
