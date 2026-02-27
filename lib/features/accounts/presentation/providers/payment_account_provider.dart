import 'package:flutter/foundation.dart';
import 'package:fintrack/database/hive_service.dart';
import 'package:fintrack/features/accounts/data/models/payment_account_model.dart';

class PaymentAccountProvider extends ChangeNotifier {
  List<PaymentAccount> _accounts = [];
  PaymentAccount? _selectedAccount;

  List<PaymentAccount> get accounts => _accounts;
  PaymentAccount? get selectedAccount => _selectedAccount;

  List<PaymentAccount> get activeAccounts =>
      _accounts.where((a) => a.isActive).toList();

  PaymentAccount? get defaultAccount {
    try {
      return _accounts.firstWhere((a) => a.isDefault);
    } catch (e) {
      return _accounts.isNotEmpty ? _accounts.first : null;
    }
  }

  PaymentAccountProvider() {
    _loadInitialData();
  }

  void _loadInitialData() {
    _accounts = HiveService.getAllPaymentAccounts();
    // Ensure at least default accounts exist
    if (_accounts.isEmpty) {
      final defaultAccounts = PaymentAccount.getDefaultAccounts();
      for (var account in defaultAccounts) {
        HiveService.addPaymentAccount(account);
        _accounts.add(account);
      }
    }
  }

  Future<void> addAccount(PaymentAccount account) async {
    try {
      // If this is set as default, unset all other defaults
      if (account.isDefault) {
        await _unsetAllDefaults();
      }

      await HiveService.addPaymentAccount(account);
      _accounts.add(account);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAccount(PaymentAccount account) async {
    try {
      print(
          '💾 updateAccount called: ${account.name}, balance=${account.balance}');
      // If this is set as default, unset all other defaults
      if (account.isDefault) {
        await _unsetAllDefaults();
      }

      await HiveService.updatePaymentAccount(account);
      print('💾 HiveService.updatePaymentAccount completed');
      final index = _accounts.indexWhere((a) => a.id == account.id);
      if (index != -1) {
        print('💾 Updating account at index $index in _accounts list');
        _accounts[index] = account;
      } else {
        print('❌ Account not found in _accounts list!');
      }
      print('💾 Calling notifyListeners()');
      notifyListeners();
      print('💾 updateAccount completed successfully');
    } catch (e) {
      print('❌ Error in updateAccount: $e');
      rethrow;
    }
  }

  Future<void> deleteAccount(String id) async {
    try {
      final account = _accounts.firstWhere((a) => a.id == id);

      // Prevent deletion if it's the only active account
      if (activeAccounts.length == 1 && account.isActive) {
        throw Exception('Cannot delete the only active account');
      }

      // If deleting default account, set another as default
      if (account.isDefault && _accounts.length > 1) {
        final nextDefault = _accounts.firstWhere(
          (a) => a.id != id && a.isActive,
          orElse: () => _accounts.firstWhere((a) => a.id != id),
        );
        await updateAccount(nextDefault.copyWith(isDefault: true));
      }

      await HiveService.deletePaymentAccount(id);
      _accounts.removeWhere((a) => a.id == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _unsetAllDefaults() async {
    for (var account in _accounts) {
      if (account.isDefault) {
        final updated = account.copyWith(isDefault: false);
        await HiveService.updatePaymentAccount(updated);
        final index = _accounts.indexWhere((a) => a.id == account.id);
        if (index != -1) {
          _accounts[index] = updated;
        }
      }
    }
  }

  Future<void> setDefaultAccount(String id) async {
    try {
      await _unsetAllDefaults();

      final account = _accounts.firstWhere((a) => a.id == id);
      final updated = account.copyWith(isDefault: true);
      await updateAccount(updated);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAccountBalance(String id, double newBalance) async {
    try {
      final account = _accounts.firstWhere((a) => a.id == id);
      final updated = account.copyWith(
        balance: newBalance,
        lastUpdated: DateTime.now(),
      );
      await updateAccount(updated);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> adjustAccountBalance(String id, double amount) async {
    try {
      final account = _accounts.firstWhere((a) => a.id == id);
      final newBalance = account.balance + amount;
      await updateAccountBalance(id, newBalance);
    } catch (e) {
      rethrow;
    }
  }

  List<PaymentAccount> getAccountsByType(String accountType) {
    return _accounts
        .where((a) => a.accountType == accountType && a.isActive)
        .toList();
  }

  PaymentAccount? getAccountById(String id) {
    try {
      return _accounts.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  double getTotalBalance() {
    return activeAccounts.fold<double>(0, (sum, account) {
      if (account.accountType.toLowerCase().contains('credit')) {
        // For credit cards, subtract the balance (debt) from total
        return sum - account.balance;
      }
      return sum + account.balance;
    });
  }

  double getTotalCreditCardBalance() {
    return activeAccounts
        .where((a) => a.accountType.toLowerCase().contains('credit'))
        .fold<double>(0, (sum, account) => sum + account.balance);
  }

  Map<String, double> getBalanceByType() {
    final balances = <String, double>{};
    for (var account in activeAccounts) {
      balances[account.accountType] =
          (balances[account.accountType] ?? 0) + account.balance;
    }
    return balances;
  }

  void selectAccount(PaymentAccount? account) {
    _selectedAccount = account;
    notifyListeners();
  }

  void refreshData() {
    _loadInitialData();
    notifyListeners();
  }
}
