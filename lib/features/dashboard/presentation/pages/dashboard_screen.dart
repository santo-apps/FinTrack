import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/core/constants/app_constants.dart';
import 'package:fintrack/features/dashboard/presentation/providers/home_viewmodel.dart';
import 'package:fintrack/features/dashboard/presentation/pages/asset_breakdown_screen.dart';
import 'package:fintrack/features/dashboard/presentation/pages/networth_breakdown_screen.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';
import 'package:fintrack/features/loan/presentation/pages/loan_tracker_screen.dart';
import 'package:fintrack/features/budget/presentation/pages/budget_planner_screen.dart';
import 'package:fintrack/features/goals/presentation/pages/goal_tracker_screen.dart';
import 'package:fintrack/features/bill/presentation/pages/bill_list_screen.dart';
import 'package:fintrack/features/investment/presentation/pages/investment_portfolio_screen.dart';
import 'package:fintrack/features/expense/presentation/pages/expense_list_screen.dart';
import 'package:fintrack/features/expense/presentation/providers/expense_provider.dart';
import 'package:fintrack/features/budget/presentation/providers/budget_provider.dart';
import 'package:fintrack/features/investment/presentation/providers/investment_provider.dart';
import 'package:fintrack/features/loan/presentation/providers/loan_provider.dart';
import 'package:fintrack/features/accounts/presentation/providers/payment_account_provider.dart';
import 'package:fintrack/features/goals/presentation/providers/goal_provider.dart';
import 'package:fintrack/features/bill/presentation/providers/bill_provider.dart';

/// DashboardScreen: Premium financial control center
/// Clean, calm, structured – manual discipline MVP
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeViewModel(
        expenseProvider: Provider.of<ExpenseProvider>(context, listen: false),
        budgetProvider: Provider.of<BudgetProvider>(context, listen: false),
        investmentProvider: Provider.of<InvestmentProvider>(context, listen: false),
        loanProvider: Provider.of<LoanProvider>(context, listen: false),
        accountProvider: Provider.of<PaymentAccountProvider>(context, listen: false),
        goalProvider: Provider.of<GoalProvider>(context, listen: false),
        billProvider: Provider.of<BillProvider>(context, listen: false),
      ),
      child: const _DashboardScreenContent(),
    );
  }
}

class _DashboardScreenContent extends StatefulWidget {
  const _DashboardScreenContent();

  @override
  State<_DashboardScreenContent> createState() => _DashboardScreenContentState();
}

class _DashboardScreenContentState extends State<_DashboardScreenContent>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _netWorthAnimationController;
  double _previousNetWorth = -1; // Initialize to -1 to trigger animation on first load

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: Consumer2<HomeViewModel, SettingsProvider>(
            builder: (context, viewModel, settings, _) {
              // Animate net worth if changed
              if (viewModel.netWorth != _previousNetWorth) {
                _netWorthAnimationController.forward(from: 0);
                _previousNetWorth = viewModel.netWorth;
              }

              return SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1️⃣ Snapshot Card
                    _SnapshotCard(
                      assets: viewModel.assets,
                      investmentAsset: viewModel.assetInvestmentComponent,
                      accountAsset: viewModel.assetAccountComponent,
                      loans: viewModel.loans,
                      netWorth: viewModel.netWorth,
                      todaySpend: viewModel.todaySpend,
                      remainingBudget: viewModel.remainingBudget,
                      savingsRate: viewModel.savingsRate,
                      currencySymbol: settings.currencySymbol,
                      animation: _netWorthAnimationController,
                    ),
                    const SizedBox(height: 16),

                    // 1.5️⃣ Pending Bills Alert Card
                    if (viewModel.pendingBillReminderCount > 0) ...[
                      _AlertsStrip(pendingBillCount: viewModel.pendingBillReminderCount),
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
  final double investmentAsset;
  final double accountAsset;
  final double loans;
  final double netWorth;
  final double todaySpend;
  final double remainingBudget;
  final double savingsRate;
  final String currencySymbol;
  final AnimationController animation;

  const _SnapshotCard({
    required this.assets,
    required this.investmentAsset,
    required this.accountAsset,
    required this.loans,
    required this.netWorth,
    required this.todaySpend,
    required this.remainingBudget,
    required this.savingsRate,
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
        padding: const EdgeInsets.all(20),
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
                          builder: (context) => const AssetBreakdownScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assets',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppUtils.formatCurrency(assets,
                                currencySymbol: currencySymbol),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Loans',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppUtils.formatCurrency(loans,
                                currencySymbol: currencySymbol),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

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
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Net Worth',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (isNegative) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: Colors.red.shade700,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    FadeTransition(
                      opacity: animation,
                      child: Text(
                        AppUtils.formatCurrency(netWorth,
                            currencySymbol: currencySymbol),
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: isNegative
                              ? Colors.red.shade700
                              : AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Compact Metrics Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _CompactMetric(
                  label: 'Today',
                  value: AppUtils.formatCurrency(todaySpend,
                      currencySymbol: currencySymbol),
                  color: Colors.orange,
                ),
                _CompactMetric(
                  label: 'Budget Left',
                  value: AppUtils.formatCurrency(remainingBudget,
                      currencySymbol: currencySymbol),
                  color: Colors.blue,
                ),
                _CompactMetric(
                  label: 'Savings',
                  value: '${savingsRate.toStringAsFixed(0)}%',
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CompactMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
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
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${isPositive ? '+' : ''}${gainLossPercent.toStringAsFixed(1)}%',
                      style: GoogleFonts.poppins(
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
                        'Current Value',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppUtils.formatCurrency(portfolioValue,
                            currencySymbol: currencySymbol),
                        style: GoogleFonts.poppins(
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
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppUtils.formatCurrency(gainLoss,
                            currencySymbol: currencySymbol),
                        style: GoogleFonts.poppins(
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
              style: GoogleFonts.poppins(
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
                    size: 48, color: AppTheme.primaryColor.withOpacity(0.6)),
                const SizedBox(height: 12),
                Text(
                  'No Budget Set',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a budget to track your spending',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
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
                      style: GoogleFonts.poppins(
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
                      color: usageColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: usageColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: usageColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: GoogleFonts.poppins(
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
                    style: GoogleFonts.poppins(
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
                      style: GoogleFonts.poppins(
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
                  backgroundColor: Colors.grey.shade200,
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
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        AppUtils.formatCurrency(spentAmount,
                            currencySymbol: currencySymbol),
                        style: GoogleFonts.poppins(
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
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        AppUtils.formatCurrency(remainingBudget.abs(),
                            currencySymbol: currencySymbol),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isExceeded ? Colors.red.shade700 : Colors.green.shade700,
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
                  style: GoogleFonts.poppins(
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
                        style: GoogleFonts.poppins(fontSize: 10),
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
                style: GoogleFonts.poppins(
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
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppUtils.formatCurrency(cat.amount,
                                currencySymbol: currencySymbol),
                            style: GoogleFonts.poppins(
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
                          backgroundColor: Colors.grey.shade200,
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
    if (days < 30) return '${days} days strong! You\'re on fire 🔥';
    return '${days} days! You\'re a tracking master 🏆';
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
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.7),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$streak',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
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
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStreakMessage(streak),
                    style: GoogleFonts.poppins(
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
            color: Colors.red.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
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
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$pendingBillCount reminder${pendingBillCount != 1 ? 's' : ''} pending',
                      style: GoogleFonts.poppins(
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
                        size: 48, color: AppTheme.primaryColor.withOpacity(0.6)),
                    const SizedBox(height: 12),
                    Text(
                      'No Goals Set',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set financial goals to track progress',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
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
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey.shade600),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${activeGoals.length} active goal${activeGoals.length == 1 ? '' : 's'}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${AppUtils.formatCurrency(totalSaved, currencySymbol: settingsProvider.currencySymbol)} saved of ${AppUtils.formatCurrency(totalTarget, currencySymbol: settingsProvider.currencySymbol)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$completedGoalsCount completed goal${completedGoalsCount == 1 ? '' : 's'}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (progressPercent / 100).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${progressPercent.toStringAsFixed(1)}% complete',
                    style: GoogleFonts.poppins(
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
