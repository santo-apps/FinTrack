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
    debugPrint('[BudgetProvider] Looking for budget for $month/$year');
    debugPrint('[BudgetProvider] Total budgets loaded: ${_budgets.length}');
    for (final budget in _budgets) {
      debugPrint(
          '[BudgetProvider] Budget: ${budget.id}, month=${budget.month}, year=${budget.year}, baselineId=${budget.baselineId}');
      if (budget.month == month && budget.year == year) {
        debugPrint('[BudgetProvider] Found matching budget!');
        return budget;
      }
    }
    debugPrint('[BudgetProvider] No budget found for $month/$year');
    return null;
  }

  /// Gets budgets for a specific month, including recurring instances
  List<Budget> getBudgetsForMonth(int month, int year) {
    return _budgets.where((b) => b.month == month && b.year == year).toList();
  }

  /// Creates or updates a budget with recurrence option
  Future<void> createOrUpdateBudget(
    Map<String, double> categoryLimits, {
    required int month,
    required int year,
    String currency = 'USD',
    String recurrenceType = 'oneTime',
    DateTime? endDate,
  }) async {
    try {
      final existing = getBudgetForMonth(month, year);
      final now = DateTime.now();

      debugPrint('[BudgetProvider] createOrUpdateBudget called:');
      debugPrint('  - month=$month, year=$year');
      debugPrint('  - recurrenceType=$recurrenceType');
      debugPrint('  - endDate=$endDate');
      debugPrint('  - existing=$existing');

      // Check if this is a recurring budget setup
      final isConvertingToRecurring = recurrenceType == 'monthly';
      final isEditingExisting = existing != null && !isConvertingToRecurring;

      debugPrint(
          '[BudgetProvider] isConvertingToRecurring=$isConvertingToRecurring, isEditingExisting=$isEditingExisting');

      if (isConvertingToRecurring) {
        // Create base budget for this month and all future months until endDate
        // First, delete the existing one-time budget if it exists (no baselineId)
        if (existing != null && existing.baselineId == null) {
          debugPrint(
              '[BudgetProvider] Deleting existing one-time budget before creating recurring series');
          await HiveService.deleteBudget(existing.id);
          _budgets.removeWhere((b) => b.id == existing.id);
        }
        // Create base budget for this month and all future months until endDate
        final baselineId = '${year}_${month}_${now.millisecondsSinceEpoch}';
        final endDateToUse =
            endDate ?? DateTime(year + 10, month); // Default 10 years

        debugPrint(
            '[BudgetProvider] Creating recurring budget series with baselineId: $baselineId');
        debugPrint('[BudgetProvider] End date: $endDateToUse');

        int currentMonth = month;
        int currentYear = year;
        int budgetCount = 0;

        while (DateTime(currentYear, currentMonth, 1).isBefore(
            DateTime(endDateToUse.year, endDateToUse.month, 1)
                .add(const Duration(days: 1)))) {
          final budget = Budget(
            id: '${currentYear}_${currentMonth}_$baselineId',
            categoryLimits: categoryLimits,
            createdAt: now,
            updatedAt: now,
            currency: currency,
            month: currentMonth,
            year: currentYear,
            recurrenceType: recurrenceType,
            endDate: endDateToUse,
            baselineId: baselineId,
          );
          debugPrint(
              '[BudgetProvider] Creating budget ${budget.id} for $currentMonth/$currentYear');
          await HiveService.updateBudget(budget);
          _budgets.add(budget);
          budgetCount++;

          currentMonth++;
          if (currentMonth > 12) {
            currentMonth = 1;
            currentYear++;
          }
        }
        debugPrint('[BudgetProvider] Created $budgetCount recurring budgets');
      } else if (isEditingExisting) {
        // Update only this specific month's budget
        final updated = existing.copyWith(
          categoryLimits: categoryLimits,
          updatedAt: DateTime.now(),
          recurrenceType: recurrenceType,
          endDate: endDate,
        );
        await HiveService.updateBudget(updated);
        final index = _budgets.indexWhere((b) => b.id == updated.id);
        if (index >= 0) {
          _budgets[index] = updated;
        }
      } else {
        // Create a new one-time budget
        final budget = Budget(
          id: existing?.id ?? '${year}_$month',
          categoryLimits: categoryLimits,
          createdAt: existing?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
          currency: currency,
          month: month,
          year: year,
          recurrenceType: recurrenceType,
          endDate: endDate,
        );
        await HiveService.updateBudget(budget);
        final index = _budgets.indexWhere((b) => b.id == budget.id);
        if (index >= 0) {
          _budgets[index] = budget;
        } else {
          _budgets.add(budget);
        }
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete budget for a specific month only
  Future<void> deleteBudgetForMonth(int month, int year) async {
    try {
      final budget = getBudgetForMonth(month, year);
      if (budget != null) {
        await HiveService.deleteBudget(budget.id);
        _budgets.removeWhere((b) => b.id == budget.id);
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete entire recurring series
  Future<void> deleteRecurringSeries(String baselineId) async {
    try {
      final toDelete =
          _budgets.where((b) => b.baselineId == baselineId).toList();
      for (final budget in toDelete) {
        await HiveService.deleteBudget(budget.id);
      }
      _budgets.removeWhere((b) => b.baselineId == baselineId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
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

  /// Update all budgets in a recurring series with new category limits
  Future<void> updateRecurringSeries(
    String baselineId,
    Map<String, double> categoryLimits,
  ) async {
    try {
      final budgetsInSeries =
          _budgets.where((b) => b.baselineId == baselineId).toList();

      for (final budget in budgetsInSeries) {
        final updated = budget.copyWith(
          categoryLimits: categoryLimits,
          updatedAt: DateTime.now(),
        );
        await HiveService.updateBudget(updated);
        final index = _budgets.indexWhere((b) => b.id == budget.id);
        if (index >= 0) {
          _budgets[index] = updated;
        }
      }
      notifyListeners();
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
    debugPrint('[BudgetProvider] Loaded ${_budgets.length} budgets from Hive');
    for (final budget in _budgets) {
      debugPrint(
          '[BudgetProvider] - ${budget.id}: ${budget.month}/${budget.year}, baselineId=${budget.baselineId}, recurrenceType=${budget.recurrenceType}');
    }
  }
}
