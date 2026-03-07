import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/core/constants/app_constants.dart';
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
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, _) {
          final allExpenses = provider.expenses;

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

          // Sort expenses for list usage
          final sortedExpenses = List<Expense>.from(filteredExpenses);
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

          final totalAmount = filteredExpenses.fold<double>(
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
                        labelStyle:
                            GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
              _buildSummaryCard(totalAmount, filteredExpenses.length),

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
      floatingActionButton: FloatingActionButton(
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppTheme.primaryColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _tabPrimaryTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: _tabSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    List<Expense> expenses,
    double totalAmount,
  ) {
    // Overview should reflect expense entries only.
    final expenseEntries = expenses
        .where((expense) => (expense.transactionType ?? 'expense') == 'expense')
        .toList();
    final expenseTotal = expenseEntries.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final categoryBreakdown = _getCategoryBreakdown(expenseEntries);

    if (expenseEntries.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No expense transactions for this period',
        subtitle: 'Try a different month or add a new expense',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPieChartCard(context, categoryBreakdown, expenseTotal),
        const SizedBox(height: 16),
        _buildSectionTitle('Top 5 Expenses'),
        const SizedBox(height: 8),
        ...expenseEntries
            .take(5)
            .map((expense) => ExpenseCard(expense: expense)),
        if (expenseEntries.length > 5)
          Text(
            'Showing top 5 of ${expenseEntries.length} expenses',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: _tabSecondaryTextColor(context),
            ),
          ),
        const SizedBox(height: 16),
        _buildSectionTitle('Category Breakdown'),
        const SizedBox(height: 8),
        ...categoryBreakdown.entries.map((entry) {
          final categoryName = entry.key;
          final categoryAmount = entry.value;
          final percentage = expenseTotal > 0
              ? ((categoryAmount / expenseTotal) * 100).toDouble()
              : 0.0;

          final categoryData = _getCategoryData(context, categoryName);
          final categoryColor = categoryData != null
              ? _hexToColor(categoryData.color)
              : AppTheme.primaryColor;

          return _buildCategoryBreakdownItem(
            label: categoryName,
            amount: categoryAmount,
            percentage: percentage,
            color: categoryColor,
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
      padding: const EdgeInsets.all(16),
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
                    style: GoogleFonts.poppins(fontSize: 18),
                  ),
                ),
              ),
              title: Text(
                category,
                style: GoogleFonts.poppins(
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
                    style: GoogleFonts.poppins(
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
                  .map((expense) => ExpenseCard(expense: expense))
                  .toList(),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimelineTab(BuildContext context, List<Expense> expenses) {
    // Filter to show only expense transactions
    final expenseEntries = expenses
        .where((e) => (e.transactionType ?? 'expense') == 'expense')
        .toList();

    if (expenseEntries.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No expenses for this period',
        subtitle: 'Try a different month or add new expenses',
      );
    }

    final query = _timelineSearchQuery.trim().toLowerCase();
    final filteredExpenses = query.isEmpty
        ? expenseEntries
        : expenseEntries.where((expense) {
            final haystack = [
              expense.title,
              expense.category,
              expense.paymentMethod,
              expense.notes ?? '',
              ...expense.tags,
            ].join(' ').toLowerCase();
            return haystack.contains(query);
          }).toList();

    final grouped = _groupExpensesByDate(filteredExpenses);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _timelineSearchController,
                  style: GoogleFonts.poppins(
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
                    hintStyle: GoogleFonts.poppins(
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
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: grouped.entries.map((entry) {
                    final date = entry.key;
                    final dayExpenses = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, top: 12),
                          child: Text(
                            AppUtils.formatDate(date),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _tabSecondaryTextColor(context),
                            ),
                          ),
                        ),
                        ...dayExpenses
                            .map((expense) => ExpenseCard(expense: expense)),
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
    final sections = _buildPieChartSections(context, breakdown, totalAmount);
    final currencySymbol = context.read<SettingsProvider>().currencySymbol;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surface
            : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                sections: sections,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category Distribution',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _tabPrimaryTextColor(context),
                  ),
                ),
                const SizedBox(height: 12),
                ...breakdown.entries.take(4).map(
                  (entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _getCategoryColor(context, entry.key),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _tabPrimaryTextColor(context),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  AppUtils.formatCurrency(entry.value,
                                      currencySymbol: currencySymbol),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: _tabSecondaryTextColor(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
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
  }) {
    final currencySymbol = context.read<SettingsProvider>().currencySymbol;

    return Container(
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
                  style: GoogleFonts.poppins(
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
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppUtils.formatCurrency(amount,
                        currencySymbol: currencySymbol),
                    style: GoogleFonts.poppins(
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
    return breakdown;
  }

  List<PieChartSectionData> _buildPieChartSections(
    BuildContext context,
    Map<String, double> breakdown,
    double totalAmount,
  ) {
    if (breakdown.isEmpty) {
      return [
        PieChartSectionData(
          value: 1,
          color: Colors.grey.shade300,
          radius: 18,
          showTitle: false,
        ),
      ];
    }

    return breakdown.entries.map((entry) {
      final percentage =
          totalAmount > 0 ? ((entry.value / totalAmount) * 100) : 0.0;

      return PieChartSectionData(
        value: entry.value,
        color: _getCategoryColor(context, entry.key),
        radius: 25,
        showTitle: true,
        title: '${percentage.toStringAsFixed(0)}%',
        titleStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.7),
              offset: const Offset(0.5, 0.5),
              blurRadius: 1.5,
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

  Color _getCategoryColor(BuildContext context, String category) {
    final categoryData = _getCategoryData(context, category);
    return categoryData != null
        ? _hexToColor(categoryData.color)
        : AppTheme.primaryColor;
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  Widget _buildSummaryCard(double totalAmount, int expenseCount) {
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _customDateRange != null
                          ? 'Custom Period'
                          : _getMonthYearString(_selectedMonth),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppUtils.formatCurrency(totalAmount,
                          currencySymbol: currencySymbol),
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.white,
                      ),
                    ),
                  ],
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
                      constraints: const BoxConstraints(),
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
                      constraints: const BoxConstraints(),
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
                                  style: GoogleFonts.poppins(fontSize: 13)),
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
                                  style: GoogleFonts.poppins(fontSize: 13)),
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
                      constraints: const BoxConstraints(),
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
                  constraints: const BoxConstraints(),
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
                              style: GoogleFonts.poppins(fontSize: 13)),
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
                              style: GoogleFonts.poppins(fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (_customDateRange != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppUtils.formatDateShort(_customDateRange!.start)} - ${AppUtils.formatDateShort(_customDateRange!.end)}',
                  style: GoogleFonts.poppins(
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
                          ? Theme.of(context).colorScheme.surfaceVariant
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
                          style: GoogleFonts.poppins(
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
                style: GoogleFonts.poppins(
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
                          style: GoogleFonts.poppins(
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
                                style: GoogleFonts.poppins(
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
                    style: GoogleFonts.poppins(),
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
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
}

class ExpenseCard extends StatelessWidget {
  final Expense expense;

  const ExpenseCard({super.key, required this.expense});

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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.surface
              : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  categoryIcon,
                  style: GoogleFonts.poppins(fontSize: 24),
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
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 12,
                        color: secondaryTextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        expense.category,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: secondaryTextColor,
                        ),
                      ),
                      if (expense.paymentMethod.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.payment,
                          size: 12,
                          color: secondaryTextColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            expense.paymentMethod,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: secondaryTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        AppUtils.formatDateShort(expense.date),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: secondaryTextColor,
                        ),
                      ),
                      if (accountData != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.account_balance_wallet,
                          size: 10,
                          color: secondaryTextColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            accountData.name,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
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
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppUtils.formatCurrency(expense.amount,
                      currencySymbol: currencySymbol),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.errorColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onPressed: () => _showExpenseMenu(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showExpenseMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
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
                Navigator.pop(context);
                _confirmDelete(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Reverse balance adjustments before deleting
              await _reverseTransactionEffects(context, expense);
              context.read<ExpenseProvider>().deleteExpense(expense.id);
              Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.watch<SettingsProvider>().currencySymbol;
    return Scaffold(
      appBar: AppBar(
        title: Text(expense.title),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      AppUtils.formatCurrency(expense.amount,
                          currencySymbol: currencySymbol),
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      expense.category,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _DetailRow(
              label: 'Date',
              value: AppUtils.formatDate(expense.date),
            ),
            _DetailRow(
              label: 'Payment Method',
              value: expense.paymentMethod,
            ),
            if (expense.notes != null && expense.notes!.isNotEmpty)
              _DetailRow(
                label: 'Notes',
                value: expense.notes!,
              ),
            if (expense.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Tags',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children:
                    expense.tags.map((tag) => Chip(label: Text(tag))).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
          ),
        ],
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
      } else if (selectedTransactionType == 'income') {
        // Check if it's a credit card account (refund) or regular income
        if (widget.initialAccountId != null) {
          try {
            final account = accounts.firstWhere(
              (a) => a.id == widget.initialAccountId,
            );
            selectedCategory = account.accountType
                    .toLowerCase()
                    .contains('credit')
                ? 'Refund'
                : (categories.isNotEmpty ? categories.first.name : 'Income');
          } catch (e) {
            selectedCategory =
                categories.isNotEmpty ? categories.first.name : 'Income';
          }
        } else {
          selectedCategory =
              categories.isNotEmpty ? categories.first.name : 'Income';
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
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Only show category if not coming from a specific account
            if (widget.initialAccountId == null)
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
                                      style: GoogleFonts.poppins(fontSize: 18)),
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
                                    style: GoogleFonts.poppins(fontSize: 18)),
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
                                                style: GoogleFonts.poppins(
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
                                        style:
                                            GoogleFonts.poppins(fontSize: 18)),
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
                                        style:
                                            GoogleFonts.poppins(fontSize: 18)),
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
      await _applyTransactionEffects(widget.expense!, reverse: true);
      context.read<ExpenseProvider>().updateExpense(expense);
      await _applyTransactionEffects(expense, reverse: false);
    } else {
      context.read<ExpenseProvider>().addExpense(expense);
      await _applyTransactionEffects(expense, reverse: false);
    }

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
