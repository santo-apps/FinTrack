import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/core/constants/app_constants.dart';
import 'package:fintrack/core/utils/custom_widgets.dart';
import 'package:fintrack/features/accounts/data/models/payment_account_model.dart';
import 'package:fintrack/features/accounts/presentation/providers/payment_account_provider.dart';
import 'package:fintrack/features/expense/data/models/expense_model.dart';
import 'package:fintrack/features/expense/presentation/providers/expense_provider.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';
import 'package:fintrack/features/expense/presentation/pages/expense_list_screen.dart';
import 'package:fintrack/features/expense/presentation/widgets/transaction_calculator_sheet.dart';

bool shouldShowTransactionForAccount(Expense expense, String accountId) {
  final isSourceAccount = expense.accountId == accountId;
  if (isSourceAccount) return true;

  final transactionType = expense.transactionType ?? 'expense';
  final supportsDestinationView =
      transactionType == 'transfer' || transactionType == 'payment';

  return supportsDestinationView && expense.destinationAccountId == accountId;
}

bool isDebitTransactionForAccount(Expense expense, String accountId) {
  final transactionType = expense.transactionType ?? 'expense';
  final isDestinationSide = expense.destinationAccountId == accountId &&
      expense.accountId != accountId;

  return transactionType == 'expense' ||
      transactionType == 'payment' ||
      (transactionType == 'transfer' && !isDestinationSide);
}

class AccountTransactionScreen extends StatefulWidget {
  final PaymentAccount account;

  const AccountTransactionScreen({
    super.key,
    required this.account,
  });

  @override
  State<AccountTransactionScreen> createState() =>
      _AccountTransactionScreenState();
}

class _AccountTransactionScreenState extends State<AccountTransactionScreen>
    with TickerProviderStateMixin {
  late int _selectedTabIndex;
  final Set<String> _pendingDeletedExpenseIds = <String>{};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _TransactionSortOption _sortOption = _TransactionSortOption.date;
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = -1;
  }

  bool _isCreditAccount(PaymentAccount account) {
    return account.accountType.toLowerCase().contains('credit');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDarkMode ? Theme.of(context).colorScheme.surface : null,
      appBar: CustomAppBar(
        title: widget.account.name,
        showBackButton: true,
      ),
      body: SafeArea(
        top: false,
        child: Consumer2<ExpenseProvider, PaymentAccountProvider>(
          builder: (context, expenseProvider, accountProvider, _) {
            // Get the latest account data from provider
            final currentAccount =
                accountProvider.getAccountById(widget.account.id);
            if (currentAccount == null) {
              return Center(
                child: Text(
                  'Account not found',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              );
            }

            // Filter expenses for this account.
            // Show source-side transactions always, and destination-side
            // entries for transfer/payment so both involved accounts can see
            // the same transaction.
            final expenses = expenseProvider.expenses
                .where((expense) =>
                    shouldShowTransactionForAccount(
                        expense, currentAccount.id) &&
                    !_pendingDeletedExpenseIds.contains(expense.id))
                .toList();

            // Apply search filter
            final query = _searchQuery.trim().toLowerCase();
            final filteredExpenses = query.isEmpty
                ? expenses
                : expenses.where((expense) {
                    final haystack = [
                      expense.title,
                      expense.category,
                      expense.paymentMethod,
                      expense.notes ?? '',
                    ].join(' ').toLowerCase();
                    return haystack.contains(query);
                  }).toList();

            // Apply sorting
            switch (_sortOption) {
              case _TransactionSortOption.date:
                filteredExpenses.sort((a, b) => _sortAscending
                    ? a.date.compareTo(b.date)
                    : b.date.compareTo(a.date));
                break;
              case _TransactionSortOption.amount:
                filteredExpenses.sort((a, b) => _sortAscending
                    ? a.amount.compareTo(b.amount)
                    : b.amount.compareTo(a.amount));
                break;
              case _TransactionSortOption.category:
                filteredExpenses.sort((a, b) => _sortAscending
                    ? a.category.compareTo(b.category)
                    : b.category.compareTo(a.category));
                break;
            }

            // Calculate totals
            double totalDebits = 0;

            for (final expense in expenses) {
              final isDebit =
                  isDebitTransactionForAccount(expense, currentAccount.id);

              if (isDebit && expense.amount > 0) {
                totalDebits += expense.amount;
              }
            }

            final isCreditCard = _isCreditAccount(currentAccount);
            final summaryBalance = currentAccount.balance;

            return ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                contentBottomPadding(context, hasFab: false),
              ),
              children: [
                // Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.surface
                        : null,
                    gradient: Theme.of(context).brightness == Brightness.dark
                        ? null
                        : LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.accentColor
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(16),
                    border: Theme.of(context).brightness == Brightness.dark
                        ? Border.all(color: Theme.of(context).dividerColor)
                        : null,
                    boxShadow: Theme.of(context).brightness == Brightness.dark
                        ? []
                        : [
                            BoxShadow(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCreditCard
                            ? 'Outstanding Balance'
                            : 'Account Balance',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppUtils.formatCurrency(
                          summaryBalance,
                          currencySymbol:
                              context.watch<SettingsProvider>().currencySymbol,
                        ),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _SummaryItem(
                            label: 'Total Transactions',
                            value: filteredExpenses.length.toString(),
                          ),
                          _SummaryItem(
                            label: 'Total Debits',
                            value: AppUtils.formatCurrency(
                              totalDebits,
                              currencySymbol: context
                                  .watch<SettingsProvider>()
                                  .currencySymbol,
                            ),
                          ),
                        ],
                      ),
                      if (currentAccount.accountType
                              .toLowerCase()
                              .contains('credit') &&
                          (currentAccount.statementDate != null ||
                              currentAccount.dueDate != null)) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (currentAccount.statementDate != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Theme.of(context).colorScheme.surface
                                      : Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Statement day: ${currentAccount.statementDate!.day.toString().padLeft(2, '0')} (monthly)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                        : Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (currentAccount.dueDate != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Theme.of(context).colorScheme.surface
                                      : Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Due day: ${currentAccount.dueDate!.day.toString().padLeft(2, '0')} (monthly)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                        : Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _buildTransactionActionBar(),
                const SizedBox(height: 20),

                // Transactions List
                Text(
                  'Transactions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search transactions',
                          suffixIcon: _searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<_TransactionSortOption>(
                      icon: const Icon(Icons.sort),
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
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _TransactionSortOption.date,
                          child: Text('Date'),
                        ),
                        PopupMenuItem(
                          value: _TransactionSortOption.amount,
                          child: Text('Amount'),
                        ),
                        PopupMenuItem(
                          value: _TransactionSortOption.category,
                          child: Text('Category'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (filteredExpenses.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 32,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 52,
                          color: AppTheme.textSecondaryColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No transactions yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color:
                                isDarkMode ? Colors.white : AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Use the action tabs above to add an expense, income, transfer, or payment for this account.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode
                                ? Colors.white70
                                : AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...filteredExpenses.map((expense) => _TransactionCard(
                        key: Key(expense.id),
                        expense: expense,
                        currentAccountId: currentAccount.id,
                        currencySymbol:
                            context.watch<SettingsProvider>().currencySymbol,
                        isCreditCard: currentAccount.accountType
                            .toLowerCase()
                            .contains('credit'),
                        onEdit: () => _editTransaction(expense),
                        onDelete: () => _deleteTransaction(expense),
                      )),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTransactionActionBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final actions = _getTransactionActions();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.white : AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: actions
                .asMap()
                .entries
                .map((entry) =>
                    _buildTransactionActionCard(entry.key, entry.value))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionActionCard(int index, _TransactionAction action) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedTabIndex == index;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() => _selectedTabIndex = index);
              _showCalculator(action.type);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? action.color.withValues(alpha: 0.16)
                    : (isDarkMode
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? action.color.withValues(alpha: 0.55)
                      : (isDarkMode ? Colors.white12 : Colors.grey.shade200),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    action.icon,
                    size: 20,
                    color: isSelected
                        ? action.color
                        : (isDarkMode
                            ? Colors.white70
                            : AppTheme.textSecondaryColor),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    action.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? action.color
                          : (isDarkMode ? Colors.white : AppTheme.textColor),
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

  List<_TransactionAction> _getTransactionActions() {
    final isCreditCard = widget.account.accountType == 'Credit Card';
    final actions = <_TransactionAction>[
      _TransactionAction(
        label: 'Expense',
        type: 'expense',
        icon: Icons.remove_circle_outline,
        color: const Color(0xFFE4572E),
      ),
      _TransactionAction(
        label: isCreditCard ? 'Refund' : 'Income',
        type: 'income',
        icon: Icons.add_circle_outline,
        color: const Color(0xFF2E9E58),
      ),
      if (isCreditCard)
        _TransactionAction(
          label: 'Payment',
          type: 'payment',
          icon: Icons.credit_score_outlined,
          color: const Color(0xFF335CFF),
        )
      else
        _TransactionAction(
          label: 'Transfer',
          type: 'transfer',
          icon: Icons.swap_horiz,
          color: const Color(0xFF7E5CEF),
        ),
    ];

    return actions;
  }

  void _showCalculator(String transactionType) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor:
          isDarkMode ? Theme.of(context).colorScheme.surface : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TransactionCalculatorSheet(
        sourceAccount: widget.account,
        transactionType: transactionType,
        onSubmit: (amount, selectedAccountId) async {
          if (!mounted) return;
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor:
                isDarkMode ? Theme.of(context).colorScheme.surface : null,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => AddEditExpenseScreen(
              initialAccountId: widget.account.id,
              initialTransactionType: transactionType,
              initialAmount: amount,
              initialDestinationAccountId: selectedAccountId,
            ),
          );
        },
      ),
    );
  }

  void _editTransaction(Expense expense) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor:
          isDarkMode ? Theme.of(context).colorScheme.surface : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddEditExpenseScreen(
        expense: expense,
        initialAccountId: expense.accountId,
        initialTransactionType: expense.transactionType,
        initialDestinationAccountId: expense.destinationAccountId,
        initialAmount: expense.amount,
      ),
    );
  }

  void _deleteTransaction(Expense expense) async {
    final accountProvider = context.read<PaymentAccountProvider>();
    final expenseProvider = context.read<ExpenseProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Optimistically hide the item so UI updates immediately.
    if (mounted) {
      setState(() {
        _pendingDeletedExpenseIds.add(expense.id);
      });
    }

    try {
      // Reverse transaction effects
      final sourceId = expense.accountId;
      if (sourceId != null) {
        final sourceAccount = accountProvider.getAccountById(sourceId);
        if (sourceAccount != null) {
          final isCreditCard =
              sourceAccount.accountType.toLowerCase().contains('credit');

          final amount = expense.amount;
          final transactionType = expense.transactionType ?? 'expense';

          double sourceDelta = 0;
          double destinationDelta = 0;
          String? destinationId = expense.destinationAccountId;

          // Calculate the original deltas (same logic as _applyTransactionEffects)
          switch (transactionType) {
            case 'income':
              sourceDelta = isCreditCard ? -amount : amount;
              break;
            case 'transfer':
              sourceDelta = -amount;
              if (destinationId != null) {
                final destination =
                    accountProvider.getAccountById(destinationId);
                if (destination != null) {
                  final isDestCredit =
                      destination.accountType.toLowerCase().contains('credit');
                  destinationDelta = isDestCredit ? -amount : amount;
                }
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

          await accountProvider.adjustAccountBalance(
            sourceId,
            sourceDelta,
          );

          if (destinationId != null && destinationDelta != 0) {
            await accountProvider.adjustAccountBalance(
              destinationId,
              destinationDelta,
            );
          }
        }
      }

      await expenseProvider.deleteExpense(expense.id);

      if (mounted) {
        setState(() {
          _pendingDeletedExpenseIds.remove(expense.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted')),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _pendingDeletedExpenseIds.remove(expense.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete transaction')),
        );
      }
    }
  }
}

enum _TransactionSortOption { date, amount, category }

class _TransactionAction {
  final String label;
  final String type;
  final IconData icon;
  final Color color;

  const _TransactionAction({
    required this.label,
    required this.type,
    required this.icon,
    required this.color,
  });
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({
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
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.onSurface
                : Colors.white,
          ),
        ),
      ],
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Expense expense;
  final String currentAccountId;
  final String currencySymbol;
  final bool isCreditCard;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _TransactionCard({
    super.key,
    required this.expense,
    required this.currentAccountId,
    required this.currencySymbol,
    this.isCreditCard = false,
    this.onEdit,
    this.onDelete,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today • ${_formatTime(date)}';
    } else if (dateOnly == yesterday) {
      return 'Yesterday • ${_formatTime(date)}';
    } else {
      return '${dateOnly.day} ${_monthName(dateOnly.month)} ${dateOnly.year} • ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _monthName(int month) {
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

  String _getTransactionLabel() {
    final transactionType = expense.transactionType ?? 'expense';
    final isDestinationSide =
        expense.destinationAccountId == currentAccountId &&
            expense.accountId != currentAccountId;

    if (transactionType == 'income' && isCreditCard) {
      return 'Refund';
    }

    switch (transactionType) {
      case 'income':
        return 'Income';
      case 'transfer':
        return isDestinationSide ? 'Transfer In' : 'Transfer Out';
      case 'payment':
        return 'Payment';
      default:
        return 'Expense';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final transactionType = expense.transactionType ?? 'expense';
    final isDebit = isDebitTransactionForAccount(expense, currentAccountId);

    // Determine colors and icons based on transaction type
    Color color;
    IconData iconData;

    switch (transactionType) {
      case 'income':
        color = AppTheme.successColor;
        iconData = Icons.arrow_downward;
        break;
      case 'transfer':
        color = Colors.blue;
        iconData = Icons.swap_horiz;
        break;
      case 'payment':
        color = Colors.orange;
        iconData = Icons.credit_card;
        break;
      default: // expense
        color = AppTheme.errorColor;
        iconData = Icons.arrow_upward;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isDarkMode ? Theme.of(context).colorScheme.surface : Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isDarkMode
            ? const BorderSide(color: Colors.white, width: 1)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                iconData,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Transaction Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title.trim().isEmpty
                        ? expense.category
                        : expense.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    expense.category,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDarkMode
                          ? Colors.white70
                          : AppTheme.textSecondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  // Transaction type badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getTransactionLabel(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(expense.date),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDarkMode
                          ? Colors.white70
                          : AppTheme.textSecondaryColor,
                    ),
                  ),
                  if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      expense.notes!,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDarkMode
                            ? Colors.white70
                            : AppTheme.textSecondaryColor,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Amount
            Text(
              '${isDebit ? '-' : '+'} ${AppUtils.formatCurrency(expense.amount.abs(), currencySymbol: currencySymbol)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(width: 8),

            // Action Buttons
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              padding: EdgeInsets.zero,
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit?.call();
                } else if (value == 'delete') {
                  onDelete?.call();
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
