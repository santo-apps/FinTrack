import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/core/utils/custom_widgets.dart';
import 'package:fintrack/features/accounts/data/models/payment_account_model.dart';
import 'package:fintrack/features/accounts/presentation/providers/payment_account_provider.dart';

typedef CalculatorSubmit = FutureOr<void> Function(
  double amount,
  String? selectedAccountId,
);

class TransactionCalculatorSheet extends StatefulWidget {
  final PaymentAccount? sourceAccount;
  final String transactionType;
  final double? initialAmount;
  final String? title;
  final String actionLabel;
  final CalculatorSubmit onSubmit;

  const TransactionCalculatorSheet({
    super.key,
    this.sourceAccount,
    required this.transactionType,
    this.initialAmount,
    this.title,
    this.actionLabel = 'SAVE',
    required this.onSubmit,
  });

  @override
  State<TransactionCalculatorSheet> createState() =>
      _TransactionCalculatorSheetState();
}

class _TransactionCalculatorSheetState
    extends State<TransactionCalculatorSheet> {
  String _display = '0';
  String _input = '';
  String _operation = '';
  double _accumulated = 0;
  bool _newNumber = true;
  String? _selectedAccountId;
  final TextEditingController _accountFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      _display = widget.initialAmount!.toStringAsFixed(2);
      _input = _display;
      _newNumber = false;
    }
  }

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

  Future<void> _submit() async {
    final amount = double.tryParse(_input) ?? 0;
    if (amount <= 0) {
      showTimedSnackBar(
        context,
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final requiresAccount = widget.transactionType == 'transfer' ||
        widget.transactionType == 'payment';
    if (requiresAccount && _selectedAccountId == null) {
      showTimedSnackBar(
        context,
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

    Navigator.pop(context);
    await widget.onSubmit(amount, _selectedAccountId);
  }

  void _showAccountPicker(
    List<PaymentAccount> availableAccounts,
    String title,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor:
          isDarkMode ? Theme.of(context).colorScheme.surface : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        String query = '';

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredAccounts = availableAccounts.where((account) {
              final queryLower = query.toLowerCase();
              final nameMatch = account.name.toLowerCase().contains(queryLower);
              final typeMatch =
                  account.accountType.toLowerCase().contains(queryLower);
              return nameMatch || typeMatch;
            }).toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  effectiveBottomInset(context) + 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : AppTheme.textColor,
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
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'No matching accounts',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : null,
                          ),
                        ),
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

  String _getTitle(PaymentAccount? sourceAccount) {
    if (widget.title != null && widget.title!.trim().isNotEmpty) {
      return widget.title!;
    }
    final isCreditCard =
        sourceAccount?.accountType.toLowerCase().contains('credit') ?? false;
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

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<PaymentAccountProvider>();
    final accounts = accountProvider.accounts;
    final sourceAccount = widget.sourceAccount == null
        ? null
        : accountProvider.getAccountById(widget.sourceAccount!.id);

    final requiresAccount = widget.transactionType == 'transfer' ||
        widget.transactionType == 'payment';

    final availableAccounts = accounts.where((account) {
      if (!account.isActive) return false;
      if (widget.transactionType == 'transfer') {
        return account.id != sourceAccount?.id &&
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

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        color:
            isDarkMode ? Theme.of(context).colorScheme.surface : Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white54 : Colors.grey.shade300,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getTitle(sourceAccount),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : AppTheme.textColor,
                  ),
                ),
                ElevatedButton(
                  onPressed: _submit,
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
                    widget.actionLabel,
                    style: const TextStyle(
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              _display,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : AppTheme.textColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
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
                SizedBox(
                  height: 50,
                  child: GestureDetector(
                    onTap: _calculate,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          '=',
                          style: TextStyle(
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _clear,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isDarkMode ? Colors.white54 : Colors.grey.shade300,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode
                        ? Colors.white70
                        : AppTheme.textSecondaryColor,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: effectiveBottomInset(context) + 24),
        ],
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: () => _handleNumber(number),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : AppTheme.textColor,
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
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              op,
              style: const TextStyle(
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: _handleDecimal,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : AppTheme.textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: _delete,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              color: isDarkMode ? Colors.white : AppTheme.textColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
