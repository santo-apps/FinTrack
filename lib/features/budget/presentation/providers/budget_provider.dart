import 'package:flutter/foundation.dart';
import 'package:fintrack/database/hive_service.dart';
import 'package:fintrack/features/budget/data/models/budget_model.dart';

class BudgetProvider extends ChangeNotifier {
  final List<Budget> _budgets = [];

  List<Budget> get budgets => List.unmodifiable(_budgets);

  BudgetProvider() {
    _loadBudgets();
  }

  Future<void> initBudget() async {
    await _loadBudgets();
    notifyListeners();
  }

  Budget? getBudgetForMonth(int month, int year) {
    for (final budget in _budgets) {
      if (budget.month == month && budget.year == year) {
        return budget;
      }
    }
    return null;
  }

  Future<void> saveBudget(Budget budget) async {
    try {
      await HiveService.updateBudget(budget);
      final index = _budgets.indexWhere((b) => b.id == budget.id);
      if (index >= 0) {
        _budgets[index] = budget;
      } else {
        _budgets.add(budget);
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createOrUpdateBudget(
    Map<String, double> categoryLimits, {
    required int month,
    required int year,
    String currency = 'USD',
  }) async {
    try {
      final existing = getBudgetForMonth(month, year);
      final budget = Budget(
        id: existing?.id ?? '${year}_$month',
        categoryLimits: categoryLimits,
        createdAt: existing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        currency: currency,
        month: month,
        year: year,
      );
      await saveBudget(budget);
    } catch (e) {
      rethrow;
    }
  }

  double getTotalMonthlySpending(int month, int year) {
    final expenses = HiveService.getExpensesInDateRange(
      DateTime(year, month, 1),
      DateTime(year, month + 1, 0),
    );
    return expenses.fold<double>(0, (sum, e) => sum + e.amount);
  }

  double getCategorySpending(String category, int month, int year) {
    final expenses = HiveService.getExpensesByCategory(category);
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 0);

    return expenses
        .where((e) => e.date.isAfter(monthStart) && e.date.isBefore(monthEnd))
        .fold<double>(0, (sum, e) => sum + e.amount);
  }

  double getCategoryBudgetLimit(String category, int month, int year) {
    final budget = getBudgetForMonth(month, year);
    return budget?.categoryLimits[category] ?? 0;
  }

  double getCategoryProgress(String category, int month, int year) {
    final limit = getCategoryBudgetLimit(category, month, year);
    if (limit == 0) return 0;
    final spent = getCategorySpending(category, month, year);
    return (spent / limit).clamp(0, 1);
  }

  bool isCategoryOverBudget(String category, int month, int year) {
    final limit = getCategoryBudgetLimit(category, month, year);
    final spent = getCategorySpending(category, month, year);
    return spent > limit && limit > 0;
  }

  Future<void> refreshData() async {
    await _loadBudgets();
    notifyListeners();
  }

  Future<void> _loadBudgets() async {
    _budgets
      ..clear()
      ..addAll(HiveService.getAllBudgets());
  }
}
