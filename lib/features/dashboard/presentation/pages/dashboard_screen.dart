import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/core/constants/app_constants.dart';
import 'package:fintrack/features/expense/presentation/providers/expense_provider.dart';
import 'package:fintrack/features/budget/presentation/providers/budget_provider.dart';
import 'package:fintrack/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:fintrack/features/investment/presentation/providers/investment_provider.dart';
import 'package:fintrack/features/goals/presentation/providers/goal_provider.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';
import 'package:fintrack/features/loan/presentation/providers/loan_provider.dart';
import 'package:fintrack/features/bill/presentation/providers/bill_provider.dart';
import 'package:fintrack/features/accounts/presentation/providers/payment_account_provider.dart';
import 'package:fintrack/services/analytics_service.dart';
import 'package:fintrack/features/expense/presentation/pages/expense_list_screen.dart';
import 'package:fintrack/features/budget/presentation/pages/budget_planner_screen.dart';
import 'package:fintrack/features/subscription/presentation/pages/subscription_list_screen.dart';
import 'package:fintrack/features/investment/presentation/pages/investment_portfolio_screen.dart';
import 'package:fintrack/features/goals/presentation/pages/goal_tracker_screen.dart';
import 'package:fintrack/features/loan/presentation/pages/loan_tracker_screen.dart';
import 'package:fintrack/features/bill/presentation/pages/bill_list_screen.dart';
import 'package:fintrack/features/accounts/presentation/pages/account_list_screen.dart';
import 'package:fintrack/features/settings/presentation/pages/settings_navigation_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _overviewCards = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    if (mounted) {
      _animationController.reset();
      _animationController.forward();
      context.read<ExpenseProvider>().refreshData();
      context.read<BudgetProvider>().refreshData();
      context.read<SubscriptionProvider>().refreshData();
      context.read<InvestmentProvider>().refreshData();
      context.read<GoalProvider>().refreshData();
      await context.read<LoanProvider>().initLoans();
      await context.read<BillProvider>().refreshData();
      context.read<PaymentAccountProvider>().refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.watch<SettingsProvider>().currencySymbol;
    final loanProvider = context.watch<LoanProvider>();
    final billProvider = context.watch<BillProvider>();
    final accountProvider = context.watch<PaymentAccountProvider>();
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: Consumer5<ExpenseProvider, BudgetProvider, SubscriptionProvider,
          InvestmentProvider, GoalProvider>(
        builder: (context, expenseProvider, budgetProvider,
            subscriptionProvider, investmentProvider, goalProvider, _) {
          final monthlyExpense = expenseProvider.getTotalMonthlyExpense();
          final now = DateTime.now();
          final budget = budgetProvider.getBudgetForMonth(now.month, now.year);
          final totalBudget = budget?.categoryLimits.values
                  .fold<double>(0, (sum, amount) => sum + amount) ??
              0;
          final portfolioValue = investmentProvider.getTotalPortfolioValue();
          final totalAccountBalance = accountProvider.getTotalBalance();
          final totalCreditCardBalance =
              accountProvider.getTotalCreditCardBalance();
          final totalLoansOutstanding =
              loanProvider.getTotalOutstandingAmount();
          final totalUnpaidBillsAmount =
              billProvider.getTotalUnpaidBillsAmount();
          final netWorth = AnalyticsService.calculateDetailedNetWorth(
            portfolioValue,
            totalAccountBalance,
            totalLoansOutstanding,
            totalCreditCardBalance,
            totalUnpaidBillsAmount,
          );
          final monthlySubscriptions =
              subscriptionProvider.getMonthlySubscriptionTotal();
          final budgetUsage = budget != null && totalBudget > 0
              ? (monthlyExpense / totalBudget).clamp(0, 1)
              : 0.0;

          // All available overview items
          final allOverviewItems = <String, _OverviewItem>{
            'monthly_spending': _OverviewItem(
              icon: Icons.trending_down,
              label: 'Monthly Spending',
              value: AppUtils.formatCurrency(
                monthlyExpense,
                currencySymbol: currencySymbol,
              ),
              accentColor: const Color(0xFFD64545),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ExpenseListScreen(
                      showAppBar: true,
                      showBackButton: true,
                    ),
                  ),
                );
              },
            ),
            'subscriptions': _OverviewItem(
              icon: Icons.subscriptions,
              label: 'Subscriptions',
              value: AppUtils.formatCurrency(
                monthlySubscriptions,
                currencySymbol: currencySymbol,
              ),
              accentColor: const Color(0xFF1C5D99),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionListScreen(
                      showAppBar: true,
                      showBackButton: true,
                    ),
                  ),
                );
              },
            ),
            'portfolio_value': _OverviewItem(
              icon: Icons.trending_up,
              label: 'Portfolio Value',
              value: AppUtils.formatCurrency(
                portfolioValue,
                currencySymbol: currencySymbol,
              ),
              accentColor: const Color(0xFFB95000),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const InvestmentPortfolioScreen(
                      showAppBar: true,
                      showBackButton: true,
                    ),
                  ),
                );
              },
            ),
            'total_balance': _OverviewItem(
              icon: Icons.account_balance_wallet,
              label: 'Total Balance',
              value: AppUtils.formatCurrency(
                totalAccountBalance,
                currencySymbol: currencySymbol,
              ),
              accentColor: const Color(0xFF2E7D32),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        const AccountListScreen(showBackButton: true),
                  ),
                );
              },
            ),
            'outstanding_loans': _OverviewItem(
              icon: Icons.account_balance,
              label: 'Outstanding Loans',
              value: AppUtils.formatCurrency(
                totalLoansOutstanding,
                currencySymbol: currencySymbol,
              ),
              accentColor: const Color(0xFF7B1E3A),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LoanTrackerScreen(
                      showAppBar: true,
                      showBackButton: true,
                    ),
                  ),
                );
              },
            ),
            'unpaid_bills': _OverviewItem(
              icon: Icons.calendar_today,
              label: 'Unpaid Bills',
              value: AppUtils.formatCurrency(
                totalUnpaidBillsAmount,
                currencySymbol: currencySymbol,
              ),
              accentColor: const Color(0xFF9A6B00),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BillListScreen(
                      showAppBar: true,
                      showBackButton: true,
                    ),
                  ),
                );
              },
            ),
          };

          // Get settings provider for user preferences
          final settingsProvider = context.watch<SettingsProvider>();

          // Filter and order overview items based on user preferences
          final overviewItems = settingsProvider.overviewItems
              .where((id) => allOverviewItems.containsKey(id))
              .map((id) => allOverviewItems[id]!)
              .toList();

          // All available quick actions
          final allQuickActions = <String, _QuickActionItem>{
            'expenses': _QuickActionItem(
              icon: Icons.receipt_long,
              label: 'Expenses',
              color: const Color(0xFF2D2A4A),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ExpenseListScreen(
                      showAppBar: true,
                      showBackButton: true,
                    ),
                  ),
                );
              },
            ),
            'accounts': _QuickActionItem(
              icon: Icons.account_balance_wallet,
              label: 'Accounts',
              color: const Color(0xFF0C6E62),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        const AccountListScreen(showBackButton: true),
                  ),
                );
              },
            ),
            'budget': _QuickActionItem(
              icon: Icons.pie_chart,
              label: 'Budget',
              color: const Color(0xFF5E2B97),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BudgetPlannerScreen(
                      showAppBar: true,
                      showBackButton: true,
                    ),
                  ),
                );
              },
            ),
            'bills': _QuickActionItem(
              icon: Icons.calendar_today,
              label: 'Bills',
              color: const Color(0xFFB95C00),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BillListScreen(
                      showAppBar: true,
                      showBackButton: true,
                    ),
                  ),
                );
              },
            ),
            'subscriptions': _QuickActionItem(
              icon: Icons.subscriptions,
              label: 'Subscriptions',
              color: const Color(0xFF6A1B9A),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionListScreen(
                      showAppBar: true,
                      showBackButton: true,
                    ),
                  ),
                );
              },
            ),
            'investments': _QuickActionItem(
              icon: Icons.trending_up,
              label: 'Investments',
              color: const Color(0xFF00796B),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const InvestmentPortfolioScreen(
                      showAppBar: true,
                      showBackButton: true,
                    ),
                  ),
                );
              },
            ),
            'goals': _QuickActionItem(
              icon: Icons.flag_outlined,
              label: 'Goals',
              color: const Color(0xFFC62828),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GoalTrackerScreen(
                      showAppBar: true,
                      showBackButton: true,
                    ),
                  ),
                );
              },
            ),
            'loans': _QuickActionItem(
              icon: Icons.account_balance,
              label: 'Loans',
              color: const Color(0xFF4527A0),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LoanTrackerScreen(
                      showAppBar: true,
                      showBackButton: true,
                    ),
                  ),
                );
              },
            ),
          };

          // Get selected quick actions from settings
          final quickActions = <_QuickActionItem>[];
          for (final actionId in settingsProvider.quickActionItems) {
            if (allQuickActions.containsKey(actionId)) {
              quickActions.add(allQuickActions[actionId]!);
            }
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Animated Header
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.2),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.easeOut,
                  )),
                  child: Text(
                    'Welcome Back!',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Hero Net Worth Card
                ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeOut,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.accentColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -20,
                          right: -20,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.12),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -10,
                          left: -10,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Financial Summary',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Net Worth',
                                      style: GoogleFonts.poppins(
                                        fontSize: 7,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              FadeTransition(
                                opacity: Tween<double>(begin: 0, end: 1)
                                    .animate(CurvedAnimation(
                                  parent: _animationController,
                                  curve: const Interval(0.3, 0.8),
                                )),
                                child: Text(
                                  AppUtils.formatCurrency(
                                    netWorth['netWorth'] ?? 0,
                                    currencySymbol: currencySymbol,
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _NetWorthItem(
                                    label: 'Assets',
                                    value: AppUtils.formatCurrency(
                                      netWorth['assets'] ?? 0,
                                      currencySymbol: currencySymbol,
                                    ),
                                  ),
                                  Container(
                                    width: 0.5,
                                    height: 28,
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                  _NetWorthItem(
                                    label: 'Liabilities',
                                    value: AppUtils.formatCurrency(
                                      netWorth['liabilities'] ?? 0,
                                      currencySymbol: currencySymbol,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Financial Overview
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Financial Overview',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 16),
                          tooltip: 'Customize financial overview',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SettingsNavigationScreen(
                                  initialTab: 2,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    ToggleButtons(
                      isSelected: [_overviewCards, !_overviewCards],
                      onPressed: (index) {
                        setState(() {
                          _overviewCards = index == 0;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      constraints:
                          const BoxConstraints(minHeight: 32, minWidth: 36),
                      children: const [
                        Icon(Icons.view_module, size: 18),
                        Icon(Icons.view_list, size: 18),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: _overviewCards
                      ? _buildOverviewCards(overviewItems)
                      : _buildOverviewList(overviewItems),
                ),
                const SizedBox(height: 12),

                // Quick Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quick Actions',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      tooltip: 'Customize quick actions',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const SettingsNavigationScreen(
                              initialTab: 1,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildQuickActions(quickActions),
                const SizedBox(height: 8),

                // Budget Progress
                Text(
                  'Budget Status',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const BudgetPlannerScreen(
                          showAppBar: true,
                          showBackButton: true,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: budget != null
                          ? Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Budget Used',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            color: AppTheme.textSecondaryColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '${(budgetUsage * 100).toStringAsFixed(1)}%',
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: budgetUsage > 0.8
                                                ? AppTheme.errorColor
                                                : AppTheme.successColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      width: 50,
                                      height: 50,
                                      child: _CircularProgressIndicator(
                                        value: budgetUsage.toDouble(),
                                        size: 50,
                                        strokeWidth: 3.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Divider(
                                  color: AppTheme.borderColor,
                                  height: 1,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Spending: ${AppUtils.formatCurrency(monthlyExpense, currencySymbol: currencySymbol)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                    ),
                                    Text(
                                      'Budget: ${AppUtils.formatCurrency(totalBudget, currencySymbol: currencySymbol)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : SizedBox(
                              width: double.infinity,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.pie_chart_outline,
                                    size: 40,
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.6),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No Budget Set',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap to create your monthly budget',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Goals Section
                if (goalProvider.activeGoals.isNotEmpty) ...[
                  Text(
                    'Financial Goals',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const GoalTrackerScreen(
                            showAppBar: true,
                            showBackButton: true,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Overall Progress',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: AppTheme.textSecondaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${goalProvider.getOverallProgressPercentage().toStringAsFixed(1)}%',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: _CircularProgressIndicator(
                                    value: goalProvider
                                            .getOverallProgressPercentage() /
                                        100,
                                    size: 50,
                                    strokeWidth: 3.5,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Divider(
                              color: AppTheme.borderColor,
                              height: 1,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${goalProvider.activeGoals.length} active goal${goalProvider.activeGoals.length > 1 ? 's' : ''}',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewCards(List<_OverviewItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map(
                (item) => SizedBox(
                  width: cardWidth,
                  child: _OverviewCard(item: item),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildOverviewList(List<_OverviewItem> items) {
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OverviewListItem(item: item),
            ),
          )
          .toList(),
    );
  }

  Widget _buildQuickActions(List<_QuickActionItem> actions) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return _QuickActionTile(item: actions[index]);
        },
      ),
    );
  }
}

class _OverviewItem {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final VoidCallback onTap;

  const _OverviewItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.onTap,
  });
}

class _OverviewCard extends StatelessWidget {
  final _OverviewItem item;

  const _OverviewCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: item.accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.icon,
                color: item.accentColor,
                size: 18,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              item.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: item.accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewListItem extends StatelessWidget {
  final _OverviewItem item;

  const _OverviewListItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.icon,
                color: item.accentColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item.value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: item.accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionTile extends StatelessWidget {
  final _QuickActionItem item;

  const _QuickActionTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: item.color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: item.color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.icon,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NetWorthItem extends StatelessWidget {
  final String label;
  final String value;

  const _NetWorthItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 8,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final AnimationController animationController;
  final int index;
  final IconData icon;
  final String label;
  final String value;
  final Color color1;
  final Color color2;
  final VoidCallback? onTap;

  const _FeatureCard({
    required this.animationController,
    required this.index,
    required this.icon,
    required this.label,
    required this.value,
    required this.color1,
    required this.color2,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Animation<Offset> slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(0.1 * index, 0.1 * index + 0.4, curve: Curves.easeOut),
      ),
    );

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: animationController,
            curve: Interval(0.1 * index, 0.1 * index + 0.4),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color1, color2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: color1.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              value,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircularProgressIndicator extends StatelessWidget {
  final double value;
  final double size;
  final double strokeWidth;
  final Color? color;

  const _CircularProgressIndicator({
    required this.value,
    required this.size,
    required this.strokeWidth,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final Color progressColor = color ?? AppTheme.accentColor;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: progressColor.withOpacity(0.1),
          ),
        ),
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: value.clamp(0, 1),
            strokeWidth: strokeWidth,
            backgroundColor: progressColor.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
      ],
    );
  }
}
