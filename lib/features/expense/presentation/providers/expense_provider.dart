import 'package:flutter/foundation.dart';
import 'package:fintrack/database/hive_service.dart';
import 'package:fintrack/features/expense/data/models/expense_model.dart';
import 'package:fintrack/features/expense/data/models/expense_category_model.dart';
import 'package:fintrack/core/constants/app_constants.dart';

class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  List<ExpenseCategory> _categories = [];
  Expense? _selectedExpense;

  List<Expense> get expenses => _expenses;
  List<ExpenseCategory> get categories => _categories;
  Expense? get selectedExpense => _selectedExpense;

  List<ExpenseCategory> getCategoriesOrderedByUsage({
    String? transactionType,
  }) {
    final normalizedType = transactionType?.trim().toLowerCase();
    final categoryUsage = <String, int>{};

    for (final expense in _expenses) {
      final expenseType = (expense.transactionType ?? 'expense').toLowerCase();
      if (normalizedType != null && normalizedType.isNotEmpty) {
        if (normalizedType == 'expense' || normalizedType == 'payment') {
          if (expenseType != 'expense' && expenseType != 'payment') {
            continue;
          }
        } else if (expenseType != normalizedType) {
          continue;
        }
      }
      final key = expense.category.trim().toLowerCase();
      if (key.isEmpty) continue;
      categoryUsage[key] = (categoryUsage[key] ?? 0) + 1;
    }

    final ordered = List<ExpenseCategory>.from(_categories)
      ..sort((a, b) {
        final aKey = a.name.trim().toLowerCase();
        final bKey = b.name.trim().toLowerCase();
        final aCount = categoryUsage[aKey] ?? 0;
        final bCount = categoryUsage[bKey] ?? 0;
        if (aCount != bCount) {
          return bCount.compareTo(aCount);
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    return ordered;
  }

  ExpenseProvider() {
    _loadInitialData();
  }

  bool _isSystemSubscriptionPayment(Expense expense) {
    final transactionType = expense.transactionType ?? 'expense';
    return transactionType == 'payment' &&
        expense.category == 'Subscriptions' &&
        expense.title.startsWith('Subscription Payment - ');
  }

  void _loadInitialData() {
    _expenses = HiveService.getAllExpenses();
    _categories = HiveService.getAllCategories();
  }

  Future<void> addExpense(Expense expense) async {
    try {
      await HiveService.addExpense(expense);
      _expenses.add(expense);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      await HiveService.updateExpense(expense);
      final index = _expenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _expenses[index] = expense;
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await HiveService.deleteExpense(id);
      _expenses.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  List<Expense> getExpensesByCategory(String category) {
    return _expenses.where((e) => e.category == category).toList();
  }

  List<Expense> getExpensesInDateRange(DateTime start, DateTime end) {
    return _expenses
        .where((e) => e.date.isAfter(start) && e.date.isBefore(end))
        .toList();
  }

  Future<void> addCategory(ExpenseCategory category) async {
    try {
      await HiveService.addCategory(category);
      _categories.add(category);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCategory(ExpenseCategory category) async {
    try {
      await HiveService.updateCategory(category);
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await HiveService.deleteCategory(id);
      _categories.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  double getTotalMonthlyExpense() {
    final period = AppUtils.calculateMonthPeriod();
    final monthlyExpenses =
        getExpensesInDateRange(period['start'], period['end']).where((e) {
      final transactionType = e.transactionType ?? 'expense';
      final isExpenseLike =
          transactionType == 'expense' || transactionType == 'payment';
      return isExpenseLike && !_isSystemSubscriptionPayment(e);
    });
    return monthlyExpenses.fold<double>(0, (sum, e) => sum + e.amount);
  }

  Map<String, double> getMonthlyCategoryBreakdown() {
    final period = AppUtils.calculateMonthPeriod();
    final monthlyExpenses =
        getExpensesInDateRange(period['start'], period['end']).where((e) {
      final transactionType = e.transactionType ?? 'expense';
      final isExpenseLike =
          transactionType == 'expense' || transactionType == 'payment';
      return isExpenseLike && !_isSystemSubscriptionPayment(e);
    });
    final breakdown = <String, double>{};
    for (var expense in monthlyExpenses) {
      breakdown[expense.category] =
          (breakdown[expense.category] ?? 0) + expense.amount;
    }
    return breakdown;
  }

  void selectExpense(Expense? expense) {
    _selectedExpense = expense;
    notifyListeners();
  }

  Future<void> refreshData() async {
    _loadInitialData();
    notifyListeners();
  }
}
