import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/core/constants/app_constants.dart';
import 'package:fintrack/core/utils/custom_widgets.dart';
import 'package:fintrack/core/utils/dropdown_search_utils.dart';
import 'package:fintrack/features/accounts/data/models/payment_account_model.dart';
import 'package:fintrack/features/expense/data/models/expense_model.dart';
import 'package:fintrack/features/expense/presentation/providers/expense_provider.dart';
import 'package:fintrack/features/accounts/presentation/providers/payment_account_provider.dart';
import 'package:fintrack/features/loan/data/models/loan_model.dart';
import 'package:fintrack/features/loan/presentation/providers/loan_provider.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';

class RecordPaymentDialog extends StatefulWidget {
  final Loan loan;

  const RecordPaymentDialog({super.key, required this.loan});

  @override
  State<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _paymentType = 'emi'; // 'emi', 'full', or 'interest'
  String? _selectedSourceAccountType;
  String? _selectedSourceAccountId;

  @override
  void initState() {
    super.initState();
    // Pre-fill with EMI amount
    _amountController.text = widget.loan.monthlyEmi.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _recordPayment() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    final accountProvider = context.read<PaymentAccountProvider>();
    final sourceAccount = _selectedSourceAccountId == null
        ? null
        : accountProvider.getAccountById(_selectedSourceAccountId!);

    if (sourceAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a source account'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Amount must be greater than 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Only check for regular payments, not interest-only
    if (_paymentType != 'interest') {
      final newPaidAmount = widget.loan.paidAmount + amount;

      if (newPaidAmount > widget.loan.borrowedAmount) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Payment Exceeds Loan'),
            content: Text(
              'The payment amount exceeds the remaining loan balance. '
              'Remaining: ${AppUtils.formatCurrency(widget.loan.pendingAmount, currencySymbol: context.read<SettingsProvider>().currencySymbol)}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
    }

    Future.microtask(() async {
      // Call appropriate payment method based on payment type
      if (_paymentType == 'interest') {
        await context
            .read<LoanProvider>()
            .makeInterestPayment(widget.loan.id, amount);
      } else {
        await context.read<LoanProvider>().makePayment(widget.loan.id, amount);
      }

      // Persist a linked payment transaction for traceability and bill status.
      final paymentExpense = Expense(
        id: AppUtils.generateId(),
        title: _paymentType == 'interest'
            ? 'Loan Interest Payment - ${widget.loan.lender}'
            : 'Loan EMI Payment - ${widget.loan.lender}',
        amount: amount,
        category: 'Loan Payment',
        paymentMethod: sourceAccount.accountType,
        date: DateTime.now(),
        accountId: sourceAccount.id,
        transactionType: 'payment',
        notes: _paymentType == 'interest'
            ? 'Interest-only payment'
            : 'Loan repayment',
      );
      await context.read<ExpenseProvider>().addExpense(paymentExpense);

      // Reflect debit in selected source account.
      final isCredit =
          sourceAccount.accountType.toLowerCase().contains('credit');
      final sourceDelta = isCredit ? amount : -amount;
      await accountProvider.adjustAccountBalance(sourceAccount.id, sourceDelta);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _paymentType == 'interest'
                ? 'Interest payment of ${AppUtils.formatCurrency(amount, currencySymbol: context.read<SettingsProvider>().currencySymbol)} recorded'
                : 'Payment of ${AppUtils.formatCurrency(amount, currencySymbol: context.read<SettingsProvider>().currencySymbol)} recorded',
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.watch<SettingsProvider>().currencySymbol;
    final remainingAmount = widget.loan.pendingAmount;
    final sourceAccounts = context
        .watch<PaymentAccountProvider>()
        .activeAccounts
        .where((a) => !a.accountType.toLowerCase().contains('loan'))
        .toList();

    final accountTypes = sourceAccounts
        .map((account) => account.accountType)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final selectedSourceAccount = _selectedSourceAccountId == null
        ? null
        : context
            .read<PaymentAccountProvider>()
            .getAccountById(_selectedSourceAccountId!);

    final selectedAccountTypeValue =
        accountTypes.contains(_selectedSourceAccountType)
            ? _selectedSourceAccountType
            : selectedSourceAccount?.accountType;

    final filteredSourceAccounts = selectedAccountTypeValue == null
        ? <PaymentAccount>[]
        : sourceAccounts
            .where((account) => account.accountType == selectedAccountTypeValue)
            .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    if (_selectedSourceAccountId == null && filteredSourceAccounts.isNotEmpty) {
      _selectedSourceAccountId = filteredSourceAccounts.first.id;
    }

    if (_selectedSourceAccountId != null &&
        filteredSourceAccounts
            .every((account) => account.id != _selectedSourceAccountId)) {
      _selectedSourceAccountId = null;
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom +
              effectiveBottomInset(context, minimum: 12),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Record Payment',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.loan.lender,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Remaining',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          Text(
                            AppUtils.formatCurrency(
                              remainingAmount,
                              currencySymbol: currencySymbol,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.errorColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'EMI Amount',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          Text(
                            AppUtils.formatCurrency(
                              widget.loan.monthlyEmi,
                              currencySymbol: currencySymbol,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _paymentType = 'emi';
                                _amountController.text =
                                    widget.loan.monthlyEmi.toStringAsFixed(2);
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: _paymentType == 'emi'
                                    ? AppTheme.primaryColor
                                    : Colors.grey,
                                width: _paymentType == 'emi' ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              'EMI Amount',
                              style: TextStyle(
                                fontSize: 12,
                                color: _paymentType == 'emi'
                                    ? AppTheme.primaryColor
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _paymentType = 'full';
                                _amountController.text =
                                    remainingAmount.toStringAsFixed(2);
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: _paymentType == 'full'
                                    ? AppTheme.primaryColor
                                    : Colors.grey,
                                width: _paymentType == 'full' ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              'Full Amount',
                              style: TextStyle(
                                fontSize: 12,
                                color: _paymentType == 'full'
                                    ? AppTheme.primaryColor
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _paymentType = 'interest';
                            _amountController.text = '';
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: _paymentType == 'interest'
                                ? AppTheme.accentColor
                                : Colors.grey,
                            width: _paymentType == 'interest' ? 2 : 1,
                          ),
                        ),
                        icon: Icon(
                          Icons.percent,
                          size: 16,
                          color: _paymentType == 'interest'
                              ? AppTheme.accentColor
                              : Colors.grey,
                        ),
                        label: Text(
                          'Interest Only (Balance Unchanged)',
                          style: TextStyle(
                            fontSize: 12,
                            color: _paymentType == 'interest'
                                ? AppTheme.accentColor
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Payment Amount',
                    border: const OutlineInputBorder(),
                    prefixText: '$currencySymbol ',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter payment amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    if (_paymentType != 'interest' &&
                        amount > remainingAmount) {
                      return 'Amount exceeds remaining balance';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownSearch<String>(
                  selectedItem: selectedAccountTypeValue,
                  items: accountTypes,
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: 'Account Type',
                      helperText: 'Filter source accounts by type',
                    ),
                  ),
                  popupProps: DropdownSearchUi.adaptiveMenuPopup<String>(
                    context: context,
                    searchHint: 'Search account type...',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedSourceAccountType = value;
                      _selectedSourceAccountId = null;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select account type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownSearch<String>(
                  selectedItem: _selectedSourceAccountId,
                  items: filteredSourceAccounts
                      .map((account) => account.id)
                      .toList(),
                  itemAsString: (id) {
                    final account = filteredSourceAccounts.firstWhere(
                      (item) => item.id == id,
                      orElse: () => filteredSourceAccounts.first,
                    );
                    return account.name;
                  },
                  compareFn: (first, second) => first == second,
                  dropdownBuilder: (context, selectedItem) {
                    if (selectedAccountTypeValue == null) {
                      return Text(
                        'Select account type first',
                        style: TextStyle(color: Theme.of(context).hintColor),
                      );
                    }

                    if (selectedItem == null) {
                      return Text(
                        'Select source account',
                        style: TextStyle(color: Theme.of(context).hintColor),
                      );
                    }

                    final account = filteredSourceAccounts.firstWhere(
                      (item) => item.id == selectedItem,
                      orElse: () => filteredSourceAccounts.first,
                    );

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.accountType,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          account.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    );
                  },
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: 'Source Account',
                      helperText: selectedAccountTypeValue == null
                          ? 'Choose account type first'
                          : 'Showing $selectedAccountTypeValue accounts',
                    ),
                  ),
                  popupProps: DropdownSearchUi.adaptiveMenuPopup<String>(
                    context: context,
                    searchHint: 'Search accounts...',
                    itemBuilder: (context, accountId, isSelected) {
                      final account = filteredSourceAccounts.firstWhere(
                        (item) => item.id == accountId,
                        orElse: () => filteredSourceAccounts.first,
                      );

                      return ListTile(
                        title: Text(account.name),
                        subtitle: Text(
                          '${account.accountType} • ${AppUtils.formatCurrency(account.balance, currencySymbol: currencySymbol)}',
                        ),
                      );
                    },
                    emptyBuilder: (context, searchEntry) => const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No accounts found for this type'),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedSourceAccountId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select source account';
                    }
                    return null;
                  },
                ),
                if (selectedSourceAccount != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Balance: ${AppUtils.formatCurrency(selectedSourceAccount.balance, currencySymbol: currencySymbol)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _recordPayment,
                        child: const Text('Record Payment'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
