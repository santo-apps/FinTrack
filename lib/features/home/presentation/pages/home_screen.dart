import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:fintrack/features/expense/presentation/pages/expense_list_screen.dart';
import 'package:fintrack/features/bill/presentation/pages/bill_list_screen.dart';
import 'package:fintrack/features/subscription/presentation/pages/subscription_list_screen.dart';
import 'package:fintrack/features/investment/presentation/pages/investment_portfolio_screen.dart';
import 'package:fintrack/features/budget/presentation/pages/budget_planner_screen.dart';
import 'package:fintrack/features/goals/presentation/pages/goal_tracker_screen.dart';
import 'package:fintrack/features/loan/presentation/pages/loan_tracker_screen.dart';
import 'package:fintrack/features/settings/presentation/pages/settings_screen.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';
import 'package:fintrack/features/accounts/presentation/pages/account_list_screen.dart';
import 'package:fintrack/features/accounts/presentation/pages/account_form_screen.dart';
import 'package:fintrack/features/loan/presentation/widgets/add_edit_loan_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isFabExpanded = false;

  static const _NavModule _homeModule = _NavModule(
    id: 'home',
    label: 'Home',
    icon: Icons.home,
    screen: DashboardScreen(),
  );

  static const List<_NavModule> _allModules = [
    _NavModule(
      id: 'expenses',
      label: 'Expenses',
      icon: Icons.receipt_long,
      screen: ExpenseListScreen(showAppBar: false),
    ),
    _NavModule(
      id: 'accounts',
      label: 'Accounts',
      icon: Icons.account_balance_wallet,
      screen: AccountListScreen(showAppBar: false),
    ),
    _NavModule(
      id: 'budget',
      label: 'Budget',
      icon: Icons.pie_chart,
      screen: BudgetPlannerScreen(showAppBar: false),
    ),
    _NavModule(
      id: 'bills',
      label: 'Bills',
      icon: Icons.calendar_today,
      screen: BillListScreen(showAppBar: false),
    ),
    _NavModule(
      id: 'subscriptions',
      label: 'Subs',
      icon: Icons.subscriptions,
      screen: SubscriptionListScreen(showAppBar: false),
      appBarTitle: 'Subscriptions',
    ),
    _NavModule(
      id: 'investments',
      label: 'Investments',
      icon: Icons.trending_up,
      screen: InvestmentPortfolioScreen(showAppBar: false),
    ),
    _NavModule(
      id: 'goals',
      label: 'Goals',
      icon: Icons.flag_outlined,
      screen: GoalTrackerScreen(showAppBar: false),
    ),
    _NavModule(
      id: 'loans',
      label: 'Loans',
      icon: Icons.account_balance,
      screen: LoanTrackerScreen(showAppBar: false),
    ),
  ];

  void _navigateToScreen(Widget screen) {
    // Close drawer and navigate with full-screen coverage
    Navigator.pop(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: false,
        builder: (context) => screen,
      ),
    );
  }

  void _showExpenseDialog() {
    setState(() => _isFabExpanded = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditExpenseScreen(),
      ),
    );
  }

  void _showSubscriptionDialog() {
    setState(() => _isFabExpanded = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditSubscriptionScreen(),
      ),
    );
  }

  void _showInvestmentDialog() {
    setState(() => _isFabExpanded = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditInvestmentScreen(),
      ),
    );
  }

  void _showAccountDialog() {
    setState(() => _isFabExpanded = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AccountFormScreen(),
      ),
    );
  }

  void _showGoalDialog() {
    setState(() => _isFabExpanded = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditGoalScreen(),
      ),
    );
  }

  void _showLoanDialog() {
    setState(() => _isFabExpanded = false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: const AddEditLoanDialog(),
      ),
    );
  }

  void _showBudgetDialog() {
    setState(() => _isFabExpanded = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const BudgetPlannerScreen(showAppBar: true, showBackButton: true),
      ),
    );
  }

  void _showBillDialog() {
    setState(() => _isFabExpanded = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditBillScreen(),
      ),
    );
  }

  List<_FabActionConfig> _buildFabActions(SettingsProvider settingsProvider) {
    final actionMap = <String, _FabActionConfig>{
      'expenses': _FabActionConfig(
        id: 'expenses',
        icon: Icons.receipt_long,
        label: 'Expense',
        onPressed: _showExpenseDialog,
      ),
      'subscriptions': _FabActionConfig(
        id: 'subscriptions',
        icon: Icons.subscriptions,
        label: 'Subscription',
        onPressed: _showSubscriptionDialog,
      ),
      'investments': _FabActionConfig(
        id: 'investments',
        icon: Icons.trending_up,
        label: 'Investment',
        onPressed: _showInvestmentDialog,
      ),
      'accounts': _FabActionConfig(
        id: 'accounts',
        icon: Icons.account_balance_wallet,
        label: 'Account',
        onPressed: _showAccountDialog,
      ),
      'goals': _FabActionConfig(
        id: 'goals',
        icon: Icons.flag_outlined,
        label: 'Goal',
        onPressed: _showGoalDialog,
      ),
      'loans': _FabActionConfig(
        id: 'loans',
        icon: Icons.account_balance,
        label: 'Loan',
        onPressed: _showLoanDialog,
      ),
      'budget': _FabActionConfig(
        id: 'budget',
        icon: Icons.pie_chart,
        label: 'Budget',
        onPressed: _showBudgetDialog,
      ),
      'bills': _FabActionConfig(
        id: 'bills',
        icon: Icons.calendar_today,
        label: 'Bill',
        onPressed: _showBillDialog,
      ),
    };

    final configuredActions = settingsProvider.quickActionItems
        .where((id) => actionMap.containsKey(id))
        .map((id) => actionMap[id]!)
        .toList();

    if (configuredActions.isNotEmpty) {
      return configuredActions;
    }

    return [
      actionMap['expenses']!,
      actionMap['accounts']!,
      actionMap['budget']!,
      actionMap['bills']!,
    ];
  }

  Widget _buildExpandableFab(
      BuildContext context, SettingsProvider settingsProvider) {
    final fabActions = _buildFabActions(settingsProvider);
    final stackHeight =
        _isFabExpanded ? 70.0 + (fabActions.length * 55.0) : 56.0;

    return SizedBox(
      width: 220,
      height: stackHeight,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Mini FABs
          if (_isFabExpanded)
            ...fabActions.asMap().entries.map((entry) {
              final index = entry.key;
              final action = entry.value;

              return Positioned(
                bottom: 70 + (index * 55),
                right: 0,
                child: _MiniFloatingActionButton(
                  icon: action.icon,
                  label: action.label,
                  onPressed: action.onPressed,
                ),
              );
            }),
          // Main FAB
          Positioned(
            bottom: 0,
            right: 0,
            child: FloatingActionButton(
              mini: true,
              heroTag: 'home_main_fab_expand',
              onPressed: () => setState(() => _isFabExpanded = !_isFabExpanded),
              child: Icon(_isFabExpanded ? Icons.close : Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  /// Creates a screen with back button enabled for sidebar navigation
  Widget _createScreenWithBackButton(String screenId) {
    switch (screenId) {
      case 'budget':
        return const BudgetPlannerScreen(
            showAppBar: true, showBackButton: true);
      case 'bills':
        return const BillListScreen(showAppBar: true, showBackButton: true);
      case 'loans':
        return const LoanTrackerScreen(showAppBar: true, showBackButton: true);
      case 'subscriptions':
        return const SubscriptionListScreen(
            showAppBar: true, showBackButton: true);
      case 'investments':
        return const InvestmentPortfolioScreen(
            showAppBar: true, showBackButton: true);
      case 'goals':
        return const GoalTrackerScreen(showAppBar: true, showBackButton: true);
      case 'expenses':
        return const ExpenseListScreen(showAppBar: true, showBackButton: true);
      case 'accounts':
        return const AccountListScreen(showAppBar: true, showBackButton: true);
      default:
        return const Placeholder();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, _) {
        final bottomModules = _buildBottomModules(settingsProvider);
        if (_currentIndex >= bottomModules.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _currentIndex = 0);
            }
          });
        }

        final currentModule = bottomModules[_currentIndex];

        final isHomeModule = currentModule.id == _homeModule.id;

        return Stack(
          children: [
            Scaffold(
              appBar: AppBar(
                title: isHomeModule
                    ? const Text('FinTrack')
                    : Text(currentModule.appBarTitle ?? currentModule.label),
                elevation: 0,
                automaticallyImplyLeading: true,
              ),
              drawer: _buildDrawer(context, bottomModules),
              body: bottomModules[_currentIndex].screen,
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: _currentIndex,
                type: bottomModules.length > 3
                    ? BottomNavigationBarType.fixed
                    : BottomNavigationBarType.shifting,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                elevation: 8,
                onTap: (index) {
                  setState(() => _currentIndex = index);
                },
                items: bottomModules
                    .map(
                      (module) => BottomNavigationBarItem(
                        icon: Icon(module.icon),
                        label: module.label,
                      ),
                    )
                    .toList(),
              ),
            ),
            if (isHomeModule && _isFabExpanded)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _isFabExpanded = false),
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
              ),
            if (isHomeModule)
              Positioned(
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom +
                    kBottomNavigationBarHeight +
                    16,
                child: Material(
                  type: MaterialType.transparency,
                  child: _buildExpandableFab(context, settingsProvider),
                ),
              ),
          ],
        );
      },
    );
  }

  List<_NavModule> _buildBottomModules(SettingsProvider settingsProvider) {
    final selectedIds = settingsProvider.bottomNavItems;
    final selectedModules = selectedIds
        .map((id) => _allModules.firstWhere(
              (module) => module.id == id,
              orElse: () => const _NavModule(
                id: 'unknown',
                label: 'Unknown',
                icon: Icons.help_outline,
                screen: SizedBox.shrink(),
              ),
            ))
        .where((module) => module.id != 'unknown')
        .toList();

    return [_homeModule, ...selectedModules];
  }

  Widget _buildDrawer(BuildContext context, List<_NavModule> bottomModules) {
    return Drawer(
      child: Container(
        color: Colors.grey[50],
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Modern Gradient Header
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.of(context).padding.top + 24,
                24,
                30,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/icon/fintrack_icon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'FinTrack',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Personal Finance Manager',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Quick Navigation Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Text(
                'Quick Navigation',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...bottomModules.asMap().entries.map((entry) {
              final index = entry.key;
              final module = entry.value;
              return _buildModernDrawerItem(
                context,
                icon: module.icon,
                label: module.appBarTitle ?? module.label,
                isSelected: _currentIndex == index,
                onTap: () {
                  setState(() => _currentIndex = index);
                  Navigator.pop(context);
                },
              );
            }),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Divider(
                color: Colors.grey[300],
                height: 1,
              ),
            ),

            // Features Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Text(
                'Features',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ..._allModules
                .where(
                  (module) =>
                      !bottomModules.any((item) => item.id == module.id),
                )
                .map(
                  (module) => _buildModernDrawerItem(
                    context,
                    icon: module.icon,
                    label: module.appBarTitle ?? module.label,
                    onTap: () => _navigateToScreen(
                        _createScreenWithBackButton(module.id)),
                  ),
                ),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Divider(
                color: Colors.grey[300],
                height: 1,
              ),
            ),

            // Application Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Text(
                'Application',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // Settings
            _buildModernDrawerItem(
              context,
              icon: Icons.settings,
              label: 'Settings',
              onTap: () => _navigateToScreen(const SettingsScreen()),
            ),

            // About
            // _buildModernDrawerItem(
            //   context,
            //   icon: Icons.info_outline,
            //   label: 'About',
            //   onTap: () => _navigateToScreen(const AboutAppScreen()),
            // ),

            // Footer Spacer
            const SizedBox(height: 24),

            // Footer Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[200]!,
                ),
              ),
              child: Center(
                child: Text(
                  'v1.0.0',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected
            ? Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                width: 1.5,
              )
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.15)
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color:
                isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
            size: 20,
          ),
        ),
        title: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color:
                isSelected ? Theme.of(context).primaryColor : Colors.grey[800],
          ),
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle_rounded,
                color: Theme.of(context).primaryColor,
                size: 20,
              )
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class _FabActionConfig {
  final String id;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _FabActionConfig({
    required this.id,
    required this.icon,
    required this.label,
    required this.onPressed,
  });
}

class _NavModule {
  final String id;
  final String label;
  final IconData icon;
  final Widget screen;
  final String? appBarTitle;

  const _NavModule({
    required this.id,
    required this.label,
    required this.icon,
    required this.screen,
    this.appBarTitle,
  });
}

class _MiniFloatingActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _MiniFloatingActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 164,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              heroTag: 'home_mini_fab_${icon.codePoint}',
              mini: true,
              onPressed: onPressed,
              child: Icon(icon),
            ),
          ],
        ),
      ),
    );
  }
}
