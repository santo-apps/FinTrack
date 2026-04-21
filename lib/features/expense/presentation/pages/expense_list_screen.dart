import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/core/constants/app_constants.dart';
import 'package:fintrack/core/utils/custom_widgets.dart';
import 'package:fintrack/features/expense/data/models/expense_model.dart';
import 'package:fintrack/features/expense/data/models/expense_category_model.dart';
import 'package:fintrack/features/expense/presentation/providers/expense_provider.dart';
import 'package:fintrack/features/expense/presentation/pages/manage_expense_categories_screen.dart';
import 'package:fintrack/features/accounts/data/models/payment_account_model.dart';
import 'package:fintrack/features/accounts/presentation/providers/payment_account_provider.dart';
import 'package:fintrack/features/accounts/presentation/providers/account_type_provider.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';

enum SortOption { date, amount, category }

class ExpenseListScreen extends StatefulWidget {
  final bool showAppBar;
  final bool showBackButton;

  const ExpenseListScreen({
    super.key,
    this.showAppBar = true,
    this.showBackButton = false,
  });

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedMonth = DateTime.now();
  DateTimeRange? _customDateRange;
  SortOption _sortOption = SortOption.date;
  bool _sortAscending = false;
  late TabController _tabController;
  final Set<String> _expandedCategories = <String>{};
  final TextEditingController _timelineSearchController =
      TextEditingController();
  String _timelineSearchQuery = '';
  int _touchedIndex = -1;
  final Set<String> _pendingDeletedExpenseIds = <String>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Color _tabPrimaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : AppTheme.textColor;
  }

  Color _tabSecondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : AppTheme.textSecondaryColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Expenses'),
              elevation: 0,
              automaticallyImplyLeading: widget.showBackButton,
            )
          : null,
      body: SafeArea(
        child: Consumer<ExpenseProvider>(
          builder: (context, provider, _) {
            final allExpenses = provider.expenses
                .where((e) => !_pendingDeletedExpenseIds.contains(e.id))
                .toList();

            // Filter expenses based on selected period
            List<Expense> filteredExpenses;
            if (_customDateRange != null) {
              filteredExpenses = allExpenses.where((expense) {
                return expense.date.isAfter(_customDateRange!.start
                        .subtract(const Duration(days: 1))) &&
                    expense.date.isBefore(
                        _customDateRange!.end.add(const Duration(days: 1)));
              }).toList();
            } else {
              filteredExpenses = allExpenses.where((expense) {
                return expense.date.year == _selectedMonth.year &&
                    expense.date.month == _selectedMonth.month;
              }).toList();
            }

            // Use one consistent dataset across summary + all tabs
            final overviewExpenses =
                filteredExpenses.where(_isAccountBreakdownTransaction).toList();

            // Sort expenses for list usage
            final sortedExpenses = List<Expense>.from(overviewExpenses);
            switch (_sortOption) {
              case SortOption.date:
                sortedExpenses.sort((a, b) => _sortAscending
                    ? a.date.compareTo(b.date)
                    : b.date.compareTo(a.date));
                break;
              case SortOption.amount:
                sortedExpenses.sort((a, b) => _sortAscending
                    ? a.amount.compareTo(b.amount)
                    : b.amount.compareTo(a.amount));
                break;
              case SortOption.category:
                sortedExpenses.sort((a, b) => _sortAscending
                    ? a.category.compareTo(b.category)
                    : b.category.compareTo(a.category));
                break;
            }

            final totalAmount = overviewExpenses.fold<double>(
                0, (sum, expense) => sum + expense.amount);

            if (allExpenses.isEmpty) {
              return _buildEmptyState(
                icon: Icons.receipt_long,
                title: 'No Expenses',
                subtitle: 'Start tracking your expenses',
              );
            }

            return Column(
              children: [
                // TabBar with sort button
                Container(
                  color: Theme.of(context).appBarTheme.backgroundColor,
                  child: Row(
                    children: [
                      Expanded(
                        child: TabBar(
                          controller: _tabController,
                          labelColor: _tabPrimaryTextColor(context),
                          unselectedLabelColor: _tabSecondaryTextColor(context),
                          labelStyle: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600),
                          unselectedLabelStyle: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500),
                          tabs: const [
                            Tab(text: 'Overview'),
                            Tab(text: 'Categories'),
                            Tab(text: 'Timeline'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Month/Period Summary Card
                _buildSummaryCard(totalAmount),

                // Tabs Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(context, sortedExpenses, totalAmount),
                      _buildCategoryTab(context, sortedExpenses),
                      _buildTimelineTab(context, sortedExpenses),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: AdaptiveBottomFab(
        child: FloatingActionButton(
          mini: true,
          heroTag: 'expense_list_fab_add',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddEditExpenseScreen(),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timelineSearchController.dispose();
    super.dispose();
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppTheme.primaryColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _tabPrimaryTextColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: _tabSecondaryTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    List<Expense> expenses,
    double totalAmount,
  ) {
    final overviewExpenses =
        expenses.where(_isAccountBreakdownTransaction).toList();

    // Overview should exclude income transactions but include payment/other expense-side entries
    final expenseTotal = overviewExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final categoryBreakdown = _getCategoryBreakdown(overviewExpenses);
    final accountBreakdownExpenses = overviewExpenses;
    final accountBreakdown =
        _getPaymentAccountBreakdown(accountBreakdownExpenses);
    final accountBreakdownTotal = accountBreakdownExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    if (overviewExpenses.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No expense transactions for this period',
        subtitle: 'Try a different month or add a new expense',
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        contentBottomPadding(context),
      ),
      children: [
        _buildSectionTitle('Category Distribution'),
        const SizedBox(height: 8),
        _buildPieChartCard(context, categoryBreakdown, expenseTotal),
        const SizedBox(height: 16),
        _buildSectionTitle('Top 5 Expenses'),
        if (overviewExpenses.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Showing top 5 of ${overviewExpenses.length} expenses',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: _tabSecondaryTextColor(context),
              ),
            ),
          ),
        const SizedBox(height: 8),
        ...overviewExpenses.take(5).map((expense) => ExpenseCard(
              key: ValueKey(expense.id),
              expense: expense,
              onDeleted: _handleExpenseDeleted,
            )),
        const SizedBox(height: 16),
        _buildSectionTitle('Payment Account Breakdown'),
        const SizedBox(height: 8),
        ...accountBreakdown.entries.toList().asMap().entries.map((entry) {
          final accountName = entry.value.key;
          final accountAmount = entry.value.value;
          final percentage = accountBreakdownTotal > 0
              ? ((accountAmount / accountBreakdownTotal) * 100).toDouble()
              : 0.0;

          return _buildCategoryBreakdownItem(
            label: accountName,
            amount: accountAmount,
            percentage: percentage,
            color: _getBreakdownColor(entry.key),
            onTap: () {
              final accountExpenses = accountBreakdownExpenses
                  .where((expense) =>
                      _getExpenseAccountName(expense) == accountName)
                  .toList();

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _AccountTransactionsPage(
                    accountName: accountName,
                    expenses: accountExpenses,
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildCategoryTab(BuildContext context, List<Expense> expenses) {
    if (expenses.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No expenses for this period',
        subtitle: 'Try a different month or add new expenses',
      );
    }

    final grouped = _groupExpensesByCategory(expenses);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        contentBottomPadding(context),
      ),
      children: grouped.entries.map((entry) {
        final category = entry.key;
        final categoryExpenses = entry.value;
        final total = categoryExpenses.fold<double>(
            0, (sum, expense) => sum + expense.amount);
        final categoryData = _getCategoryData(context, category);
        final categoryColor = categoryData != null
            ? _hexToColor(categoryData.color)
            : AppTheme.primaryColor;
        final categoryIcon = categoryData?.icon ?? '📌';
        final isExpanded = _expandedCategories.contains(category);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.surface
              : AppTheme.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.borderColor),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
            ),
            child: ExpansionTile(
              key: PageStorageKey<String>('expense-category-$category'),
              initiallyExpanded: isExpanded,
              onExpansionChanged: (expanded) {
                setState(() {
                  if (expanded) {
                    _expandedCategories.add(category);
                  } else {
                    _expandedCategories.remove(category);
                  }
                });
              },
              tilePadding: const EdgeInsets.all(12),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    categoryIcon,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                  ),
                ),
              ),
              title: Text(
                category,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _tabPrimaryTextColor(context),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppUtils.formatCurrency(total,
                        currencySymbol:
                            context.read<SettingsProvider>().currencySymbol),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _tabPrimaryTextColor(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: _tabSecondaryTextColor(context),
                  ),
                ],
              ),
              children: categoryExpenses
                  .map((expense) => ExpenseCard(
                        key: ValueKey(expense.id),
                        expense: expense,
                        onDeleted: _handleExpenseDeleted,
                      ))
                  .toList(),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimelineTab(BuildContext context, List<Expense> expenses) {
    // Show all expenses including payments (loan, subscription, credit card)
    if (expenses.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No expenses for this period',
        subtitle: 'Try a different month or add new expenses',
      );
    }

    final query = _timelineSearchQuery.trim().toLowerCase();
    final filteredExpenses = query.isEmpty
        ? expenses
        : expenses.where((expense) {
            final haystack = [
              expense.title,
              expense.category,
              expense.paymentMethod,
              expense.notes ?? '',
              ...expense.tags,
            ].join(' ').toLowerCase();
            return haystack.contains(query);
          }).toList();

    final groupedByDate = _groupExpensesByDate(filteredExpenses);
    final groupedByCategory = _groupExpensesByCategory(filteredExpenses);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _timelineSearchController,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppTheme.textColor,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _timelineSearchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search timeline',
                    hintStyle: TextStyle(
                      fontFamily: 'Poppins',
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : AppTheme.textSecondaryColor,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : AppTheme.textSecondaryColor,
                    ),
                    suffixIcon: _timelineSearchQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white70
                                  : AppTheme.textSecondaryColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _timelineSearchController.clear();
                                _timelineSearchQuery = '';
                              });
                            },
                          ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.surface
                        : AppTheme.surfaceColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primaryColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _sortOption == SortOption.date
                    ? 'Date'
                    : _sortOption == SortOption.amount
                        ? 'Amount'
                        : 'Category',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _tabSecondaryTextColor(context),
                ),
              ),
              const SizedBox(width: 4),
              _buildSortButton(),
            ],
          ),
        ),
        Expanded(
          child: filteredExpenses.isEmpty
              ? _buildEmptyState(
                  icon: Icons.search_off,
                  title: 'No matching expenses',
                  subtitle: 'Try a different keyword',
                )
              : _sortOption == SortOption.category
                  ? ListView(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        contentBottomPadding(context),
                      ),
                      children: groupedByCategory.entries.map((entry) {
                        final category = entry.key;
                        final categoryExpenses = entry.value;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 8, top: 12),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _tabSecondaryTextColor(context),
                                ),
                              ),
                            ),
                            ...categoryExpenses.map((expense) => ExpenseCard(
                                  key: ValueKey(expense.id),
                                  expense: expense,
                                  onDeleted: _handleExpenseDeleted,
                                )),
                          ],
                        );
                      }).toList(),
                    )
                  : _sortOption == SortOption.amount
                      ? ListView(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            contentBottomPadding(context),
                          ),
                          children: filteredExpenses
                              .map((expense) => ExpenseCard(
                                    key: ValueKey(expense.id),
                                    expense: expense,
                                    onDeleted: _handleExpenseDeleted,
                                  ))
                              .toList(),
                        )
                      : ListView(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            contentBottomPadding(context),
                          ),
                          children: groupedByDate.entries.map((entry) {
                            final date = entry.key;
                            final dayExpenses = entry.value;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 8, top: 12),
                                  child: Text(
                                    AppUtils.formatDate(date),
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _tabSecondaryTextColor(context),
                                    ),
                                  ),
                                ),
                                ...dayExpenses.map((expense) => ExpenseCard(
                                      key: ValueKey(expense.id),
                                      expense: expense,
                                      onDeleted: _handleExpenseDeleted,
                                    )),
                              ],
                            );
                          }).toList(),
                        ),
        ),
      ],
    );
  }

  Widget _buildPieChartCard(
    BuildContext context,
    Map<String, double> breakdown,
    double totalAmount,
  ) {
    final sections =
        _buildPieChartSections(context, breakdown, totalAmount, _touchedIndex);
    final currencySymbol = context.read<SettingsProvider>().currencySymbol;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surface
            : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: 142,
              height: 142,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 19,
                  sections: sections,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      if (event is! FlTapUpEvent) {
                        return;
                      }

                      setState(() {
                        if (pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }

                        final tappedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                        _touchedIndex =
                            _touchedIndex == tappedIndex ? -1 : tappedIndex;
                      });
                    },
                  ),
                ),
                swapAnimationDuration: const Duration(milliseconds: 800),
                swapAnimationCurve: Curves.easeInOutCubic,
              ),
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 4) / 2;
              return Wrap(
                spacing: 4,
                runSpacing: 4,
                children: breakdown.entries.toList().asMap().entries.map(
                  (mapEntry) {
                    final index = mapEntry.key;
                    final entry = mapEntry.value;
                    final isSelected = index == _touchedIndex;

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          _touchedIndex = isSelected ? -1 : index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: itemWidth,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _getBreakdownColor(index).withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? _getBreakdownColor(index)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: isSelected ? 10 : 8,
                              height: isSelected ? 10 : 8,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: _getBreakdownColor(index),
                                shape: BoxShape.circle,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: _getBreakdownColor(index)
                                              .withOpacity(0.6),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${entry.key} (${_formatPercentLabel(entry.value, totalAmount)})',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: isSelected ? 11 : 10,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: _tabPrimaryTextColor(context),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    AppUtils.formatCurrency(entry.value,
                                        currencySymbol: currencySymbol),
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: isSelected ? 10 : 9,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: _tabSecondaryTextColor(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _tabPrimaryTextColor(context),
      ),
    );
  }

  Widget _buildCategoryBreakdownItem({
    required String label,
    required double amount,
    required double percentage,
    required Color color,
    VoidCallback? onTap,
  }) {
    final currencySymbol = context.read<SettingsProvider>().currencySymbol;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.surface
              : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _tabPrimaryTextColor(context),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppUtils.formatCurrency(amount,
                          currencySymbol: currencySymbol),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _tabSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 6,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<Expense>> _groupExpensesByCategory(List<Expense> expenses) {
    final grouped = <String, List<Expense>>{};
    for (final expense in expenses) {
      grouped.putIfAbsent(expense.category, () => []).add(expense);
    }
    return grouped;
  }

  Map<DateTime, List<Expense>> _groupExpensesByDate(List<Expense> expenses) {
    final grouped = <DateTime, List<Expense>>{};
    for (final expense in expenses) {
      final dateKey =
          DateTime(expense.date.year, expense.date.month, expense.date.day);
      grouped.putIfAbsent(dateKey, () => []).add(expense);
    }

    // Keep insertion order for non-date sorting so timeline reflects current sort.
    if (_sortOption != SortOption.date) {
      return grouped;
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => _sortAscending ? a.compareTo(b) : b.compareTo(a));
    return {for (final key in sortedKeys) key: grouped[key]!};
  }

  Widget _buildSortButton() {
    return PopupMenuButton<SortOption>(
      icon: const Icon(Icons.sort),
      tooltip: 'Sort by',
      onSelected: (option) {
        setState(() {
          if (_sortOption == option) {
            _sortAscending = !_sortAscending;
          } else {
            _sortOption = option;
            _sortAscending = false;
          }
        });
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: SortOption.date,
          child: Row(
            children: [
              Icon(
                _sortOption == SortOption.date
                    ? (_sortAscending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward)
                    : Icons.calendar_today,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text('Date'),
            ],
          ),
        ),
        PopupMenuItem(
          value: SortOption.amount,
          child: Row(
            children: [
              Icon(
                _sortOption == SortOption.amount
                    ? (_sortAscending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward)
                    : Icons.attach_money,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text('Amount'),
            ],
          ),
        ),
        PopupMenuItem(
          value: SortOption.category,
          child: Row(
            children: [
              Icon(
                _sortOption == SortOption.category
                    ? (_sortAscending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward)
                    : Icons.category,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text('Category'),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, double> _getCategoryBreakdown(List<Expense> expenses) {
    final breakdown = <String, double>{};
    for (final expense in expenses) {
      breakdown[expense.category] =
          (breakdown[expense.category] ?? 0) + expense.amount;
    }

    final sorted = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    const maxSlices = 8;
    if (sorted.length <= maxSlices) {
      return Map<String, double>.fromEntries(sorted);
    }

    final limited = sorted.take(maxSlices - 1).toList();
    final othersTotal = sorted
        .skip(maxSlices - 1)
        .fold<double>(0, (sum, entry) => sum + entry.value);

    return {
      for (final entry in limited) entry.key: entry.value,
      'Others': othersTotal,
    };
  }

  Map<String, double> _getPaymentAccountBreakdown(List<Expense> expenses) {
    final breakdown = <String, double>{};

    for (final expense in expenses) {
      final accountName = _getExpenseAccountName(expense);

      breakdown[accountName] = (breakdown[accountName] ?? 0) + expense.amount;
    }

    final sortedEntries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map<String, double>.fromEntries(sortedEntries);
  }

  bool _isAccountBreakdownTransaction(Expense expense) {
    final transactionType = expense.transactionType ?? 'expense';
    return transactionType != 'income' && transactionType != 'transfer';
  }

  String _getExpenseAccountName(Expense expense) {
    final accountProvider = context.read<PaymentAccountProvider>();

    if (expense.accountId != null && expense.accountId!.isNotEmpty) {
      final account = accountProvider.getAccountById(expense.accountId!);
      return account?.name ?? 'Deleted Account';
    }

    return 'Unassigned Account';
  }

  Color _getBreakdownColor(int index) {
    final palette = <Color>[
      AppTheme.primaryColor,
      Colors.teal,
      Colors.indigo,
      Colors.orange,
      Colors.purple,
      Colors.green,
      Colors.red,
      Colors.blue,
    ];
    return palette[index % palette.length];
  }

  String _formatPercentLabel(double value, double totalAmount) {
    final percentage = totalAmount > 0 ? ((value / totalAmount) * 100) : 0.0;
    if (percentage > 0 && percentage < 1) {
      return '<1%';
    }
    return '${percentage.toStringAsFixed(0)}%';
  }

  List<PieChartSectionData> _buildPieChartSections(
    BuildContext context,
    Map<String, double> breakdown,
    double totalAmount,
    int touchedIndex,
  ) {
    if (breakdown.isEmpty) {
      return [
        PieChartSectionData(
          value: 1,
          color: Colors.grey.shade300,
          radius: 39,
          showTitle: false,
        ),
      ];
    }

    int index = 0;
    return breakdown.entries.map((entry) {
      final isTouched = index == touchedIndex;
      final radius = isTouched ? 43.0 : 39.0;
      final fontSize = isTouched ? 14.0 : 12.0;
      final baseColor = _getBreakdownColor(index);
      final color =
          isTouched ? Color.lerp(baseColor, Colors.white, 0.2)! : baseColor;
      index++;

      return PieChartSectionData(
        value: entry.value,
        color: color,
        radius: radius,
        showTitle: true,
        title: _formatPercentLabel(entry.value, totalAmount),
        titleStyle: TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(isTouched ? 0.8 : 0.7),
              offset: const Offset(0.5, 0.5),
              blurRadius: isTouched ? 2.5 : 1.5,
            ),
          ],
        ),
      );
    }).toList();
  }

  ExpenseCategory? _getCategoryData(BuildContext context, String category) {
    final categories = context.read<ExpenseProvider>().categories;
    return categories.where((c) => c.name == category).firstOrNull;
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  Widget _buildSummaryCard(double totalAmount) {
    final currencySymbol = context.watch<SettingsProvider>().currencySymbol;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surface
            : null,
        gradient: Theme.of(context).brightness == Brightness.dark
            ? null
            : LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.7)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(14),
        border: Theme.of(context).brightness == Brightness.dark
            ? Border.all(color: Theme.of(context).dividerColor)
            : null,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.transparent
                : AppTheme.primaryColor.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _customDateRange != null
                    ? 'Custom Period'
                    : _getMonthYearString(_selectedMonth),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_customDateRange == null)
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.white),
                      iconSize: 24,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28),
                      onPressed: () {
                        setState(() {
                          _selectedMonth = DateTime(
                            _selectedMonth.year,
                            _selectedMonth.month - 1,
                          );
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.calendar_month,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.white),
                      iconSize: 22,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28),
                      tooltip: 'Select Date',
                      offset: const Offset(0, 40),
                      color: Colors.white,
                      onSelected: (value) {
                        if (value == 'month') {
                          _showMonthPicker();
                        } else if (value == 'range') {
                          _showDateRangePicker();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'month',
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 18, color: AppTheme.primaryColor),
                              const SizedBox(width: 12),
                              Text('Select Month',
                                  style: TextStyle(
                                      fontFamily: 'Poppins', fontSize: 13)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'range',
                          child: Row(
                            children: [
                              Icon(Icons.date_range,
                                  size: 18, color: AppTheme.primaryColor),
                              const SizedBox(width: 12),
                              Text('Select Date Range',
                                  style: TextStyle(
                                      fontFamily: 'Poppins', fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.chevron_right,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.white),
                      iconSize: 24,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28),
                      onPressed: () {
                        final nextMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month + 1,
                        );
                        if (nextMonth.isBefore(
                            DateTime.now().add(const Duration(days: 1)))) {
                          setState(() {
                            _selectedMonth = nextMonth;
                          });
                        }
                      },
                    ),
                  ],
                ),
              if (_customDateRange != null)
                PopupMenuButton<String>(
                  icon: Icon(Icons.date_range,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.white),
                  iconSize: 22,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28),
                  tooltip: 'Change Date Selection',
                  offset: const Offset(0, 40),
                  color: Colors.white,
                  onSelected: (value) {
                    if (value == 'month') {
                      setState(() {
                        _customDateRange = null;
                      });
                    } else if (value == 'range') {
                      _showDateRangePicker();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'month',
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 18, color: AppTheme.primaryColor),
                          const SizedBox(width: 12),
                          Text('Switch to Month View',
                              style: TextStyle(
                                  fontFamily: 'Poppins', fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'range',
                      child: Row(
                        children: [
                          Icon(Icons.date_range,
                              size: 18, color: AppTheme.primaryColor),
                          const SizedBox(width: 12),
                          Text('Change Date Range',
                              style: TextStyle(
                                  fontFamily: 'Poppins', fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppUtils.formatCurrency(totalAmount,
                  currencySymbol: currencySymbol),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_customDateRange != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppUtils.formatDateShort(_customDateRange!.start)} - ${AppUtils.formatDateShort(_customDateRange!.end)}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Colors.white.withOpacity(0.7),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _customDateRange = null;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Colors.white,
                            size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Clear',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
      });
    }
  }

  void _showMonthPicker() async {
    int selectedYear = _selectedMonth.year;
    int selectedMonth = _selectedMonth.month;

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Select Month',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Year Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () {
                            setState(() {
                              selectedYear--;
                            });
                          },
                        ),
                        Text(
                          '$selectedYear',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: selectedYear < DateTime.now().year
                              ? () {
                                  setState(() {
                                    selectedYear++;
                                  });
                                }
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Month Grid
                    GridView.builder(
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final month = index + 1;
                        final isSelected = selectedMonth == month;
                        final isFuture = selectedYear == DateTime.now().year &&
                            month > DateTime.now().month;

                        return InkWell(
                          onTap: isFuture
                              ? null
                              : () {
                                  setState(() {
                                    selectedMonth = month;
                                  });
                                },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : isFuture
                                      ? Colors.grey.shade200
                                      : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _getMonthShort(month),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : isFuture
                                          ? Colors.grey
                                          : AppTheme.textColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      DateTime(selectedYear, selectedMonth),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'Select',
                    style: TextStyle(
                        fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = null;
        _selectedMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  String _getMonthShort(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  String _getMonthYearString(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _handleExpenseDeleted(String expenseId) {
    if (!mounted) return;
    setState(() {
      _pendingDeletedExpenseIds.add(expenseId);
    });
  }
}

class _AccountTransactionsPage extends StatefulWidget {
  final String accountName;
  final List<Expense> expenses;

  const _AccountTransactionsPage({
    required this.accountName,
    required this.expenses,
  });

  @override
  State<_AccountTransactionsPage> createState() =>
      _AccountTransactionsPageState();
}

class _AccountTransactionsPageState extends State<_AccountTransactionsPage> {
  late List<Expense> _visibleExpenses;

  @override
  void initState() {
    super.initState();
    _visibleExpenses = List<Expense>.from(widget.expenses);
  }

  void _handleDeleted(String expenseId) {
    if (!mounted) return;
    setState(() {
      _visibleExpenses.removeWhere((e) => e.id == expenseId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.accountName),
      ),
      body: _visibleExpenses.isEmpty
          ? Center(
              child: Text(
                'No transactions found for this account in the selected period.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Text(
                  'Transactions',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                ..._visibleExpenses.map((expense) => ExpenseCard(
                      key: ValueKey(expense.id),
                      expense: expense,
                      dense: true,
                      onDeleted: _handleDeleted,
                    )),
              ],
            ),
    );
  }
}

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final bool dense;
  final ValueChanged<String>? onDeleted;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.dense = false,
    this.onDeleted,
  });

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  ExpenseCategory? _getCategoryData(BuildContext context) {
    final categories = context.read<ExpenseProvider>().categories;
    return categories.where((c) => c.name == expense.category).firstOrNull;
  }

  PaymentAccount? _getAccountData(BuildContext context) {
    if (expense.accountId == null || expense.accountId!.isEmpty) {
      return null;
    }
    final accountProvider = context.read<PaymentAccountProvider>();
    return accountProvider.getAccountById(expense.accountId!);
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.watch<SettingsProvider>().currencySymbol;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? Colors.white : AppTheme.textColor;
    final secondaryTextColor =
        isDarkMode ? Colors.white : AppTheme.textSecondaryColor;
    final categoryData = _getCategoryData(context);
    final categoryColor = categoryData != null
        ? _hexToColor(categoryData.color)
        : AppTheme.primaryColor;
    final categoryIcon = categoryData?.icon ?? '📌';
    final accountData = _getAccountData(context);
    final cardMargin = dense ? 8.0 : 12.0;
    final cardPadding = dense ? 10.0 : 12.0;
    final iconSize = dense ? 42.0 : 48.0;
    final iconFontSize = dense ? 20.0 : 24.0;
    final titleFontSize = dense ? 14.0 : 15.0;
    final amountFontSize = dense ? 15.0 : 16.0;
    final metadataFontSize = dense ? 10.0 : 11.0;
    final subMetaFontSize = dense ? 9.0 : 10.0;
    final trailingIconSize = dense ? 17.0 : 18.0;
    final titleToAmountSpacing = dense ? 3.0 : 4.0;
    final amountToMetaSpacing = dense ? 4.0 : 6.0;
    final betweenMetaRowsSpacing = dense ? 2.0 : 3.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExpenseDetailScreen(expense: expense),
          ),
        );
      },
      onLongPress: () {
        _showExpenseMenu(context);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: cardMargin),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.surface
              : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        padding: EdgeInsets.all(cardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  categoryIcon,
                  style:
                      TextStyle(fontFamily: 'Poppins', fontSize: iconFontSize),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: primaryTextColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: titleToAmountSpacing),
                  Text(
                    AppUtils.formatCurrency(expense.amount,
                        currencySymbol: currencySymbol),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: amountFontSize,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.errorColor,
                    ),
                  ),
                  SizedBox(height: amountToMetaSpacing),
                  Row(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 12,
                        color: secondaryTextColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          expense.category,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: metadataFontSize,
                            color: secondaryTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (expense.paymentMethod.isNotEmpty) ...[
                    SizedBox(height: betweenMetaRowsSpacing),
                    Row(
                      children: [
                        Icon(
                          Icons.payment,
                          size: 12,
                          color: secondaryTextColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            expense.paymentMethod,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: metadataFontSize,
                              color: secondaryTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: betweenMetaRowsSpacing),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 11,
                        color: secondaryTextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppUtils.formatDateShort(expense.date),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: subMetaFontSize,
                          color: secondaryTextColor,
                        ),
                      ),
                      if (accountData != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.account_balance_wallet,
                          size: 11,
                          color: secondaryTextColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            accountData.name,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: subMetaFontSize,
                              color: secondaryTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: IconButton(
                icon: Icon(Icons.more_vert, size: trailingIconSize),
                onPressed: () => _showExpenseMenu(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExpenseMenu(BuildContext context) {
    final parentContext = context;
    showModalBottomSheet(
      context: parentContext,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  parentContext,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddEditExpenseScreen(expense: expense),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.errorColor),
              title: const Text('Delete',
                  style: TextStyle(color: AppTheme.errorColor)),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDelete(parentContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final parentContext = context;
    final expenseProvider = parentContext.read<ExpenseProvider>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Reverse balance adjustments before deleting
              await _reverseTransactionEffects(parentContext, expense);
              await expenseProvider.deleteExpense(expense.id);

              onDeleted?.call(expense.id);

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _reverseTransactionEffects(
      BuildContext context, Expense expense) async {
    final accountProvider = context.read<PaymentAccountProvider>();
    final accounts = accountProvider.accounts;

    // Get source account
    final sourceAccount = accounts.firstWhere(
      (a) => a.id == expense.accountId,
      orElse: () => PaymentAccount(
        id: 'temp',
        name: 'Unknown',
        accountType: 'Unknown',
        createdAt: DateTime.now(),
      ),
    );

    final isCreditCard =
        sourceAccount.accountType.toLowerCase().contains('credit');

    final amount = expense.amount;
    final transactionType = expense.transactionType ?? 'expense';

    // Determine balance deltas (same as _applyTransactionEffects, then reverse)
    double sourceDelta = 0;
    double destinationDelta = 0;
    String? destinationId = expense.destinationAccountId;

    switch (transactionType) {
      case 'income':
        sourceDelta = isCreditCard ? -amount : amount;
        break;
      case 'transfer':
        sourceDelta = -amount;
        if (destinationId != null) {
          final destination = accounts.firstWhere(
            (a) => a.id == destinationId,
            orElse: () => PaymentAccount(
              id: 'temp',
              name: 'Unknown',
              accountType: 'Unknown',
              createdAt: DateTime.now(),
            ),
          );
          final isDestCredit =
              destination.accountType.toLowerCase().contains('credit');
          destinationDelta = isDestCredit ? -amount : amount;
        }
        break;
      case 'payment':
        sourceDelta = -amount;
        if (destinationId != null) {
          destinationDelta = -amount;
        }
        break;
      default: // expense
        sourceDelta = isCreditCard ? amount : -amount;
    }

    // Reverse the deltas (negate them)
    sourceDelta = -sourceDelta;
    destinationDelta = -destinationDelta;

    // Apply balance adjustments
    if (sourceDelta != 0) {
      final updatedSourceAccount = sourceAccount.copyWith(
        balance: sourceAccount.balance + sourceDelta,
      );
      await accountProvider.updateAccount(updatedSourceAccount);
    }

    // Update destination account if needed
    if (destinationId != null && destinationDelta != 0) {
      try {
        final destinationAccount = accounts.firstWhere(
          (a) => a.id == destinationId,
        );
        final updatedDestAccount = destinationAccount.copyWith(
          balance: destinationAccount.balance + destinationDelta,
        );
        await accountProvider.updateAccount(updatedDestAccount);
      } catch (e) {
        // Destination account not found, skip
      }
    }
  }
}

class ExpenseDetailScreen extends StatelessWidget {
  final Expense expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  String _getTransactionTypeLabel() {
    final transactionType = expense.transactionType ?? 'expense';
    switch (transactionType) {
      case 'expense':
        return '💸 Expense';
      case 'income':
        return '💰 Income';
      case 'transfer':
        return '🔄 Transfer';
      case 'payment':
        return '💳 Payment';
      default:
        return transactionType;
    }
  }

  String _getAccountName(BuildContext context) {
    final accountProvider = context.read<PaymentAccountProvider>();

    if (expense.accountId != null && expense.accountId!.isNotEmpty) {
      final account = accountProvider.getAccountById(expense.accountId!);
      return account?.name ?? 'Deleted Account';
    }

    return 'No Account';
  }

  String _getAccountType(BuildContext context) {
    final accountProvider = context.read<PaymentAccountProvider>();

    if (expense.accountId != null && expense.accountId!.isNotEmpty) {
      final account = accountProvider.getAccountById(expense.accountId!);
      return account?.accountType ?? 'Unknown Account Type';
    }

    return 'No Account Type';
  }

  bool _showsDestinationAccount() {
    final transactionType = expense.transactionType ?? 'expense';
    return (transactionType == 'transfer' || transactionType == 'payment') &&
        expense.destinationAccountId != null &&
        expense.destinationAccountId!.isNotEmpty;
  }

  String _getDestinationAccountName(BuildContext context) {
    final accountProvider = context.read<PaymentAccountProvider>();
    final destinationId = expense.destinationAccountId;

    if (destinationId != null && destinationId.isNotEmpty) {
      final account = accountProvider.getAccountById(destinationId);
      return account?.name ?? 'Deleted Account';
    }

    return 'No Destination Account';
  }

  String _getDestinationAccountType(BuildContext context) {
    final accountProvider = context.read<PaymentAccountProvider>();
    final destinationId = expense.destinationAccountId;

    if (destinationId != null && destinationId.isNotEmpty) {
      final account = accountProvider.getAccountById(destinationId);
      return account?.accountType ?? 'Unknown Account Type';
    }

    return 'No Destination Account Type';
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.watch<SettingsProvider>().currencySymbol;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            contentBottomPadding(context, hasFab: false),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Amount Card
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDarkMode
                        ? [const Color(0xFF1E3A5F), const Color(0xFF2E4A6F)]
                        : [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withOpacity(0.8)
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      AppUtils.formatCurrency(expense.amount,
                          currencySymbol: currencySymbol),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        expense.category,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Transaction Details Card
              _ModernDetailCard(
                icon: Icons.receipt_long,
                label: 'Transaction',
                value: expense.title,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 12),
              _ModernDetailCard(
                icon: Icons.calendar_today,
                label: 'Date',
                value: AppUtils.formatDate(expense.date),
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 12),
              _ModernDetailCard(
                icon: Icons.swap_horiz,
                label: 'Transaction Type',
                value: _getTransactionTypeLabel(),
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 12),
              _ModernDetailCard(
                icon: Icons.account_balance_wallet,
                label: 'From Account',
                value: _getAccountName(context),
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 12),
              _ModernDetailCard(
                icon: Icons.category,
                label: 'From Account Type',
                value: _getAccountType(context),
                isDarkMode: isDarkMode,
              ),
              if (_showsDestinationAccount()) ...[
                const SizedBox(height: 12),
                _ModernDetailCard(
                  icon: Icons.call_made,
                  label: 'To Account',
                  value: _getDestinationAccountName(context),
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 12),
                _ModernDetailCard(
                  icon: Icons.account_tree,
                  label: 'To Account Type',
                  value: _getDestinationAccountType(context),
                  isDarkMode: isDarkMode,
                ),
              ],
              if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _ModernDetailCard(
                  icon: Icons.notes,
                  label: 'Notes',
                  value: expense.notes!,
                  isDarkMode: isDarkMode,
                ),
              ],
              if (expense.tags.isNotEmpty) ...[
                const SizedBox(height: 20),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.local_offer,
                              size: 18,
                              color: isDarkMode
                                  ? Colors.white70
                                  : AppTheme.textSecondaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tags',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode
                                    ? Colors.white
                                    : AppTheme.textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: expense.tags
                              .map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      tag,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernDetailCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDarkMode;

  const _ModernDetailCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode
                          ? Colors.white60
                          : AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : AppTheme.textColor,
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

class AddEditExpenseScreen extends StatefulWidget {
  final Expense? expense;
  final String? initialAccountId;
  final String? initialTransactionType;
  final double? initialAmount;
  final String? initialDestinationAccountId;

  const AddEditExpenseScreen({
    super.key,
    this.expense,
    this.initialAccountId,
    this.initialTransactionType,
    this.initialAmount,
    this.initialDestinationAccountId,
  });

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  late TextEditingController titleController;
  late TextEditingController amountController;
  late TextEditingController notesController;
  late DateTime selectedDate;
  late String selectedCategory;
  late String selectedPaymentMethod;
  String? selectedAccountType;
  String? selectedAccountId;
  String selectedTransactionType =
      'expense'; // 'expense', 'income', 'transfer', 'payment'
  String? selectedDestinationAccountId;

  String _getPreferredIncomeCategory(List<ExpenseCategory> categories) {
    for (final category in categories) {
      if (category.name.toLowerCase().contains('income')) {
        return category.name;
      }
    }
    return categories.isNotEmpty ? categories.first.name : 'Income';
  }

  @override
  void initState() {
    super.initState();
    final categories = context.read<ExpenseProvider>().categories;
    final accounts = context.read<PaymentAccountProvider>().accounts;

    if (widget.expense != null) {
      titleController = TextEditingController(text: widget.expense!.title);
      amountController =
          TextEditingController(text: widget.expense!.amount.toString());
      notesController = TextEditingController(text: widget.expense!.notes);
      selectedDate = widget.expense!.date;
      selectedCategory = widget.expense!.category;
      selectedPaymentMethod = widget.expense!.paymentMethod;
      selectedAccountId = widget.expense!.accountId;
      selectedTransactionType = widget.expense!.transactionType ?? 'expense';
      selectedDestinationAccountId = widget.expense!.destinationAccountId;

      // Find account type from account ID
      if (selectedAccountId != null) {
        final account = accounts.firstWhere(
          (a) => a.id == selectedAccountId,
          orElse: () => accounts.isNotEmpty
              ? accounts.first
              : PaymentAccount(
                  id: 'temp',
                  name: 'Cash',
                  accountType: 'Cash',
                  createdAt: DateTime.now(),
                ),
        );
        selectedAccountType = account.accountType;
      }
    } else {
      titleController = TextEditingController();
      amountController = TextEditingController(
        text:
            widget.initialAmount != null ? widget.initialAmount.toString() : '',
      );
      notesController = TextEditingController();
      selectedDate = DateTime.now();

      // Set category based on transaction type
      selectedTransactionType = widget.initialTransactionType ?? 'expense';
      if (selectedTransactionType == 'payment') {
        selectedCategory = 'Credit Card Payment';
      } else if (selectedTransactionType == 'transfer') {
        selectedCategory = 'Transfer';
      } else if (selectedTransactionType == 'income') {
        // Check if it's a credit card account (refund) or regular income
        if (widget.initialAccountId != null) {
          try {
            final account = accounts.firstWhere(
              (a) => a.id == widget.initialAccountId,
            );
            selectedCategory =
                account.accountType.toLowerCase().contains('credit')
                    ? 'Refund'
                    : _getPreferredIncomeCategory(categories);
          } catch (e) {
            selectedCategory = _getPreferredIncomeCategory(categories);
          }
        } else {
          selectedCategory = _getPreferredIncomeCategory(categories);
        }
      } else {
        selectedCategory =
            categories.isNotEmpty ? categories.first.name : 'Food';
      }

      selectedPaymentMethod = 'Cash';
      selectedDestinationAccountId = widget.initialDestinationAccountId;
      // Use initial account ID if provided
      selectedAccountId = widget.initialAccountId;

      // If initialAccountId is provided, set the account type from that account
      if (widget.initialAccountId != null) {
        try {
          final initialAccount = accounts.firstWhere(
            (a) => a.id == widget.initialAccountId,
          );
          selectedAccountType = initialAccount.accountType;
          selectedPaymentMethod = initialAccount.accountType;
        } catch (e) {
          selectedAccountType = null;
        }
      } else {
        selectedAccountType = null;
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.watch<SettingsProvider>().currencySymbol;
    final categories = context.watch<ExpenseProvider>().categories;
    return Scaffold(
      appBar: AppBar(
        title: Text(_getFormTitle()),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Close',
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'Manage Categories',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageExpenseCategoriesScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter expense title',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                hintText: 'Enter amount',
                prefixText: '$currencySymbol ',
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickExpenseDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      AppUtils.formatDate(selectedDate),
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Internal transfers should not be categorized as expenses.
            if (selectedTransactionType != 'income' &&
                selectedTransactionType != 'transfer')
              DropdownButtonFormField<String>(
                value: categories.any((c) => c.name == selectedCategory)
                    ? selectedCategory
                    : (categories.isNotEmpty ? categories.first.name : null),
                decoration: InputDecoration(
                  labelText: 'Category',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.settings, size: 20),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ManageExpenseCategoriesScreen(),
                        ),
                      );
                    },
                  ),
                ),
                items: categories.isEmpty
                    ? [
                        const DropdownMenuItem(
                          value: 'Others',
                          child: Text('Others'),
                        )
                      ]
                    : categories
                        .map((category) => DropdownMenuItem(
                              value: category.name,
                              child: Row(
                                children: [
                                  Text(category.icon,
                                      style: TextStyle(
                                          fontFamily: 'Poppins', fontSize: 18)),
                                  const SizedBox(width: 8),
                                  Text(category.name),
                                ],
                              ),
                            ))
                        .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedCategory = value);
                  }
                },
              ),
            if (selectedTransactionType != 'income' &&
                selectedTransactionType != 'transfer')
              const SizedBox(height: 16),
            // Only show account type and account selectors if not coming from a specific account
            if (widget.initialAccountId == null)
              Consumer2<PaymentAccountProvider, AccountTypeProvider>(
                builder: (context, accountProvider, accountTypeProvider, _) {
                  final accounts = accountProvider.accounts;
                  final accountTypes = accountTypeProvider.activeAccountTypes;

                  // Ensure selectedAccountType is valid
                  final validAccountTypeNames =
                      accountTypes.map((t) => t.name).toList();
                  final validatedAccountType = (selectedAccountType != null &&
                          validAccountTypeNames.contains(selectedAccountType))
                      ? selectedAccountType
                      : null;

                  return Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: validatedAccountType,
                        decoration: const InputDecoration(
                          labelText: 'Account Type',
                          helperText: 'Select the type of payment account',
                        ),
                        items: accountTypes.map((type) {
                          return DropdownMenuItem(
                            value: type.name,
                            child: Row(
                              children: [
                                Text(type.icon ?? '📌',
                                    style: TextStyle(
                                        fontFamily: 'Poppins', fontSize: 18)),
                                const SizedBox(width: 8),
                                Text(type.name),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedAccountType = value;
                            selectedPaymentMethod = value ?? '';
                            selectedAccountId = null; // Reset account selection
                            selectedTransactionType = 'expense';
                            selectedDestinationAccountId = null;
                          });
                        },
                      ),
                      if (selectedAccountType != null) ...[
                        const SizedBox(height: 16),
                        Builder(
                          builder: (context) {
                            final filteredAccounts = accounts
                                .where((a) =>
                                    a.accountType == selectedAccountType &&
                                    a.isActive)
                                .toList();
                            final hasFilteredAccounts =
                                filteredAccounts.isNotEmpty;

                            // Ensure selectedAccountId is valid
                            final validAccountIds =
                                filteredAccounts.map((a) => a.id).toList();
                            final validatedAccountId = (selectedAccountId !=
                                        null &&
                                    validAccountIds.contains(selectedAccountId))
                                ? selectedAccountId
                                : null;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButtonFormField<String>(
                                  value: validatedAccountId,
                                  decoration: InputDecoration(
                                    labelText: 'Specific Account',
                                    helperText: 'Choose which account to use',
                                  ),
                                  hint: hasFilteredAccounts
                                      ? null
                                      : const Text('No accounts available'),
                                  items: filteredAccounts.map((account) {
                                    return DropdownMenuItem(
                                      value: account.id,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (account.icon != null)
                                            Text('${account.icon} ',
                                                style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 18)),
                                          Flexible(
                                            child: Text(
                                              account.name,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (account.balance != 0)
                                            Text(
                                              ' (${AppUtils.formatCurrency(account.balance, currencySymbol: context.read<SettingsProvider>().currencySymbol)})',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    AppTheme.textSecondaryColor,
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: hasFilteredAccounts
                                      ? (value) {
                                          setState(() {
                                            selectedAccountId = value;
                                            final account = accounts.firstWhere(
                                              (a) => a.id == value,
                                              orElse: () => null as dynamic,
                                            ) as PaymentAccount?;
                                            if (account != null) {
                                              final allowedTypes = account
                                                          .accountType ==
                                                      'Credit Card'
                                                  ? [
                                                      'expense',
                                                      'income',
                                                      'payment'
                                                    ]
                                                  : [
                                                      'expense',
                                                      'income',
                                                      'transfer'
                                                    ];
                                              if (!allowedTypes.contains(
                                                  selectedTransactionType)) {
                                                selectedTransactionType =
                                                    allowedTypes.first;
                                                selectedDestinationAccountId =
                                                    null;
                                              }
                                            }
                                          });
                                        }
                                      : null,
                                ),
                                if (!hasFilteredAccounts)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Add an account under this type in Accounts before saving this expense.',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  );
                },
              ),
            const SizedBox(height: 16),
            // Transaction Type Selection - only show if not predefined from account
            if (widget.initialTransactionType == null)
              Consumer<PaymentAccountProvider>(
                builder: (context, accountProvider, _) {
                  final selectedAccount = selectedAccountId != null
                      ? accountProvider.accounts.firstWhere(
                          (a) => a.id == selectedAccountId,
                          orElse: () => null as dynamic,
                        ) as PaymentAccount?
                      : null;
                  final isCreditCard = selectedAccount?.accountType
                          .toLowerCase()
                          .contains('credit') ??
                      false;

                  // Determine available transaction types based on account type
                  final List<String> availableTypes = [];
                  if (selectedAccount != null) {
                    if (selectedAccount.accountType == 'Credit Card') {
                      availableTypes.addAll(['expense', 'income', 'payment']);
                    } else {
                      // Bank Account and other types
                      availableTypes.addAll(['expense', 'income', 'transfer']);
                    }
                  } else {
                    availableTypes.addAll(['expense', 'income']);
                  }

                  return Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: availableTypes.contains(selectedTransactionType)
                            ? selectedTransactionType
                            : availableTypes.first,
                        decoration: const InputDecoration(
                          labelText: 'Transaction Type',
                          helperText: 'Select transaction type',
                        ),
                        items: availableTypes.map((type) {
                          final labels = {
                            'expense': '💸 Expense',
                            'income': isCreditCard ? '💰 Refund' : '💰 Income',
                            'transfer': '🔄 Transfer',
                            'payment': '💳 Payment',
                          };
                          return DropdownMenuItem(
                            value: type,
                            child: Text(labels[type] ?? type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedTransactionType = value;
                              selectedDestinationAccountId = null;
                              final categories =
                                  context.read<ExpenseProvider>().categories;
                              if (value == 'income') {
                                selectedCategory = isCreditCard
                                    ? 'Refund'
                                    : _getPreferredIncomeCategory(categories);
                              } else if (value == 'transfer') {
                                selectedCategory = 'Transfer';
                              } else if (value == 'payment') {
                                selectedCategory = 'Credit Card Payment';
                              } else if (!categories
                                  .any((c) => c.name == selectedCategory)) {
                                selectedCategory = categories.isNotEmpty
                                    ? categories.first.name
                                    : 'Food';
                              }
                            });
                          }
                        },
                      ),
                      // Destination Account for transfers and payments
                      if (selectedTransactionType == 'transfer' ||
                          selectedTransactionType == 'payment') ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedDestinationAccountId,
                          decoration: InputDecoration(
                            labelText: selectedTransactionType == 'transfer'
                                ? 'Transfer To'
                                : 'Payment From',
                            helperText: selectedTransactionType == 'transfer'
                                ? 'Select destination account'
                                : 'Select bank account to pay from',
                          ),
                          items: accountProvider.accounts.where((account) {
                            if (!account.isActive ||
                                account.id == selectedAccountId) {
                              return false;
                            }
                            // For both transfer and payment, show only bank accounts
                            return account.accountType
                                .toLowerCase()
                                .contains('bank');
                          }).map((account) {
                            return DropdownMenuItem(
                              value: account.id,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (account.icon != null)
                                    Text('${account.icon} ',
                                        style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18)),
                                  Flexible(
                                    child: Text(
                                      account.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedDestinationAccountId = value;
                            });
                          },
                        ),
                      ],
                    ],
                  );
                },
              )
            else
              // When from account, only show destination selector if needed
              Consumer<PaymentAccountProvider>(
                builder: (context, accountProvider, _) {
                  return Column(
                    children: [
                      if (selectedTransactionType == 'transfer' ||
                          selectedTransactionType == 'payment') ...[
                        DropdownButtonFormField<String>(
                          value: selectedDestinationAccountId,
                          decoration: InputDecoration(
                            labelText: selectedTransactionType == 'transfer'
                                ? 'Transfer To'
                                : 'Payment From',
                            helperText: selectedTransactionType == 'transfer'
                                ? 'Select destination account'
                                : 'Select bank account to pay from',
                          ),
                          items: accountProvider.accounts.where((account) {
                            if (!account.isActive ||
                                account.id == selectedAccountId) {
                              return false;
                            }
                            // For both transfer and payment, show only bank accounts
                            return account.accountType
                                .toLowerCase()
                                .contains('bank');
                          }).map((account) {
                            return DropdownMenuItem(
                              value: account.id,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (account.icon != null)
                                    Text('${account.icon} ',
                                        style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18)),
                                  Flexible(
                                    child: Text(
                                      account.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedDestinationAccountId = value;
                            });
                          },
                        ),
                      ],
                    ],
                  );
                },
              ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Add any notes',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveExpense,
                child: Text(_getSubmitLabel()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isCreditAccountById(String? accountId) {
    if (accountId == null) return false;
    final account = context.read<PaymentAccountProvider>().getAccountById(
          accountId,
        );
    return account != null &&
        account.accountType.toLowerCase().contains('credit');
  }

  String _getTransactionLabel(String type) {
    if (type == 'income' && _isCreditAccountById(selectedAccountId)) {
      return 'Refund';
    }

    switch (type) {
      case 'income':
        return 'Income';
      case 'transfer':
        return 'Transfer';
      case 'payment':
        return 'Payment';
      default:
        return 'Expense';
    }
  }

  String _getFormTitle() {
    final label = _getTransactionLabel(selectedTransactionType);
    return widget.expense == null ? 'Add $label' : 'Edit $label';
  }

  String _getSubmitLabel() {
    final label = _getTransactionLabel(selectedTransactionType);
    return widget.expense == null ? 'Add $label' : 'Update $label';
  }

  bool _isCreditAccount(PaymentAccount account) {
    return account.accountType.toLowerCase().contains('credit');
  }

  Future<void> _applyTransactionEffects(Expense expense,
      {required bool reverse}) async {
    final accountProvider = context.read<PaymentAccountProvider>();
    final sourceId = expense.accountId;
    if (sourceId == null) return;

    final sourceAccount = accountProvider.getAccountById(sourceId);
    if (sourceAccount == null) return;

    final amount = expense.amount;
    final transactionType = expense.transactionType ?? 'expense';

    double sourceDelta = 0;
    double destinationDelta = 0;
    String? destinationId = expense.destinationAccountId;

    switch (transactionType) {
      case 'income':
        sourceDelta = _isCreditAccount(sourceAccount) ? -amount : amount;
        break;
      case 'transfer':
        sourceDelta = -amount;
        if (destinationId != null) {
          final destination = accountProvider.getAccountById(destinationId);
          if (destination != null) {
            destinationDelta = _isCreditAccount(destination) ? -amount : amount;
          }
        }
        break;
      case 'payment':
        sourceDelta = -amount;
        if (destinationId != null) {
          destinationDelta = -amount;
        }
        break;
      default:
        sourceDelta = _isCreditAccount(sourceAccount) ? amount : -amount;
    }

    if (reverse) {
      sourceDelta = -sourceDelta;
      destinationDelta = -destinationDelta;
    }

    await accountProvider.adjustAccountBalance(sourceId, sourceDelta);
    if (destinationId != null && destinationDelta != 0) {
      await accountProvider.adjustAccountBalance(
          destinationId, destinationDelta);
    }
  }

  Future<void> _saveExpense() async {
    final title = titleController.text.trim();
    final amount = double.tryParse(amountController.text) ?? 0;

    if (title.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account')),
      );
      return;
    }

    // For transfers and payments, validate destination account is selected
    if ((selectedTransactionType == 'transfer' ||
            selectedTransactionType == 'payment') &&
        selectedDestinationAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination account')),
      );
      return;
    }

    final expense = widget.expense?.copyWith(
          title: title,
          amount: amount,
          category: selectedCategory,
          paymentMethod: selectedPaymentMethod,
          notes: notesController.text,
          date: selectedDate,
          accountId: selectedAccountId,
          transactionType: selectedTransactionType,
          destinationAccountId: selectedDestinationAccountId,
        ) ??
        Expense(
          id: AppUtils.generateId(),
          title: title,
          amount: amount,
          category: selectedCategory,
          paymentMethod: selectedPaymentMethod,
          notes: notesController.text.isEmpty ? null : notesController.text,
          date: selectedDate,
          accountId: selectedAccountId,
          transactionType: selectedTransactionType,
          destinationAccountId: selectedDestinationAccountId,
        );

    if (widget.expense != null) {
      final expenseProvider = context.read<ExpenseProvider>();
      await _applyTransactionEffects(widget.expense!, reverse: true);
      expenseProvider.updateExpense(expense);
      await _applyTransactionEffects(expense, reverse: false);
    } else {
      final expenseProvider = context.read<ExpenseProvider>();
      expenseProvider.addExpense(expense);
      await _applyTransactionEffects(expense, reverse: false);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _pickExpenseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }
}
