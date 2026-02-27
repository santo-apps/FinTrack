import 'package:flutter/foundation.dart';
import 'package:fintrack/database/hive_service.dart';
import 'package:fintrack/features/debt/data/models/debt_model.dart';

class DebtProvider extends ChangeNotifier {
  List<Debt> _debts = [];

  List<Debt> get debts => _debts;

  DebtProvider() {
    _loadDebts();
  }

  void _loadDebts() {
    _debts = HiveService.getAllDebts();
  }

  Future<void> addDebt(Debt debt) async {
    try {
      await HiveService.addDebt(debt);
      _debts.add(debt);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDebt(Debt debt) async {
    try {
      await HiveService.updateDebt(debt);
      final index = _debts.indexWhere((d) => d.id == debt.id);
      if (index != -1) {
        _debts[index] = debt;
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteDebt(String id) async {
    try {
      await HiveService.deleteDebt(id);
      _debts.removeWhere((d) => d.id == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  double getTotalDebt() {
    return _debts.fold<double>(0, (sum, d) => sum + d.remainingBalance);
  }

  double getTotalMonthlyEMI() {
    return _debts.fold<double>(0, (sum, d) => sum + d.monthlyEmi);
  }

  Debt? getDebtById(String id) {
    try {
      return _debts.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> refreshData() async {
    _loadDebts();
    notifyListeners();
  }
}
