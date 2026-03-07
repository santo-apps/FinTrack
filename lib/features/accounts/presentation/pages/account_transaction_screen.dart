import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.account.name,
        showBackButton: true,
      ),
      body: Consumer2<ExpenseProvider, PaymentAccountProvider>(
        builder: (context, expenseProvider, accountProvider, _) {
          // Get the latest account data from provider
          final currentAccount =
              accountProvider.getAccountById(widget.account.id);
          if (currentAccount == null) {
            return Center(
              child: Text(
                'Account not found',
                style: GoogleFonts.poppins(
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
                  shouldShowTransactionForAccount(expense, currentAccount.id))
              .toList();

          // Sort by date descending
          expenses.sort((a, b) => b.date.compareTo(a.date));

          // Calculate totals
          double totalDebits = 0;

          for (final expense in expenses) {
            final isDebit =
                isDebitTransactionForAccount(expense, currentAccount.id);

            if (isDebit && expense.amount > 0) {
              totalDebits += expense.amount;
            }
          }

          if (expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 80,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No expenses recorded for this account',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
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
                          colors: [AppTheme.primaryColor, AppTheme.accentColor],
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
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Balance',
                      style: GoogleFonts.poppins(
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
                        currentAccount.balance,
                        currencySymbol:
                            context.watch<SettingsProvider>().currencySymbol,
                      ),
                      style: GoogleFonts.poppins(
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
                          value: expenses.length.toString(),
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
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Transactions List
              Text(
                'Transactions',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 12),
              ...expenses.map((expense) => _TransactionCard(
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _getTransactionTabs(),
        ),
      ),
    );
  }

  List<Widget> _getTransactionTabs() {
    final isCreditCard = widget.account.accountType == 'Credit Card';
    final tabs = [
      ('Expense', 'expense', '💸'),
      (isCreditCard ? 'Refund' : 'Income', 'income', '💰'),
      if (isCreditCard)
        ('Payment', 'payment', '💳')
      else
        ('Transfer', 'transfer', '🔄'),
    ];

    return tabs.asMap().entries.map((entry) {
      final index = entry.key;
      final tab = entry.value;
      final isSelected = _selectedTabIndex == index;

      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() => _selectedTabIndex = index);
              _showCalculator(tab.$2);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tab.$3,
                    style: GoogleFonts.poppins(fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tab.$1,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondaryColor,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      height: 2,
                      width: 24,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  void _showCalculator(String transactionType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TransactionCalculator(
        account: widget.account,
        transactionType: transactionType,
      ),
    );
  }

  void _editTransaction(Expense expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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

  void _deleteTransaction(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              // Reverse transaction effects
              final accountProvider = context.read<PaymentAccountProvider>();
              final sourceId = expense.accountId;
              if (sourceId != null) {
                final sourceAccount = accountProvider.getAccountById(sourceId);
                if (sourceAccount != null) {
                  final isCreditCard = sourceAccount.accountType
                      .toLowerCase()
                      .contains('credit');

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
                          final isDestCredit = destination.accountType
                              .toLowerCase()
                              .contains('credit');
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

              // Delete the transaction
              context.read<ExpenseProvider>().deleteExpense(expense.id);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaction deleted')),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Calculator widget for entering transaction amounts
class TransactionCalculator extends StatefulWidget {
  final PaymentAccount account;
  final String transactionType;

  const TransactionCalculator({
    super.key,
    required this.account,
    required this.transactionType,
  });

  @override
  State<TransactionCalculator> createState() => _TransactionCalculatorState();
}

class _TransactionCalculatorState extends State<TransactionCalculator> {
  String _display = '0';
  String _input = '';
  String _operation = '';
  double _accumulated = 0;
  bool _newNumber = true;
  String? _selectedAccountId;
  final TextEditingController _accountFieldController = TextEditingController();

  @override
  void dispose() {
    _accountFieldController.dispose();
    super.dispose();
  }

  void _handleNumber(String number) {
    setState(() {
      if (_newNumber) {
        _input = number;
        _newNumber = false;
      } else {
        _input += number;
      }
      _display = _input.isEmpty ? '0' : _input;
    });
  }

  void _handleDecimal() {
    setState(() {
      if (_newNumber) {
        _input = '0.';
        _newNumber = false;
      } else if (!_input.contains('.')) {
        _input += '.';
      }
      _display = _input;
    });
  }

  void _handleOperation(String op) {
    final currentValue = double.tryParse(_input) ?? 0;

    if (_accumulated != 0 && _input.isNotEmpty) {
      _calculate();
    } else {
      _accumulated = currentValue;
    }

    setState(() {
      _operation = op;
      _input = '';
      _newNumber = true;
    });
  }

  void _calculate() {
    if (_operation.isEmpty || _input.isEmpty) return;

    final currentValue = double.tryParse(_input) ?? 0;
    double result = 0;

    switch (_operation) {
      case '+':
        result = _accumulated + currentValue;
        break;
      case '-':
        result = _accumulated - currentValue;
        break;
      case '×':
        result = _accumulated * currentValue;
        break;
      case '÷':
        result = currentValue != 0 ? _accumulated / currentValue : 0;
        break;
    }

    setState(() {
      _accumulated = result;
      _input = result.toString();
      _display = result.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
      _operation = '';
      _newNumber = true;
    });
  }

  void _clear() {
    setState(() {
      _display = '0';
      _input = '';
      _operation = '';
      _accumulated = 0;
      _newNumber = true;
    });
  }

  void _delete() {
    setState(() {
      if (_input.isNotEmpty) {
        _input = _input.substring(0, _input.length - 1);
        _display = _input.isEmpty ? '0' : _input;
        if (_input.isEmpty) {
          _newNumber = true;
        }
      }
    });
  }

  void _proceed() {
    final amount = double.tryParse(_input) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final requiresAccount = widget.transactionType == 'transfer' ||
        widget.transactionType == 'payment';
    if (requiresAccount && _selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.transactionType == 'transfer'
                ? 'Select a target account'
                : 'Select a source account',
          ),
        ),
      );
      return;
    }

    _proceedToForm(amount, _selectedAccountId);
  }

  void _showAccountPicker(
    List<PaymentAccount> availableAccounts,
    String title,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        String query = '';

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredAccounts = availableAccounts.where((account) {
              final nameMatch =
                  account.name.toLowerCase().contains(query.toLowerCase());
              final typeMatch = account.accountType
                  .toLowerCase()
                  .contains(query.toLowerCase());
              return nameMatch || typeMatch;
            }).toList();

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search accounts',
                      ),
                      onChanged: (value) {
                        setSheetState(() {
                          query = value.trim();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    if (filteredAccounts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('No matching accounts'),
                      )
                    else
                      SizedBox(
                        height: 300,
                        child: ListView.builder(
                          itemCount: filteredAccounts.length,
                          itemBuilder: (context, index) {
                            final account = filteredAccounts[index];
                            return ListTile(
                              title: Text(account.name),
                              subtitle: Text(account.accountType),
                              onTap: () {
                                setState(() {
                                  _selectedAccountId = account.id;
                                  _accountFieldController.text = account.name;
                                });
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _proceedToForm(double amount, String? destinationAccountId) {
    // Close the calculator modal bottom sheet
    Navigator.pop(context);

    // Show the form in a full-screen bottom sheet
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => AddEditExpenseScreen(
            initialAccountId: widget.account.id,
            initialTransactionType: widget.transactionType,
            initialAmount: amount,
            initialDestinationAccountId: destinationAccountId,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<PaymentAccountProvider>();
    final currentAccount = accountProvider.getAccountById(widget.account.id);

    if (currentAccount == null) {
      return const Center(
        child: Text('Account not found'),
      );
    }

    final isCreditCard =
        currentAccount.accountType.toLowerCase().contains('credit');
    final transactionLabel = _getTransactionLabel(isCreditCard);
    final requiresAccount = widget.transactionType == 'transfer' ||
        widget.transactionType == 'payment';
    final accounts = accountProvider.accounts;
    final availableAccounts = accounts.where((account) {
      if (!account.isActive) {
        return false;
      }
      if (widget.transactionType == 'transfer') {
        return account.id != currentAccount.id &&
            account.accountType.toLowerCase().contains('bank');
      }
      if (widget.transactionType == 'payment') {
        return account.accountType.toLowerCase().contains('bank');
      }
      return false;
    }).toList();

    final selectedAccountName = _selectedAccountId == null
        ? ''
        : availableAccounts
            .firstWhere(
              (account) => account.id == _selectedAccountId,
              orElse: () => accounts.firstWhere(
                (account) => account.id == _selectedAccountId,
                orElse: () => PaymentAccount(
                  id: 'temp',
                  name: '',
                  accountType: 'Unknown',
                  createdAt: DateTime.now(),
                ),
              ),
            )
            .name;

    if (_accountFieldController.text != selectedAccountName) {
      _accountFieldController.text = selectedAccountName;
    }

    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        color: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (requiresAccount) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextFormField(
                controller: _accountFieldController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: widget.transactionType == 'transfer'
                      ? 'Transfer To'
                      : 'Payment From',
                  helperText: widget.transactionType == 'transfer'
                      ? 'Select target account'
                      : 'Select source bank account',
                  suffixIcon: const Icon(Icons.search),
                ),
                onTap: availableAccounts.isEmpty
                    ? null
                    : () {
                        final title = widget.transactionType == 'transfer'
                            ? 'Select Target Account'
                            : 'Select Source Bank Account';
                        _showAccountPicker(availableAccounts, title);
                      },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Header with Save button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  transactionLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textColor,
                  ),
                ),
                ElevatedButton(
                  onPressed: _proceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    'SAVE',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              _display,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Calculator Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Row 1: 1, 2, 3, ×
                Row(
                  children: [
                    _buildNumberButton('1'),
                    const SizedBox(width: 8),
                    _buildNumberButton('2'),
                    const SizedBox(width: 8),
                    _buildNumberButton('3'),
                    const SizedBox(width: 8),
                    _buildOperationButton('×'),
                  ],
                ),
                const SizedBox(height: 8),

                // Row 2: 4, 5, 6, ÷
                Row(
                  children: [
                    _buildNumberButton('4'),
                    const SizedBox(width: 8),
                    _buildNumberButton('5'),
                    const SizedBox(width: 8),
                    _buildNumberButton('6'),
                    const SizedBox(width: 8),
                    _buildOperationButton('÷'),
                  ],
                ),
                const SizedBox(height: 8),

                // Row 3: 7, 8, 9, +
                Row(
                  children: [
                    _buildNumberButton('7'),
                    const SizedBox(width: 8),
                    _buildNumberButton('8'),
                    const SizedBox(width: 8),
                    _buildNumberButton('9'),
                    const SizedBox(width: 8),
                    _buildOperationButton('+'),
                  ],
                ),
                const SizedBox(height: 8),

                // Row 4: ., 0, Delete, -
                Row(
                  children: [
                    _buildDecimalButton(),
                    const SizedBox(width: 8),
                    _buildNumberButton('0'),
                    const SizedBox(width: 8),
                    _buildDeleteButton(),
                    const SizedBox(width: 8),
                    _buildOperationButton('-'),
                  ],
                ),
                const SizedBox(height: 8),

                // Row 5: Equals (full width)
                SizedBox(
                  height: 50,
                  child: GestureDetector(
                    onTap: _handleEquals,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '=',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Clear Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _clear,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Clear',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _handleEquals() {
    if (_operation.isNotEmpty && _input.isNotEmpty) {
      _calculate();
    }
  }

  Widget _buildNumberButton(String number) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _handleNumber(number),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOperationButton(String op) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _handleOperation(op),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              op,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDecimalButton() {
    return Expanded(
      child: GestureDetector(
        onTap: _handleDecimal,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '.',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Expanded(
      child: GestureDetector(
        onTap: _delete,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              color: AppTheme.textColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  String _getTransactionLabel(bool isCreditCard) {
    if (isCreditCard && widget.transactionType == 'income') {
      return 'Add Refund';
    }

    switch (widget.transactionType) {
      case 'income':
        return 'Add Income';
      case 'transfer':
        return 'Transfer';
      case 'payment':
        return 'Make Payment';
      default:
        return 'Add Expense';
    }
  }
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
          style: GoogleFonts.poppins(
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
          style: GoogleFonts.poppins(
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
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
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
                    expense.category,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Transaction type badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getTransactionLabel(),
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(expense.date),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      expense.notes!,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppTheme.textSecondaryColor,
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
              style: GoogleFonts.poppins(
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
