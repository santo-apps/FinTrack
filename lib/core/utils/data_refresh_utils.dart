import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/features/accounts/presentation/providers/payment_account_provider.dart';
import 'package:fintrack/features/bill/presentation/providers/bill_provider.dart';
import 'package:fintrack/features/budget/presentation/providers/budget_provider.dart';
import 'package:fintrack/features/debt/presentation/providers/debt_provider.dart';
import 'package:fintrack/features/expense/presentation/providers/expense_provider.dart';
import 'package:fintrack/features/goals/presentation/providers/goal_provider.dart';
import 'package:fintrack/features/investment/presentation/providers/investment_provider.dart';
import 'package:fintrack/features/loan/presentation/providers/loan_provider.dart';
import 'package:fintrack/features/receivable/presentation/providers/receivable_provider.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';
import 'package:fintrack/features/subscription/presentation/providers/subscription_provider.dart';

class DataRefreshUtils {
  DataRefreshUtils._();

  static Future<void> refreshAllAndSignal(BuildContext context) async {
    final expenseProvider = context.read<ExpenseProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    final subscriptionProvider = context.read<SubscriptionProvider>();
    final investmentProvider = context.read<InvestmentProvider>();
    final goalProvider = context.read<GoalProvider>();
    final loanProvider = context.read<LoanProvider>();
    final billProvider = context.read<BillProvider>();
    final debtProvider = context.read<DebtProvider>();
    final receivableProvider = context.read<ReceivableProvider>();
    final paymentAccountProvider = context.read<PaymentAccountProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    await expenseProvider.refreshData();
    await budgetProvider.refreshData();
    await subscriptionProvider.refreshData();
    await investmentProvider.refreshData();
    await goalProvider.refreshData();
    await loanProvider.refreshData();
    await billProvider.refreshData();
    await debtProvider.refreshData();
    await receivableProvider.refreshData();
    paymentAccountProvider.refreshData();
    await settingsProvider.refreshSettings();
    settingsProvider.bumpDataRefreshVersion();
  }
}
