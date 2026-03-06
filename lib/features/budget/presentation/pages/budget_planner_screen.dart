import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/core/constants/app_constants.dart';
import 'package:fintrack/core/utils/custom_widgets.dart';
import 'package:fintrack/features/budget/data/models/budget_model.dart';
import 'package:fintrack/features/budget/presentation/providers/budget_provider.dart';
import 'package:fintrack/features/expense/data/models/expense_model.dart';
import 'package:fintrack/features/expense/presentation/providers/expense_provider.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';

class BudgetPlannerScreen extends StatefulWidget {
  final bool showAppBar;
  final bool showBackButton;

  const BudgetPlannerScreen({
    super.key,
    this.showAppBar = true,
    this.showBackButton = false,
  });

  @override
  State<BudgetPlannerScreen> createState() => _BudgetPlannerScreenState();
}

class _BudgetPlannerScreenState extends State<BudgetPlannerScreen>
    with TickerProviderStateMixin {
  DateTime _selectedMonth = DateTime.now();
  bool _summaryExpanded = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<BudgetProvider>(context, listen: false).initBudget();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? CustomAppBar(
              title: 'Budget',
              showBackButton: widget.showBackButton,
              actions: [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete_all') {
                      _confirmDeleteAllBudgets(context);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete_all',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete All Budgets',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )
          : null,
      body: Consumer3<BudgetProvider, ExpenseProvider, SettingsProvider>(
        builder:
            (context, budgetProvider, expenseProvider, settingsProvider, _) {
          final currencySymbol = settingsProvider.currencySymbol;
          final budget = budgetProvider.getBudgetForMonth(
            _selectedMonth.month,
            _selectedMonth.year,
          );
          final categories = expenseProvider.categories;

          // Get expenses for the selected month
          final monthExpenses = expenseProvider.expenses.where((expense) {
            return expense.date.year == _selectedMonth.year &&
                expense.date.month == _selectedMonth.month;
          }).toList();

          // Calculate spending by category
          final Map<String, double> categorySpending = {};
          for (var expense in monthExpenses) {
            categorySpending[expense.category] =
                (categorySpending[expense.category] ?? 0) + expense.amount;
          }

          // Calculate totals
          final totalBudget =
              budget?.categoryLimits.values.fold<double>(0, (sum, amount) {
                    return sum + amount;
                  }) ??
                  0;
          final totalSpent = categorySpending.values
              .fold<double>(0, (sum, amount) => sum + amount);
          final budgetedCategories = budget?.categoryLimits.keys.toList() ?? [];

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildMonthNavigation(),
                    _buildSummaryCard(
                      context,
                      totalBudget,
                      totalSpent,
                      currencySymbol,
                      budgetedCategories,
                      categorySpending,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Category Budgets',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => _showAddBudgetDialog(
                              context,
                              categories,
                              budget,
                            ),
                            tooltip: 'Add Budget',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              if (budgetedCategories.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pie_chart_outline,
                          size: 64,
                          color: AppTheme.textSecondaryColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No budgets set for this month',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextButton.icon(
                          onPressed: () => _showAddBudgetDialog(
                            context,
                            categories,
                            budget,
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Budget'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final category = budgetedCategories[index];
                        final budgetAmount =
                            budget!.categoryLimits[category] ?? 0;
                        final spentAmount = categorySpending[category] ?? 0;
                        final percentage = budgetAmount > 0
                            ? (spentAmount / budgetAmount).clamp(0.0, 1.0)
                            : 0.0;

                        final categoryData = categories.firstWhere(
                          (c) => c.name == category,
                          orElse: () => categories.first,
                        );

                        return _buildBudgetCard(
                          context,
                          category,
                          budgetAmount,
                          spentAmount,
                          percentage,
                          currencySymbol,
                          categoryData.icon,
                          categoryData.color,
                          monthExpenses
                              .where((e) => e.category == category)
                              .toList(),
                        );
                      },
                      childCount: budgetedCategories.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        heroTag: 'budget_planner_fab_add',
        onPressed: () {
          final categories = context.read<ExpenseProvider>().categories;
          final budget = context.read<BudgetProvider>().getBudgetForMonth(
                _selectedMonth.month,
                _selectedMonth.year,
              );
          _showAddBudgetDialog(context, categories, budget);
        },
        tooltip: 'Add Budget',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMonthNavigation() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            iconSize: 20,
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month - 1,
                );
              });
            },
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime.now();
              });
            },
            child: Text(
              _getMonthYearString(_selectedMonth),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            iconSize: 20,
            onPressed: () {
              final nextMonth = DateTime(
                _selectedMonth.year,
                _selectedMonth.month + 1,
              );
              if (nextMonth
                  .isBefore(DateTime.now().add(const Duration(days: 31)))) {
                setState(() {
                  _selectedMonth = nextMonth;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    double totalBudget,
    double totalSpent,
    String currencySymbol,
    List<String> budgetedCategories,
    Map<String, double> categorySpending,
  ) {
    final remaining = totalBudget - totalSpent;
    final percentage =
        totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;

    return InkWell(
      onTap: () {
        setState(() {
          _summaryExpanded = !_summaryExpanded;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.7)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Summary',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    _summaryExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white.withOpacity(0.9),
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LayoutBuilder(
                builder: (context, constraints) {
                  final showChart = constraints.maxWidth >= 360 &&
                      budgetedCategories.isNotEmpty &&
                      _summaryExpanded;

                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Budget',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppUtils.formatCurrency(totalBudget,
                                  currencySymbol: currencySymbol),
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            if (_summaryExpanded) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Spent',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color:
                                                Colors.white.withOpacity(0.8),
                                          ),
                                        ),
                                        Text(
                                          AppUtils.formatCurrency(totalSpent,
                                              currencySymbol: currencySymbol),
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Remaining',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color:
                                                Colors.white.withOpacity(0.8),
                                          ),
                                        ),
                                        Text(
                                          AppUtils.formatCurrency(remaining,
                                              currencySymbol: currencySymbol),
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: remaining >= 0
                                                ? Colors.white
                                                : Colors.red.shade200,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (showChart)
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 18,
                              sections: _buildPieChartSections(
                                  budgetedCategories, categorySpending),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (_summaryExpanded) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percentage >= 1.0
                          ? Colors.red.shade300
                          : (percentage >= 0.8
                              ? Colors.orange.shade300
                              : Colors.green.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(percentage * 100).toStringAsFixed(1)}% of budget used',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: 4,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percentage >= 1.0
                          ? Colors.red.shade300
                          : (percentage >= 0.8
                              ? Colors.orange.shade300
                              : Colors.green.shade300),
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

  List<PieChartSectionData> _buildPieChartSections(
    List<String> categories,
    Map<String, double> categorySpending,
  ) {
    final colors = [
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.orange.shade300,
      Colors.purple.shade300,
      Colors.red.shade300,
      Colors.teal.shade300,
      Colors.pink.shade300,
      Colors.amber.shade300,
    ];

    return categories.asMap().entries.map((entry) {
      final category = entry.value;
      final spent = categorySpending[category] ?? 0;
      final color = colors[entry.key % colors.length];

      return PieChartSectionData(
        value: spent,
        color: color,
        radius: 15,
        showTitle: false,
      );
    }).toList();
  }

  Widget _buildBudgetCard(
    BuildContext context,
    String category,
    double budgetAmount,
    double spentAmount,
    double percentage,
    String currencySymbol,
    String icon,
    String colorHex,
    List<Expense> categoryExpenses,
  ) {
    final categoryColor = _hexToColor(colorHex);
    final isOverBudget = spentAmount > budgetAmount;

    return Dismissible(
      key: ValueKey(category),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (direction) {
        _confirmDeleteBudget(context, category);
      },
      child: GestureDetector(
        onTap: () => _showCategoryExpenses(
          context,
          category,
          categoryExpenses,
          currencySymbol,
          icon,
          colorHex,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        icon,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${categoryExpenses.length} expense${categoryExpenses.length != 1 ? 's' : ''}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppUtils.formatCurrency(spentAmount,
                            currencySymbol: currencySymbol),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isOverBudget
                              ? AppTheme.errorColor
                              : AppTheme.textColor,
                        ),
                      ),
                      Text(
                        'of ${AppUtils.formatCurrency(budgetAmount, currencySymbol: currencySymbol)}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showQuickEditDialog(
                      context,
                      category,
                      budgetAmount,
                    ),
                    tooltip: 'Edit budget',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Colors.red),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _confirmDeleteBudget(
                      context,
                      category,
                    ),
                    tooltip: 'Delete budget',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percentage >= 1.0
                        ? AppTheme.errorColor
                        : (percentage >= 0.8 ? Colors.orange : categoryColor),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(percentage * 100).toStringAsFixed(1)}% used',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  if (isOverBudget)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Over by ${AppUtils.formatCurrency(spentAmount - budgetAmount, currencySymbol: currencySymbol)}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
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

  void _showAddBudgetDialog(
    BuildContext context,
    List<dynamic> categories,
    Budget? currentBudget,
  ) {
    String? selectedCategory;
    final amountController = TextEditingController();
    // Show recurrence settings for first category OR if budget is already recurring
    String recurrenceType = currentBudget?.recurrenceType ?? 'oneTime';
    DateTime? endDate = currentBudget?.endDate;
    final isFirstCategory =
        currentBudget == null || currentBudget.categoryLimits.isEmpty;
    // Always show recurrence option so user can set it at any time during budget creation
    final shouldShowRecurrence = true;

    debugPrint('[BudgetDialog] Opening add budget dialog');
    debugPrint('[BudgetDialog] currentBudget: $currentBudget');
    debugPrint('[BudgetDialog] isFirstCategory: $isFirstCategory');
    debugPrint('[BudgetDialog] shouldShowRecurrence: $shouldShowRecurrence');

    final availableCategories = categories
        .where((cat) => currentBudget?.categoryLimits[cat.name] == null)
        .toList();
    final categoryMap = {
      for (final cat in availableCategories) cat.name: cat,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondaryColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Add Category Budget',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              DropdownSearch<String>(
                items: availableCategories
                    .map((cat) => cat.name as String)
                    .toList(),
                selectedItem: selectedCategory,
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  itemBuilder: (context, item, isSelected) {
                    final cat = categoryMap[item];
                    return ListTile(
                      leading: cat == null
                          ? null
                          : Text(cat.icon,
                              style: const TextStyle(fontSize: 20)),
                      title: Text(item),
                    );
                  },
                ),
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                ),
                dropdownBuilder: (context, selectedItem) {
                  if (selectedItem == null) {
                    return const Text('Select a category');
                  }
                  final cat = categoryMap[selectedItem];
                  if (cat == null) {
                    return Text(selectedItem);
                  }
                  return Row(
                    children: [
                      Text(cat.icon, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(cat.name),
                    ],
                  );
                },
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Budget Amount',
                  border: const OutlineInputBorder(),
                  prefixText:
                      '${context.read<SettingsProvider>().currencySymbol} ',
                ),
              ),
              if (shouldShowRecurrence) ...[
                const SizedBox(height: 16),
                Text(
                  'Recurrence',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('One-Time'),
                      subtitle: Text(
                        'Budget for ${_getMonthYearString(_selectedMonth)} only',
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: 'oneTime',
                      groupValue: recurrenceType,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setState(() {
                          recurrenceType = value ?? 'oneTime';
                          if (recurrenceType == 'oneTime') {
                            endDate = null;
                          }
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Monthly Recurring'),
                      subtitle: const Text(
                        'Repeat every month from now onwards',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: 'monthly',
                      groupValue: recurrenceType,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setState(() {
                          recurrenceType = value ?? 'oneTime';
                        });
                      },
                    ),
                  ],
                ),
                if (recurrenceType == 'monthly') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          endDate == null
                              ? 'No end date'
                              : 'Until ${endDate!.year}-${endDate!.month.toString().padLeft(2, "0")}',
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: endDate ??
                                DateTime(_selectedMonth.year,
                                    _selectedMonth.month + 1),
                            firstDate: DateTime(
                                _selectedMonth.year, _selectedMonth.month + 1),
                            lastDate: DateTime(_selectedMonth.year + 10),
                          );
                          if (selectedDate != null) {
                            setState(() {
                              endDate = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                              );
                            });
                          }
                        },
                        child:
                            Text(endDate == null ? 'Set End Date' : 'Change'),
                      ),
                      if (endDate != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              endDate = null;
                            });
                          },
                          child: const Text('Clear'),
                        ),
                    ],
                  ),
                ],
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (selectedCategory == null ||
                            amountController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please fill all fields')),
                          );
                          return;
                        }

                        final amount =
                            double.tryParse(amountController.text) ?? 0;
                        if (amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please enter a valid amount')),
                          );
                          return;
                        }

                        final budgetProvider = context.read<BudgetProvider>();
                        final newLimits = Map<String, double>.from(
                            currentBudget?.categoryLimits ?? {});
                        newLimits[selectedCategory!] = amount;

                        if (isFirstCategory) {
                          // Create new budget with recurrence settings
                          budgetProvider.createOrUpdateBudget(
                            newLimits,
                            month: _selectedMonth.month,
                            year: _selectedMonth.year,
                            recurrenceType: recurrenceType,
                            endDate: endDate,
                          );
                        } else {
                          // Add category to existing budget
                          final updated = currentBudget.copyWith(
                            categoryLimits: newLimits,
                            updatedAt: DateTime.now(),
                          );
                          budgetProvider.saveBudget(updated);

                          // If this is part of a recurring series, update all future months
                          if (currentBudget.baselineId != null) {
                            budgetProvider.updateRecurringSeries(
                              currentBudget.baselineId!,
                              newLimits,
                            );
                          }
                        }
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Budget added')),
                        );
                      },
                      child: const Text('Add'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBudgetSettingsDialog(BuildContext context, Budget? currentBudget) {
    String recurrenceType = currentBudget?.recurrenceType ?? 'oneTime';
    DateTime? endDate = currentBudget?.endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Budget Settings',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recurrence Type',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('One-Time'),
                    subtitle: Text(
                      'Budget for ${_getMonthYearString(_selectedMonth)} only',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: 'oneTime',
                    groupValue: recurrenceType,
                    onChanged: (value) {
                      setState(() {
                        recurrenceType = value ?? 'oneTime';
                        if (recurrenceType == 'oneTime') {
                          endDate = null;
                        }
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Monthly Recurring'),
                    subtitle: const Text('Repeat every month'),
                    value: 'monthly',
                    groupValue: recurrenceType,
                    onChanged: (value) {
                      setState(() {
                        recurrenceType = value ?? 'oneTime';
                      });
                    },
                  ),
                ],
              ),
              if (recurrenceType == 'monthly') ...[
                const SizedBox(height: 16),
                Text(
                  'End Date (Optional)',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        endDate == null
                            ? 'No end date (indefinite)'
                            : '${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: endDate ??
                              DateTime(_selectedMonth.year + 1,
                                  _selectedMonth.month),
                          firstDate: _selectedMonth,
                          lastDate: DateTime(_selectedMonth.year + 10),
                        );
                        if (selectedDate != null) {
                          setState(() {
                            endDate = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                            );
                          });
                        }
                      },
                      child: const Text('Set Date'),
                    ),
                    if (endDate != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            endDate = null;
                          });
                        },
                        child: const Text('Clear'),
                      ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final budgetProvider = context.read<BudgetProvider>();
                if (currentBudget != null) {
                  // Update existing budget
                  final updated = currentBudget.copyWith(
                    recurrenceType: recurrenceType,
                    endDate: endDate,
                    updatedAt: DateTime.now(),
                  );
                  budgetProvider.saveBudget(updated);
                } else {
                  // Note: This would be called when creating a new budget
                  // The actual budget creation happens in createOrUpdateBudget
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Budget settings updated'),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickEditDialog(
    BuildContext context,
    String category,
    double currentAmount,
  ) {
    final amountController =
        TextEditingController(text: currentAmount.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Budget: $category',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Budget Amount',
            border: const OutlineInputBorder(),
            prefixText: '${context.read<SettingsProvider>().currencySymbol} ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }

              final budgetProvider = context.read<BudgetProvider>();
              final budget = budgetProvider.getBudgetForMonth(
                _selectedMonth.month,
                _selectedMonth.year,
              );
              if (budget != null) {
                final newLimits =
                    Map<String, double>.from(budget.categoryLimits);
                newLimits[category] = amount;
                budgetProvider.saveBudget(budget.copyWith(
                  categoryLimits: newLimits,
                  updatedAt: DateTime.now(),
                ));

                // If this is part of a recurring series, update all future months
                if (budget.baselineId != null) {
                  budgetProvider.updateRecurringSeries(
                    budget.baselineId!,
                    newLimits,
                  );
                }
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Budget updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteBudget(
    BuildContext context,
    String category,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Budget',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete the budget for $category?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final budgetProvider = context.read<BudgetProvider>();
              final budget = budgetProvider.getBudgetForMonth(
                _selectedMonth.month,
                _selectedMonth.year,
              );
              if (budget != null) {
                final newLimits =
                    Map<String, double>.from(budget.categoryLimits);
                newLimits.remove(category);
                budgetProvider.saveBudget(budget.copyWith(
                  categoryLimits: newLimits,
                  updatedAt: DateTime.now(),
                ));

                // If this is part of a recurring series, update all future months
                if (budget.baselineId != null) {
                  budgetProvider.updateRecurringSeries(
                    budget.baselineId!,
                    newLimits,
                  );
                }
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Budget deleted')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditBudgetDialog(
    BuildContext context,
    String category,
    double currentAmount,
  ) {
    _showQuickEditDialog(context, category, currentAmount);
  }

  void _confirmDeleteAllBudgets(BuildContext context) {
    final budgetProvider = context.read<BudgetProvider>();
    final budget = budgetProvider.getBudgetForMonth(
      _selectedMonth.month,
      _selectedMonth.year,
    );

    if (budget == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Budget',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delete budget for ${_getMonthYearString(_selectedMonth)}?',
              style: GoogleFonts.poppins(),
            ),
            if (budget.baselineId != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This is a recurring budget. Choose:',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• This month only: Delete just ${_getMonthYearString(_selectedMonth)}',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• All future: Delete this and all future recurring instances',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (budget.baselineId != null)
            ElevatedButton(
              onPressed: () {
                budgetProvider.deleteBudgetForMonth(
                  _selectedMonth.month,
                  _selectedMonth.year,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Budget for ${_getMonthYearString(_selectedMonth)} deleted',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('This Month Only'),
            ),
          ElevatedButton(
            onPressed: () {
              if (budget.baselineId != null) {
                budgetProvider.deleteRecurringSeries(budget.baselineId!);
              } else {
                budgetProvider.deleteBudgetForMonth(
                  _selectedMonth.month,
                  _selectedMonth.year,
                );
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    budget.baselineId != null
                        ? 'All recurring budgets deleted'
                        : 'Budget deleted',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(budget.baselineId != null ? 'All Future' : 'Delete'),
          ),
        ],
      ),
    );
  }

  void _showCategoryExpenses(
    BuildContext context,
    String category,
    List<Expense> expenses,
    String currencySymbol,
    String icon,
    String colorHex,
  ) {
    final categoryColor = _hexToColor(colorHex);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textSecondaryColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child:
                              Text(icon, style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${expenses.length} expense${expenses.length != 1 ? 's' : ''}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: expenses.isEmpty
                  ? Center(
                      child: Text(
                        'No expenses in this category',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        final expense = expenses[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      expense.title,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      AppUtils.formatDateShort(expense.date),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                AppUtils.formatCurrency(expense.amount,
                                    currencySymbol: currencySymbol),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.errorColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
