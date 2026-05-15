import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/core/constants/app_constants.dart';
import 'package:fintrack/database/hive_service.dart';
import 'package:fintrack/features/dashboard/presentation/providers/home_viewmodel.dart';
import 'package:fintrack/features/dashboard/presentation/pages/networth_breakdown_screen.dart';
import 'package:fintrack/features/accounts/presentation/pages/account_list_screen.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';
import 'package:fintrack/features/loan/presentation/pages/loan_tracker_screen.dart';
import 'package:fintrack/features/budget/presentation/pages/budget_planner_screen.dart';
import 'package:fintrack/features/goals/presentation/pages/goal_tracker_screen.dart';
import 'package:fintrack/features/bill/presentation/pages/bill_list_screen.dart';
import 'package:fintrack/features/investment/presentation/pages/investment_portfolio_screen.dart';
import 'package:fintrack/features/expense/presentation/pages/expense_list_screen.dart';
import 'package:fintrack/features/subscription/presentation/pages/subscription_list_screen.dart';
import 'package:fintrack/features/settings/presentation/pages/settings_screen.dart';
import 'package:fintrack/core/utils/custom_widgets.dart';
import 'package:fintrack/features/expense/presentation/providers/expense_provider.dart';
import 'package:fintrack/features/budget/presentation/providers/budget_provider.dart';
import 'package:fintrack/features/investment/presentation/providers/investment_provider.dart';
import 'package:fintrack/features/loan/presentation/providers/loan_provider.dart';
import 'package:fintrack/features/accounts/presentation/providers/payment_account_provider.dart';
import 'package:fintrack/features/goals/presentation/providers/goal_provider.dart';
import 'package:fintrack/features/bill/presentation/providers/bill_provider.dart';
import 'package:fintrack/features/receivable/presentation/providers/receivable_provider.dart';
import 'package:fintrack/features/receivable/presentation/pages/receivable_list_screen.dart';
import 'package:fintrack/features/subscription/presentation/providers/subscription_provider.dart';

/// DashboardScreen: Premium financial control center
/// Clean, calm, structured – manual discipline MVP
class DashboardScreen extends StatelessWidget {
  final int refreshToken;

  const DashboardScreen({super.key, this.refreshToken = 0});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey('dashboard_vm_$refreshToken'),
      create: (context) => HomeViewModel(
        expenseProvider: Provider.of<ExpenseProvider>(context, listen: false),
        budgetProvider: Provider.of<BudgetProvider>(context, listen: false),
        investmentProvider:
            Provider.of<InvestmentProvider>(context, listen: false),
        loanProvider: Provider.of<LoanProvider>(context, listen: false),
        accountProvider:
            Provider.of<PaymentAccountProvider>(context, listen: false),
        goalProvider: Provider.of<GoalProvider>(context, listen: false),
        billProvider: Provider.of<BillProvider>(context, listen: false),
        receivableProvider:
            Provider.of<ReceivableProvider>(context, listen: false),
      ),
      child: const _DashboardScreenContent(),
    );
  }
}

class _DashboardScreenContent extends StatefulWidget {
  const _DashboardScreenContent();

  @override
  State<_DashboardScreenContent> createState() =>
      _DashboardScreenContentState();
}

class _DashboardScreenContentState extends State<_DashboardScreenContent>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _netWorthAnimationController;
  double _previousNetWorth =
      -1; // Initialize to -1 to trigger animation on first load

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _netWorthAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(0); // Reset to top
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _netWorthAnimationController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final viewModel = context.read<HomeViewModel>();
    await viewModel.refresh();
  }

  bool _isOnboardingStepComplete(String key) {
    return HiveService.getSetting(key, defaultValue: false) == true;
  }

  List<_SetupTask> _buildSetupTasks({
    required PaymentAccountProvider accountProvider,
    required GoalProvider goalProvider,
    required BudgetProvider budgetProvider,
    required InvestmentProvider investmentProvider,
    required LoanProvider loanProvider,
    required SettingsProvider settingsProvider,
    required SubscriptionProvider subscriptionProvider,
  }) {
    // Helper: Check if task is complete by flag OR if data exists
    bool isTaskComplete(String flag, bool hasData) {
      return _isOnboardingStepComplete(flag) || hasData;
    }

    final hasAccounts = accountProvider.accounts.isNotEmpty;
    final hasGoals = goalProvider.goals.isNotEmpty;
    final hasBudgets = budgetProvider.budgets.isNotEmpty;
    final hasInvestments = investmentProvider.investments.isNotEmpty;
    final hasLoans = loanProvider.loans.isNotEmpty;
    final hasSubscriptions = subscriptionProvider.subscriptions.isNotEmpty;
    final currencySet =
        settingsProvider.currency != 'USD'; // Assume USD is default

    final tasks = <_SetupTask>[
      _SetupTask(
        title: 'Set preferred currency',
        subtitle: 'Choose the currency used across transactions and reports.',
        isComplete:
            isTaskComplete('onboarding_step_currency_completed', currencySet),
        icon: Icons.currency_exchange,
        destinationBuilder: (_) => const SettingsScreen(),
        actionLabel: 'Open Settings',
      ),
      _SetupTask(
        title: 'Add your first account',
        subtitle: 'Start tracking cash in bank, wallet, or cash accounts.',
        isComplete:
            isTaskComplete('onboarding_step_account_completed', hasAccounts),
        icon: Icons.account_balance_wallet_outlined,
        destinationBuilder: (_) => const AccountListScreen(
          showAppBar: true,
          showBackButton: true,
        ),
        actionLabel: 'Add Account',
      ),
      _SetupTask(
        title: 'Set a financial goal',
        subtitle: 'Create one goal to start tracking your progress.',
        isComplete: isTaskComplete('onboarding_step_goal_completed', hasGoals),
        icon: Icons.flag_outlined,
        destinationBuilder: (_) => const GoalTrackerScreen(
          showAppBar: true,
          showBackButton: true,
        ),
        actionLabel: 'Add Goal',
      ),
      _SetupTask(
        title: 'Create a monthly budget',
        subtitle: 'Set spending limits to monitor progress during the month.',
        isComplete:
            isTaskComplete('onboarding_step_budget_completed', hasBudgets),
        icon: Icons.pie_chart_outline,
        destinationBuilder: (_) => const BudgetPlannerScreen(
          showAppBar: true,
          showBackButton: true,
        ),
        actionLabel: 'Set Budget',
      ),
      _SetupTask(
        title: 'Track an investment',
        subtitle: 'Add an investment to monitor current market value.',
        isComplete: isTaskComplete(
            'onboarding_step_investment_completed', hasInvestments),
        icon: Icons.trending_up,
        destinationBuilder: (_) => const InvestmentPortfolioScreen(
          showAppBar: true,
          showBackButton: true,
        ),
        actionLabel: 'Add Investment',
      ),
      _SetupTask(
        title: 'Add a loan',
        subtitle: 'Track EMIs and remaining balances for liabilities.',
        isComplete: isTaskComplete('onboarding_step_loan_completed', hasLoans),
        icon: Icons.request_quote_outlined,
        destinationBuilder: (_) => const LoanTrackerScreen(
          showAppBar: true,
          showBackButton: true,
        ),
        actionLabel: 'Add Loan',
      ),
      _SetupTask(
        title: 'Add a subscription',
        subtitle: 'Keep recurring charges visible in one place.',
        isComplete: isTaskComplete(
            'onboarding_step_subscription_completed', hasSubscriptions),
        icon: Icons.subscriptions_outlined,
        destinationBuilder: (_) => const SubscriptionListScreen(
          showAppBar: true,
          showBackButton: true,
        ),
        actionLabel: 'Add Subscription',
      ),
    ];

    return tasks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: Consumer<HomeViewModel>(
            builder: (context, viewModel, _) {
              final settings = context.watch<SettingsProvider>();
              final accountProvider = context.watch<PaymentAccountProvider>();
              final goalProvider = context.watch<GoalProvider>();
              final budgetProvider = context.watch<BudgetProvider>();
              final investmentProvider = context.watch<InvestmentProvider>();
              final loanProvider = context.watch<LoanProvider>();
              final subscriptionProvider =
                  context.watch<SubscriptionProvider>();

              final allSetupTasks = _buildSetupTasks(
                accountProvider: accountProvider,
                goalProvider: goalProvider,
                budgetProvider: budgetProvider,
                investmentProvider: investmentProvider,
                loanProvider: loanProvider,
                settingsProvider: settings,
                subscriptionProvider: subscriptionProvider,
              );
              final pendingSetupTasks =
                  allSetupTasks.where((task) => !task.isComplete).toList();
              final completedSetupTasks =
                  allSetupTasks.where((task) => task.isComplete).toList();

              // Animate net worth if changed
              if (viewModel.netWorth != _previousNetWorth) {
                _netWorthAnimationController.forward(from: 0);
                _previousNetWorth = viewModel.netWorth;
              }

              return SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  contentBottomPadding(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1️⃣ Snapshot Card
                    _SnapshotCard(
                      assets: viewModel.assets,
                      liquidAccountBalance: viewModel.liquidAccountBalance,
                      investmentAsset: viewModel.assetInvestmentComponent,
                      accountAsset: viewModel.assetAccountComponent,
                      loans: viewModel.loans,
                      netWorth: viewModel.netWorth,
                      currencySymbol: settings.currencySymbol,
                      animation: _netWorthAnimationController,
                    ),
                    const SizedBox(height: 16),

                    if (pendingSetupTasks.isNotEmpty) ...[
                      _PendingSetupCard(
                        pendingTasks: pendingSetupTasks,
                        completedTasks: completedSetupTasks,
                        totalTasks: 7,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 1.5️⃣ Pending Bills Alert Card
                    if (viewModel.pendingBillReminderCount > 0) ...[
                      _AlertsStrip(
                          pendingBillCount: viewModel.pendingBillReminderCount),
                      const SizedBox(height: 16),
                    ],

                    if (viewModel.pendingReceivableCount > 0 ||
                        viewModel.receivedReceivableCount > 0) ...[
                      _ReceivableSummaryCard(
                        pendingCount: viewModel.pendingReceivableCount,
                        receivedCount: viewModel.receivedReceivableCount,
                        pendingTotal: viewModel.pendingReceivableTotal,
                        currencySymbol: settings.currencySymbol,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 2️⃣ Welcome Back Banner (conditional)
                    if (viewModel.isInactive) ...[
                      const _WelcomeBackBanner(),
                      const SizedBox(height: 16),
                    ],

                    // 3️⃣ Budget Overview Card
                    _BudgetOverviewCard(
                      hasBudget: viewModel.hasBudget,
                      budgetUsagePercent: viewModel.budgetUsagePercent,
                      remainingBudget: viewModel.remainingBudget,
                      monthlyBudget: viewModel.monthlyBudget,
                      overspentCategories: viewModel.overspentCategories,
                      currencySymbol: settings.currencySymbol,
                    ),
                    const SizedBox(height: 16),

                    // 4️⃣ Top Spending Categories
                    if (viewModel.topCategories.isNotEmpty) ...[
                      _TopCategoriesCard(
                        categories: viewModel.topCategories,
                        currencySymbol: settings.currencySymbol,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 5️⃣ Streak Card
                    _StreakCard(streak: viewModel.streak),
                    const SizedBox(height: 16),

                    // 6️⃣ Investment Summary (if have investments)
                    if (viewModel.investmentValue > 0) ...[
                      _InvestmentSummaryCard(
                        portfolioValue: viewModel.investmentValue,
                        investmentCost: viewModel.investmentCost,
                        gainLoss: viewModel.investmentGainLoss,
                        gainLossPercent: viewModel.investmentGainLossPercent,
                        currencySymbol: settings.currencySymbol,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 7️⃣ Goals Section
                    const _GoalsSection(),
                    const SizedBox(height: 24), // Padding at bottom
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 1️⃣ SNAPSHOT CARD
// ═══════════════════════════════════════════════════════════════

class _SnapshotCard extends StatelessWidget {
  final double assets;
  final double liquidAccountBalance;
  final double investmentAsset;
  final double accountAsset;
  final double loans;
  final double netWorth;
  final String currencySymbol;
  final AnimationController animation;

  const _SnapshotCard({
    required this.assets,
    required this.liquidAccountBalance,
    required this.investmentAsset,
    required this.accountAsset,
    required this.loans,
    required this.netWorth,
    required this.currencySymbol,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = netWorth < 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Assets & Loans Row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AccountListScreen(
                            showAppBar: true,
                            showBackButton: true,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.surface
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                size: 14,
                                color: const Color(0xFF059669),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Accounts',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: Colors.grey.shade400,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              AppUtils.formatCurrency(liquidAccountBalance,
                                  currencySymbol: currencySymbol),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF047857),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
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
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.surface
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFF59E0B).withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance,
                                size: 14,
                                color: const Color(0xFFD97706),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Loans',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: Colors.grey.shade400,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              AppUtils.formatCurrency(loans,
                                  currencySymbol: currencySymbol),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Net Worth
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => NetWorthBreakdownScreen(
                      assets: assets,
                      loans: loans,
                      netWorth: netWorth,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.surface
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isNegative
                        ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                        : const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isNegative
                          ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                          : const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 14,
                          color: isNegative
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF7C3AED),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Net Worth',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        if (isNegative) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: const Color(0xFFDC2626),
                          ),
                        ],
                        const SizedBox(width: 6),
                        Icon(
                          Icons.open_in_new,
                          size: 14,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FadeTransition(
                      opacity: animation,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          AppUtils.formatCurrency(netWorth,
                              currencySymbol: currencySymbol),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: isNegative
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.28),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Asset Balance',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                  Text(
                    AppUtils.formatCurrency(assets,
                        currencySymbol: currencySymbol),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 1.5️⃣ INVESTMENT SUMMARY CARD
// ═══════════════════════════════════════════════════════════════

class _InvestmentSummaryCard extends StatelessWidget {
  final double portfolioValue;
  final double investmentCost;
  final double gainLoss;
  final double gainLossPercent;
  final String currencySymbol;

  const _InvestmentSummaryCard({
    required this.portfolioValue,
    required this.investmentCost,
    required this.gainLoss,
    required this.gainLossPercent,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = gainLoss >= 0;

    return InkWell(
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
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Investment Portfolio',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${isPositive ? '+' : ''}${gainLossPercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isPositive
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Market Amount',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppUtils.formatCurrency(portfolioValue,
                            currencySymbol: currencySymbol),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Gain / Loss',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppUtils.formatCurrency(gainLoss,
                            currencySymbol: currencySymbol),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isPositive
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 2️⃣ WELCOME BACK BANNER
// ═══════════════════════════════════════════════════════════════

class _WelcomeBackBanner extends StatelessWidget {
  const _WelcomeBackBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.waving_hand, color: Colors.blue.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Welcome back! Let\'s get your finances back on track.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 3️⃣ BUDGET OVERVIEW CARD
// ═══════════════════════════════════════════════════════════════

class _BudgetOverviewCard extends StatelessWidget {
  final bool hasBudget;
  final double budgetUsagePercent;
  final double remainingBudget;
  final double monthlyBudget;
  final List<String> overspentCategories;
  final String currencySymbol;

  const _BudgetOverviewCard({
    required this.hasBudget,
    required this.budgetUsagePercent,
    required this.remainingBudget,
    required this.monthlyBudget,
    required this.overspentCategories,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasBudget) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pie_chart_outline,
                    size: 48,
                    color: AppTheme.primaryColor.withValues(alpha: 0.6)),
                const SizedBox(height: 12),
                Text(
                  'No Budget Set',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a budget to track your spending',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const BudgetPlannerScreen(
                          showAppBar: true,
                          showBackButton: true,
                        ),
                      ),
                    );
                  },
                  child: const Text('Set Budget'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isWarning = budgetUsagePercent >= 0.8;
    final isExceeded = budgetUsagePercent > 1.0;
    final usageColor = isExceeded
        ? Colors.red
        : isWarning
            ? Colors.orange
            : Colors.green;

    // Compute spent amount for display
    final spentAmount = monthlyBudget - remainingBudget;

    // Determine status label and icon
    String statusLabel;
    IconData statusIcon;
    if (isExceeded) {
      statusLabel = 'Overspent';
      statusIcon = Icons.warning_rounded;
    } else if (isWarning) {
      statusLabel = 'Approaching Limit';
      statusIcon = Icons.info_rounded;
    } else {
      statusLabel = 'On Track';
      statusIcon = Icons.check_circle_rounded;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
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
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Title + Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Monthly Budget',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: usageColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: usageColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: usageColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: usageColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress Bar with Label
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Spent',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${(budgetUsagePercent * 100).toStringAsFixed(0)}% of ${AppUtils.formatCurrency(monthlyBudget, currencySymbol: currencySymbol)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: usageColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: budgetUsagePercent.clamp(0.0, 1.0),
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(usageColor),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 12),
              // Amount Details Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You spent',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        AppUtils.formatCurrency(spentAmount,
                            currencySymbol: currencySymbol),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isExceeded ? 'Overspent by' : 'You have left',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        AppUtils.formatCurrency(remainingBudget.abs(),
                            currencySymbol: currencySymbol),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isExceeded
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (overspentCategories.isNotEmpty) ...[
                const SizedBox(height: 16),
                Divider(height: 1, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  '⚠️ Categories Over Limit',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: overspentCategories.take(3).map((cat) {
                    return Chip(
                      label: Text(
                        cat,
                        style: TextStyle(fontSize: 10),
                      ),
                      backgroundColor: Colors.red.shade50,
                      side: BorderSide(color: Colors.red.shade200),
                      avatar: Icon(Icons.trending_up,
                          size: 12, color: Colors.red.shade700),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 4️⃣ TOP SPENDING CATEGORIES
// ═══════════════════════════════════════════════════════════════

class _TopCategoriesCard extends StatelessWidget {
  final List<CategorySpending> categories;
  final String currencySymbol;

  const _TopCategoriesCard({
    required this.categories,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Top Spending',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ...categories.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              cat.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppUtils.formatCurrency(cat.amount,
                                currencySymbol: currencySymbol),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: cat.percentage,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(
                            cat.percentage > 1.0
                                ? Colors.red
                                : cat.percentage > 0.8
                                    ? Colors.orange
                                    : AppTheme.primaryColor,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 5️⃣ STREAK CARD
// ═══════════════════════════════════════════════════════════════

class _StreakCard extends StatelessWidget {
  final int streak;

  const _StreakCard({required this.streak});

  String _getStreakMessage(int days) {
    if (days == 0) return 'Start your tracking streak today!';
    if (days <= 2) return 'Great start! Keep tracking.';
    if (days <= 6) return 'Streak building! Keep it up.';
    if (days < 30) return '$days days strong! You\'re on fire 🔥';
    return '$days days! You\'re a tracking master 🏆';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.surface
                    : null,
                gradient: Theme.of(context).brightness == Brightness.dark
                    ? null
                    : LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withValues(alpha: 0.7),
                        ],
                      ),
                shape: BoxShape.circle,
                border: Theme.of(context).brightness == Brightness.dark
                    ? Border.all(color: Theme.of(context).dividerColor)
                    : null,
              ),
              child: Center(
                child: Text(
                  '$streak',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tracking Streak',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStreakMessage(streak),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 6️⃣ ALERTS STRIP
// ═══════════════════════════════════════════════════════════════

class _AlertsStrip extends StatelessWidget {
  final int pendingBillCount;

  const _AlertsStrip({required this.pendingBillCount});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const BillListScreen(
            showAppBar: true,
            showBackButton: true,
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: Colors.red,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending Bills',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$pendingBillCount reminder${pendingBillCount != 1 ? 's' : ''} pending',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.red.shade400,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingSetupCard extends StatelessWidget {
  final List<_SetupTask> pendingTasks;
  final List<_SetupTask> completedTasks;
  final int totalTasks;

  const _PendingSetupCard({
    required this.pendingTasks,
    required this.completedTasks,
    required this.totalTasks,
  });

  Widget _buildTaskRow(
    BuildContext context,
    _SetupTask task, {
    bool completed = false,
  }) {
    final borderColor =
        completed ? Colors.green.shade100 : Colors.orange.shade100;
    final iconColor =
        completed ? Colors.green.shade700 : const Color(0xFFD97706);
    final actionColor =
        completed ? Colors.green.shade700 : const Color(0xFFD97706);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: task.destinationBuilder),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(task.icon, color: iconColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      task.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                completed ? 'Review' : task.actionLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: actionColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = completedTasks.length;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF4E6),
              Color(0xFFFFFDF7),
            ],
          ),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.checklist_rounded,
                    color: Color(0xFFD97706),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Setup Guide',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$completedCount of $totalTasks completed',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (pendingTasks.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Text(
                  'All setup items are completed.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                  ),
                ),
              )
            else
              ...pendingTasks.map((task) => _buildTaskRow(context, task)),
            if (completedTasks.isNotEmpty) ...[
              const SizedBox(height: 6),
              Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  title: Text(
                    'Completed Setup Items (${completedTasks.length})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade800,
                    ),
                  ),
                  subtitle: Text(
                    'Tap to review completed onboarding setup steps',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  iconColor: Colors.green.shade700,
                  collapsedIconColor: Colors.green.shade700,
                  children: completedTasks
                      .map(
                        (task) => _buildTaskRow(
                          context,
                          task,
                          completed: true,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SetupTask {
  final String title;
  final String subtitle;
  final bool isComplete;
  final IconData icon;
  final WidgetBuilder destinationBuilder;
  final String actionLabel;

  const _SetupTask({
    required this.title,
    required this.subtitle,
    required this.isComplete,
    required this.icon,
    required this.destinationBuilder,
    required this.actionLabel,
  });
}

class _ReceivableSummaryCard extends StatelessWidget {
  final int pendingCount;
  final int receivedCount;
  final double pendingTotal;
  final String currencySymbol;

  const _ReceivableSummaryCard({
    required this.pendingCount,
    required this.receivedCount,
    required this.pendingTotal,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const ReceivableListScreen(
            showAppBar: true,
            showBackButton: true,
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                color: Colors.green,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Receivables',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$pendingCount pending • $receivedCount received',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pending amount: $currencySymbol ${pendingTotal.toStringAsFixed(2)} · Tap to view all',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.green.shade500,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 7️⃣ GOALS SECTION
// ═══════════════════════════════════════════════════════════════

class _GoalsSection extends StatelessWidget {
  const _GoalsSection();

  @override
  Widget build(BuildContext context) {
    return Consumer2<GoalProvider, SettingsProvider>(
      builder: (context, goalProvider, settingsProvider, _) {
        final activeGoals = goalProvider.activeGoals;
        final completedGoalsCount =
            goalProvider.goals.where((g) => g.isCompleted).length;
        final hasGoals = activeGoals.isNotEmpty;

        if (!hasGoals) {
          return Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag_outlined,
                        size: 48,
                        color: AppTheme.primaryColor.withValues(alpha: 0.6)),
                    const SizedBox(height: 12),
                    Text(
                      'No Goals Set',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set financial goals to track progress',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const GoalTrackerScreen(
                              showAppBar: true,
                              showBackButton: true,
                            ),
                          ),
                        );
                      },
                      child: const Text('Create Goal'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final totalTarget = goalProvider.getTotalGoalAmount();
        final totalSaved = goalProvider.getTotalSavedAmount();
        final progressPercent = goalProvider.getOverallProgressPercentage();

        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
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
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Financial Goals',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          size: 16,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${activeGoals.length} active goal${activeGoals.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${AppUtils.formatCurrency(totalSaved, currencySymbol: settingsProvider.currencySymbol)} saved of ${AppUtils.formatCurrency(totalTarget, currencySymbol: settingsProvider.currencySymbol)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$completedGoalsCount completed goal${completedGoalsCount == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (progressPercent / 100).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${progressPercent.toStringAsFixed(1)}% complete',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
