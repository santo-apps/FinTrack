import '../database/hive_service.dart';

class AnalyticsService {
  // Calculate monthly spending trend
  static Map<int, double> getMonthlySpendingTrend(int months) {
    final trend = <int, double>{};
    final expenses = HiveService.getAllExpenses();
    final now = DateTime.now();

    for (int i = 0; i < months; i++) {
      final month = now.month - i;
      final year = now.year + (month > 0 ? 0 : -1);
      final adjustedMonth = month > 0 ? month : month + 12;

      double monthTotal = 0;
      for (var expense in expenses) {
        if (expense.date.month == adjustedMonth && expense.date.year == year) {
          monthTotal += expense.amount;
        }
      }

      trend[adjustedMonth] = monthTotal;
    }

    return trend;
  }

  // Detect overspending categories
  static List<OverspendingAlert> detectOverspendingCategories() {
    final alerts = <OverspendingAlert>[];
    final now = DateTime.now();
    final budget = HiveService.getBudgetForMonth(now.month, now.year);
    if (budget == null) return alerts;

    final expenses = HiveService.getAllExpenses();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final categorySpending = <String, double>{};
    for (var expense in expenses) {
      if (expense.date.isAfter(monthStart) && expense.date.isBefore(monthEnd)) {
        categorySpending[expense.category] =
            (categorySpending[expense.category] ?? 0) + expense.amount;
      }
    }

    categorySpending.forEach((category, amount) {
      final limit = budget.categoryLimits[category] ?? 0;
      if (limit > 0 && amount > limit) {
        alerts.add(OverspendingAlert(
          category: category,
          limit: limit,
          spent: amount,
          percentage: ((amount / limit) * 100).clamp(0, 300),
        ));
      }
    });

    return alerts..sort((a, b) => b.percentage.compareTo(a.percentage));
  }

  // Calculate net worth
  static Map<String, double> calculateNetWorth() {
    final investments = HiveService.getAllInvestments();
    final debts = HiveService.getAllDebts();

    double totalAssets = 0;
    for (var investment in investments) {
      totalAssets += investment.getCurrentValue();
    }

    double totalLiabilities = 0;
    for (var debt in debts) {
      totalLiabilities += debt.remainingBalance;
    }

    return {
      'assets': totalAssets,
      'liabilities': totalLiabilities,
      'netWorth': totalAssets - totalLiabilities,
    };
  }

  // Calculate net worth with comprehensive asset/liability breakdown
  static Map<String, dynamic> calculateDetailedNetWorth(
    double investmentValue,
    double accountBalance,
    double loanOutstanding,
    double creditCardBalance,
    double unpaidBillsAmount,
  ) {
    // Assets = investments + bank accounts + wallets
    double totalAssets = investmentValue + accountBalance;

    // Liabilities = loans + credit card balances + unpaid bills
    double totalLiabilities =
        loanOutstanding + creditCardBalance + unpaidBillsAmount;

    return {
      'assets': totalAssets,
      'liabilities': totalLiabilities,
      'netWorth': totalAssets - totalLiabilities,
      'investmentValue': investmentValue,
      'accountBalance': accountBalance,
      'loanOutstanding': loanOutstanding,
      'creditCardBalance': creditCardBalance,
      'unpaidBillsAmount': unpaidBillsAmount,
    };
  }

  // Calculate monthly subscription total
  static double getMonthlySubscriptionTotal() {
    final subscriptions = HiveService.getAllSubscriptions();
    return subscriptions.fold<double>(
        0, (sum, sub) => sum + sub.getMonthlyAmount());
  }

  // Calculate savings rate
  static double calculateSavingsRate() {
    final now = DateTime.now();
    final budget = HiveService.getBudgetForMonth(now.month, now.year);
    if (budget == null) return 0;

    final expenses = HiveService.getAllExpenses();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    double monthTotal = 0;
    for (var expense in expenses) {
      if (expense.date.isAfter(monthStart) && expense.date.isBefore(monthEnd)) {
        monthTotal += expense.amount;
      }
    }

    final totalBudget =
        budget.categoryLimits.values.fold<double>(0, (sum, v) => sum + v);
    if (totalBudget == 0) return 0;
    final remaining = totalBudget - monthTotal;
    return ((remaining / totalBudget) * 100).clamp(0, 100);
  }

  // Category spending breakdown
  static Map<String, double> getCategoryBreakdown() {
    final expenses = HiveService.getAllExpenses();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final breakdown = <String, double>{};
    for (var expense in expenses) {
      if (expense.date.isAfter(monthStart) && expense.date.isBefore(monthEnd)) {
        breakdown[expense.category] =
            (breakdown[expense.category] ?? 0) + expense.amount;
      }
    }

    return breakdown;
  }
}

class OverspendingAlert {
  final String category;
  final double limit;
  final double spent;
  final double percentage;

  OverspendingAlert({
    required this.category,
    required this.limit,
    required this.spent,
    required this.percentage,
  });
}
