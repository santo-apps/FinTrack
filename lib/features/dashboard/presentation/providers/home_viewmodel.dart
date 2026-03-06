import 'package:flutter/foundation.dart';
import 'package:fintrack/database/hive_service.dart';
import 'package:fintrack/features/expense/presentation/providers/expense_provider.dart';
import 'package:fintrack/features/budget/presentation/providers/budget_provider.dart';
import 'package:fintrack/features/investment/presentation/providers/investment_provider.dart';
import 'package:fintrack/features/loan/presentation/providers/loan_provider.dart';
import 'package:fintrack/features/accounts/presentation/providers/payment_account_provider.dart';
import 'package:fintrack/features/goals/presentation/providers/goal_provider.dart';
import 'package:fintrack/features/bill/presentation/providers/bill_provider.dart';
import 'package:fintrack/features/bill/data/models/bill_model.dart';

/// HomeViewModel: Single source of truth for Home screen data
/// All financial computations happen here, NOT in the UI
class HomeViewModel extends ChangeNotifier {
  // Dependencies
  final ExpenseProvider _expenseProvider;
  final BudgetProvider _budgetProvider;
  final InvestmentProvider _investmentProvider;
  final LoanProvider _loanProvider;
  final PaymentAccountProvider _accountProvider;
  final GoalProvider _goalProvider;
  final BillProvider _billProvider;

  // Cached computed values
  double _assets = 0;
  double _loans = 0;
  double _netWorth = 0;
  double _todaySpend = 0;
  double _monthlyBudget = 0;
  double _monthlySpent = 0;
  double _remainingBudget = 0;
  double _budgetUsagePercent = 0;
  double _savingsRate = 0;
  int _streak = 0;
  DateTime? _lastActivityDate;
  bool _isInactive = false;
  List<CategorySpending> _topCategories = [];
  List<String> _overspentCategories = [];
  List<AlertItem> _alerts = [];
  List<double> _netWorthHistory = []; // Last 3-6 months
  Bill? _nextDueBill; // Highest priority bill (≤3 days)
  int _urgentBillCount = 0; // Number of bills due ≤3 days
  double _assetInvestmentComponent = 0;
  double _assetAccountComponent = 0;
  double _investmentValue = 0;
  double _investmentCost = 0;
  double _investmentGainLoss = 0;
  double _investmentGainLossPercent = 0;
  bool _isDisposed = false;

  HomeViewModel({
    required ExpenseProvider expenseProvider,
    required BudgetProvider budgetProvider,
    required InvestmentProvider investmentProvider,
    required LoanProvider loanProvider,
    required PaymentAccountProvider accountProvider,
    required GoalProvider goalProvider,
    required BillProvider billProvider,
  })  : _expenseProvider = expenseProvider,
        _budgetProvider = budgetProvider,
        _investmentProvider = investmentProvider,
        _loanProvider = loanProvider,
        _accountProvider = accountProvider,
        _goalProvider = goalProvider,
        _billProvider = billProvider {
    _listenToProviders();
    _computeAll();
  }

  // Getters
  double get assets => _assets;
  double get loans => _loans;
  double get netWorth => _netWorth;
  double get todaySpend => _todaySpend;
  double get monthlyBudget => _monthlyBudget;
  double get monthlySpent => _monthlySpent;
  double get remainingBudget => _remainingBudget;
  double get budgetUsagePercent => _budgetUsagePercent;
  double get savingsRate => _savingsRate;
  int get streak => _streak;
  bool get isInactive => _isInactive;
  bool get hasBudget => _monthlyBudget > 0;
  bool get isBudgetCritical => _budgetUsagePercent >= 0.8;
  bool get isBudgetExceeded => _budgetUsagePercent > 1.0;
  List<CategorySpending> get topCategories => _topCategories;
  List<String> get overspentCategories => _overspentCategories;
  List<AlertItem> get alerts => _alerts;
  bool get hasGoals => _goalProvider.activeGoals.isNotEmpty;
  List<double> get netWorthHistory => _netWorthHistory;
  Bill? get nextDueBill => _nextDueBill;
  int get urgentBillCount => _urgentBillCount;
  double get assetInvestmentComponent => _assetInvestmentComponent;
  double get assetAccountComponent => _assetAccountComponent;
  double get investmentValue => _investmentValue;
  double get investmentCost => _investmentCost;
  double get investmentGainLoss => _investmentGainLoss;
  double get investmentGainLossPercent => _investmentGainLossPercent;
  int get pendingBillReminderCount =>
      _billProvider.getPendingReminders().length;

  void _listenToProviders() {
    _expenseProvider.addListener(_computeAll);
    _budgetProvider.addListener(_computeAll);
    _investmentProvider.addListener(_onInvestmentChanged);
    _loanProvider.addListener(_computeAll);
    _accountProvider.addListener(_computeAll);
    _goalProvider.addListener(_computeAll);
    _billProvider.addListener(_computeAll);
  }

  void _onInvestmentChanged() {
    if (_isDisposed) return;
    _computeSnapshot();
    _computeInvestments();
    notifyListeners();
  }

  void _computeAll() {
    if (_isDisposed) return;
    _computeSnapshot();
    _computeNetWorthHistory();
    _computeBills();
    _computeInvestments();
    _computeBudget();
    _computeTopCategories();
    _computeStreak();
    _computeAlerts();
    _checkInactivity();
    notifyListeners();
  }

  void _computeSnapshot() {
    // Assets = Investments + Non-credit account balances
    _assetInvestmentComponent = _getEffectiveInvestmentValueFromStore();
    _assetAccountComponent = _getAssetAccountBalance();

    _assets = _assetInvestmentComponent + _assetAccountComponent;

    // Loans = Total outstanding
    _loans = _loanProvider.getTotalOutstandingAmount();

    // Net Worth
    _netWorth = _assets - _loans;

    // Today's spend
    final now = DateTime.now();
    final todayExpenses = HiveService.getAllExpenses().where((expense) {
      final transactionType = expense.transactionType ?? 'expense';
      return expense.date.year == now.year &&
          expense.date.month == now.month &&
          expense.date.day == now.day &&
          (transactionType == 'expense' || transactionType == 'payment');
    });
    _todaySpend = todayExpenses.fold<double>(0, (sum, e) => sum + e.amount);
  }

  double _getEffectiveInvestmentValueFromStore() {
    final investments = HiveService.getAllInvestments();

    return investments.fold<double>(0, (sum, investment) {
      final marketValue = investment.getCurrentValue();
      final investedCost = investment.getTotalInvestmentValue();
      final effectiveValue =
          (marketValue <= 0 && investedCost > 0) ? investedCost : marketValue;
      return sum + effectiveValue;
    });
  }

  double _getAssetAccountBalance() {
    return _accountProvider.activeAccounts.fold<double>(0, (sum, account) {
      final isCredit = account.accountType.toLowerCase().contains('credit');
      if (isCredit) return sum;
      return sum + account.balance;
    });
  }

  double _getInvestmentCostFromStore() {
    final investments = HiveService.getAllInvestments();
    return investments.fold<double>(
      0,
      (sum, investment) => sum + investment.getTotalInvestmentValue(),
    );
  }

  void _computeBudget() {
    final now = DateTime.now();
    final budget = _budgetProvider.getBudgetForMonth(now.month, now.year);

    if (budget != null) {
      _monthlyBudget = budget.categoryLimits.values
          .fold<double>(0, (sum, amount) => sum + amount);
    } else {
      _monthlyBudget = 0;
    }

    _monthlySpent = _expenseProvider.getTotalMonthlyExpense();
    _remainingBudget =
        (_monthlyBudget - _monthlySpent).clamp(0, double.infinity);
    _budgetUsagePercent =
        _monthlyBudget > 0 ? _monthlySpent / _monthlyBudget : 0;

    // Savings rate = (Income - Expenses) / Income
    // For now, simplified as budget compliance
    if (_monthlyBudget > 0) {
      _savingsRate = ((_monthlyBudget - _monthlySpent) / _monthlyBudget * 100)
          .clamp(0, 100);
    } else {
      _savingsRate = 0;
    }

    // Overspent categories
    if (budget != null) {
      _overspentCategories = [];
      final now = DateTime.now();
      final monthExpenses = HiveService.getAllExpenses().where((e) {
        return e.date.year == now.year && e.date.month == now.month;
      }).where((e) {
        final transactionType = e.transactionType ?? 'expense';
        return transactionType == 'expense' || transactionType == 'payment';
      }).toList();

      budget.categoryLimits.forEach((category, limit) {
        final spent = monthExpenses
            .where((e) => e.category == category)
            .fold<double>(0, (sum, e) => sum + e.amount);
        if (spent > limit) {
          _overspentCategories.add(category);
        }
      });

      // Sort by severity, show top 3
      _overspentCategories.take(3).toList();
    }
  }

  void _computeTopCategories() {
    final now = DateTime.now();
    final monthExpenses = HiveService.getAllExpenses().where((e) {
      return e.date.year == now.year && e.date.month == now.month;
    }).where((e) {
      final transactionType = e.transactionType ?? 'expense';
      return transactionType == 'expense' || transactionType == 'payment';
    }).toList();

    final categoryTotals = <String, double>{};
    for (var expense in monthExpenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    _topCategories = sorted.take(4).map((e) {
      final budget = _budgetProvider.getBudgetForMonth(now.month, now.year);
      final limit = budget?.categoryLimits[e.key] ?? 0;
      final percent =
          (limit > 0 ? (e.value / limit).clamp(0.0, 1.0) : 0.0) as double;

      return CategorySpending(
        category: e.key,
        amount: e.value,
        budgetLimit: limit,
        percentage: percent,
      );
    }).toList();
  }

  void _computeStreak() {
    // Get all transactions (expenses + income) sorted by date
    final allTransactions = HiveService.getAllExpenses()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (allTransactions.isEmpty) {
      _streak = 0;
      _lastActivityDate = null;
      return;
    }

    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    var currentDate = todayStart;
    var streakCount = 0;

    // Check if there's activity today or yesterday
    final latestActivity = allTransactions.first.date;
    final latestActivityDay = DateTime(
      latestActivity.year,
      latestActivity.month,
      latestActivity.day,
    );

    final daysSinceActivity = todayStart.difference(latestActivityDay).inDays;

    if (daysSinceActivity > 1) {
      // Streak broken
      _streak = 0;
      _lastActivityDate = latestActivity;
      return;
    }

    // Count consecutive days with transactions
    while (true) {
      final hasActivityOnDate = allTransactions.any((t) {
        final tDate = DateTime(t.date.year, t.date.month, t.date.day);
        return tDate.isAtSameMomentAs(currentDate);
      });

      if (!hasActivityOnDate) break;

      streakCount++;
      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    _streak = streakCount;
    _lastActivityDate = allTransactions.first.date;
  }

  void _checkInactivity() {
    if (_lastActivityDate == null) {
      _isInactive = true;
      return;
    }

    final now = DateTime.now();
    final daysSinceActivity = now.difference(_lastActivityDate!).inDays;
    _isInactive = daysSinceActivity >= 7;
  }

  void _computeAlerts() {
    _alerts = [];

    // Pending bill reminders alerts
    final pendingReminders = _billProvider.getPendingReminders();
    final now = DateTime.now();

    // Sort by due date - closest due dates first
    pendingReminders.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    // Add pending bill reminders as alerts (prioritize by due date)
    for (var reminder in pendingReminders) {
      final daysUntilDue = reminder.getDaysUntilDue();

      // Skip if due date is in the past (shouldn't happen, but safety check)
      if (daysUntilDue < 0) continue;

      // Determine severity based on days until due
      final severity = daysUntilDue == 0
          ? AlertSeverity.high
          : daysUntilDue <= 3
              ? AlertSeverity.medium
              : AlertSeverity.low;

      _alerts.add(AlertItem(
        type: AlertType.billDue,
        message:
            '${reminder.name} - Due in ${daysUntilDue == 0 ? "today" : "$daysUntilDue day(s)"}',
        severity: severity,
      ));
    }

    // Bill due alerts (overdue bills)
    final overdueBills = _billProvider.overdueBills;
    if (overdueBills.isNotEmpty) {
      _alerts.add(AlertItem(
        type: AlertType.billDue,
        message: '${overdueBills.length} bill(s) overdue',
        severity: AlertSeverity.high,
      ));
    }

    // EMI due alerts (from loans)
    final upcomingEMIs = HiveService.getAllLoans().where((loan) {
      final nextEMI = loan.nextEmiDate;
      if (nextEMI == null) return false;
      final daysUntilEMI = nextEMI.difference(now).inDays;
      return daysUntilEMI >= 0 && daysUntilEMI <= 3;
    });

    if (upcomingEMIs.isNotEmpty) {
      _alerts.add(AlertItem(
        type: AlertType.emiDue,
        message: '${upcomingEMIs.length} EMI(s) due soon',
        severity: AlertSeverity.medium,
      ));
    }

    // Limit to 3 most important alerts - prioritize by severity and due date
    _alerts.sort((a, b) {
      // High severity first, then medium, then low
      final severityOrder = {
        AlertSeverity.high: 0,
        AlertSeverity.medium: 1,
        AlertSeverity.low: 2
      };
      final severityDiff = (severityOrder[a.severity] ?? 3)
          .compareTo(severityOrder[b.severity] ?? 3);
      return severityDiff;
    });

    _alerts = _alerts.take(3).toList();
  }

  void _computeNetWorthHistory() {
    // Get last 6 months of net worth trend (simplified)
    _netWorthHistory = [];

    // For now, use current net worth as baseline
    // This provides a placeholder; ideally you'd track monthly snapshots
    final baseNetWorth = _netWorth;

    // Create a simple trend: slight variations to simulate history
    for (int i = 5; i >= 0; i--) {
      // Simple trend: gradually increase to current value
      final trendValue = baseNetWorth * (0.8 + (0.2 * (5 - i) / 5));
      _netWorthHistory.add(trendValue);
    }
  }

  void _computeBills() {
    // Find urgent bills (due ≤3 days)
    final allBills = _billProvider.bills.where((bill) => !bill.isPaid).toList();

    final urgentBills = allBills.where((bill) {
      final daysUntilDue = bill.getDaysUntilDue();
      return daysUntilDue >= 0 && daysUntilDue <= 3;
    }).toList();

    if (urgentBills.isNotEmpty) {
      // Sort by daysUntilDue (ascending)
      urgentBills
          .sort((a, b) => a.getDaysUntilDue().compareTo(b.getDaysUntilDue()));
      _nextDueBill = urgentBills.first;
      _urgentBillCount = urgentBills.length;
    } else {
      _nextDueBill = null;
      _urgentBillCount = 0;
    }
  }

  void _computeInvestments() {
    // Calculate investment summary
    _investmentValue = _getEffectiveInvestmentValueFromStore();
    _investmentCost = _getInvestmentCostFromStore();

    _investmentGainLoss = _investmentValue - _investmentCost;
    _investmentGainLossPercent =
        _investmentCost > 0 ? (_investmentGainLoss / _investmentCost) * 100 : 0;
  }

  Future<void> refresh() async {
    if (_isDisposed) return;
    // Refresh investments FIRST - critical for assets calculation
    await _investmentProvider.initInvestments();

    // Then refresh other providers
    _expenseProvider.refreshData();
    _budgetProvider.refreshData();
    _accountProvider.refreshData();
    _goalProvider.refreshData();
    await _loanProvider.initLoans();
    await _billProvider.refreshData();

    // Recompute everything with fresh data
    _computeAll();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _expenseProvider.removeListener(_computeAll);
    _budgetProvider.removeListener(_computeAll);
    _investmentProvider.removeListener(_onInvestmentChanged);
    _loanProvider.removeListener(_computeAll);
    _accountProvider.removeListener(_computeAll);
    _goalProvider.removeListener(_computeAll);
    _billProvider.removeListener(_computeAll);
    super.dispose();
  }
}

// Data models
class CategorySpending {
  final String category;
  final double amount;
  final double budgetLimit;
  final double percentage;

  CategorySpending({
    required this.category,
    required this.amount,
    required this.budgetLimit,
    required this.percentage,
  });
}

class AlertItem {
  final AlertType type;
  final String message;
  final AlertSeverity severity;

  AlertItem({
    required this.type,
    required this.message,
    required this.severity,
  });
}

enum AlertType { budgetExceeded, budgetWarning, billDue, emiDue }

enum AlertSeverity { low, medium, high }
