import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/core/utils/custom_widgets.dart';
import 'package:fintrack/features/accounts/data/models/payment_account_model.dart';
import 'package:fintrack/features/accounts/presentation/providers/payment_account_provider.dart';
import 'package:fintrack/features/receivable/data/models/receivable_model.dart';
import 'package:fintrack/features/receivable/presentation/providers/receivable_provider.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';

class AddEditReceivableDialog extends StatefulWidget {
  final Receivable? receivable;

  const AddEditReceivableDialog({super.key, this.receivable});

  @override
  State<AddEditReceivableDialog> createState() =>
      _AddEditReceivableDialogState();
}

class _AddEditReceivableDialogState extends State<AddEditReceivableDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _dueDate;
  late int _remindBeforeDays;
  bool _isRecurring = false;
  DateTime? _recurringEndDate;
  String? _selectedAccountType;
  String? _selectedAccountId;

  bool get _isEdit => widget.receivable != null;

  @override
  void initState() {
    super.initState();
    final receivable = widget.receivable;
    if (receivable != null) {
      _titleController.text = receivable.title;
      _amountController.text = receivable.amount.toStringAsFixed(2);
      _notesController.text = receivable.notes ?? '';
      _dueDate = receivable.dueDate;
      _remindBeforeDays = receivable.remindBeforeDays;
      _isRecurring = receivable.isRecurring;
      _recurringEndDate = receivable.recurringEndDate;
      _selectedAccountId = receivable.accountId;
    } else {
      _dueDate = DateTime.now().add(const Duration(days: 7));
      _remindBeforeDays = 3;
      _isRecurring = false;
      _recurringEndDate = null;
      _selectedAccountId = null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final settings = context.read<SettingsProvider>();
    final provider = context.read<ReceivableProvider>();

    if (_isRecurring && _recurringEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a recurring end date')),
      );
      return;
    }

    if (_isRecurring && _recurringEndDate!.isBefore(_dueDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Recurring end date must be on/after due date')),
      );
      return;
    }

    if (_isEdit) {
      final updated = widget.receivable!.copyWith(
        title: _titleController.text.trim(),
        amount: amount,
        dueDate: _dueDate,
        remindBeforeDays: _remindBeforeDays,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        currency: settings.currency,
        accountId: _selectedAccountId,
        isRecurring: _isRecurring,
        recurringEndDate: _isRecurring ? _recurringEndDate : null,
      );
      await provider.saveEditedReceivable(
        original: widget.receivable!,
        edited: updated,
      );
    } else {
      await provider.addReceivable(
        Receivable(
          id: const Uuid().v4(),
          title: _titleController.text.trim(),
          amount: amount,
          dueDate: _dueDate,
          remindBeforeDays: _remindBeforeDays,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          currency: settings.currency,
          accountId: _selectedAccountId,
          createdAt: DateTime.now(),
          isRecurring: _isRecurring,
          recurringEndDate: _isRecurring ? _recurringEndDate : null,
          recurrenceGroupId: _isRecurring ? const Uuid().v4() : null,
        ),
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String _formatAccountBalance(PaymentAccount account, String currencySymbol) {
    return '$currencySymbol ${account.balance.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? 'Edit Receivable' : 'Add Receivable';
    final currencySymbol = context.watch<SettingsProvider>().currencySymbol;
    final accountProvider = context.watch<PaymentAccountProvider>();
    final eligibleAccounts = accountProvider.activeAccounts
        .where(
          (account) => !account.accountType.toLowerCase().contains('credit'),
        )
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final selectedAccount = eligibleAccounts.cast<PaymentAccount?>().firstWhere(
          (account) => account?.id == _selectedAccountId,
          orElse: () => null,
        );
    final accountTypes = eligibleAccounts
        .map((account) => account.accountType)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final selectedAccountTypeValue = accountTypes.contains(_selectedAccountType)
        ? _selectedAccountType
        : selectedAccount?.accountType;
    final filteredAccounts = selectedAccountTypeValue == null
        ? <PaymentAccount>[]
        : eligibleAccounts
            .where((account) => account.accountType == selectedAccountTypeValue)
            .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final filteredSelectedAccount = filteredAccounts
        .cast<PaymentAccount?>()
        .firstWhere((account) => account?.id == _selectedAccountId,
            orElse: () => null);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            effectiveBottomInset(context, minimum: 16),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    InputDecoration(labelText: 'Amount ($currencySymbol)'),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDueDate,
                child: InputDecorator(
                  decoration:
                      const InputDecoration(labelText: 'Receivable Date'),
                  child: Text(
                    '${_dueDate.day.toString().padLeft(2, '0')}/${_dueDate.month.toString().padLeft(2, '0')}/${_dueDate.year}',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _remindBeforeDays,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('On due date')),
                  DropdownMenuItem(value: 1, child: Text('1 day before')),
                  DropdownMenuItem(value: 2, child: Text('2 days before')),
                  DropdownMenuItem(value: 3, child: Text('3 days before')),
                  DropdownMenuItem(value: 5, child: Text('5 days before')),
                  DropdownMenuItem(value: 7, child: Text('7 days before')),
                  DropdownMenuItem(value: 10, child: Text('10 days before')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _remindBeforeDays = value);
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Remind me before',
                ),
              ),
              const SizedBox(height: 12),
              DropdownSearch<String>(
                selectedItem: selectedAccountTypeValue,
                items: accountTypes,
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  constraints: const BoxConstraints(maxHeight: 320),
                  fit: FlexFit.loose,
                  menuProps: MenuProps(
                    borderRadius: BorderRadius.circular(12),
                    elevation: 6,
                  ),
                  searchFieldProps: const TextFieldProps(
                    decoration: InputDecoration(
                      hintText: 'Search account type...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                dropdownDecoratorProps: const DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: 'Account Type (for receivable mapping)',
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedAccountType = value;
                    if (_selectedAccountId != null) {
                      final selected = eligibleAccounts.firstWhere(
                        (account) => account.id == _selectedAccountId,
                        orElse: () => PaymentAccount(
                          id: '',
                          name: '',
                          accountType: '',
                          createdAt: DateTime.now(),
                        ),
                      );
                      if (selected.id.isEmpty ||
                          selected.accountType != _selectedAccountType) {
                        _selectedAccountId = null;
                      }
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownSearch<PaymentAccount?>(
                selectedItem: filteredSelectedAccount,
                items: filteredAccounts,
                itemAsString: (PaymentAccount? account) {
                  if (account == null) {
                    return 'No mapped account';
                  }
                  return '${account.accountType} • ${account.displayName}';
                },
                compareFn: (PaymentAccount? first, PaymentAccount? second) {
                  return first?.id == second?.id;
                },
                dropdownBuilder: (context, selectedItem) {
                  if (selectedAccountTypeValue == null) {
                    return Text(
                      'Select account type first',
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                      ),
                    );
                  }

                  if (selectedItem == null) {
                    return Text(
                      'No mapped account',
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                      ),
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedItem.accountType,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).hintColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedItem.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatAccountBalance(selectedItem, currencySymbol),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  );
                },
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: 'Receive Into Account (optional)',
                    helperText: selectedAccountTypeValue == null
                        ? 'Choose account type first'
                        : 'Showing $selectedAccountTypeValue accounts',
                    suffixIcon: _selectedAccountId == null
                        ? null
                        : IconButton(
                            tooltip: 'Clear mapped account',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() => _selectedAccountId = null);
                            },
                          ),
                  ),
                ),
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  constraints: const BoxConstraints(maxHeight: 320),
                  fit: FlexFit.loose,
                  menuProps: MenuProps(
                    borderRadius: BorderRadius.circular(12),
                    elevation: 6,
                  ),
                  searchFieldProps: const TextFieldProps(
                    decoration: InputDecoration(
                      hintText: 'Search accounts...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  itemBuilder: (context, account, isSelected) {
                    if (account == null) {
                      return const SizedBox.shrink();
                    }

                    final accountBalance =
                        _formatAccountBalance(account, currencySymbol);

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor.withValues(alpha: 0.08)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
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
                                  account.displayName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            accountBalance,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  emptyBuilder: (context, searchEntry) => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No eligible non-credit accounts found'),
                  ),
                ),
                onChanged: (PaymentAccount? account) {
                  setState(() => _selectedAccountId = account?.id);
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _isRecurring,
                onChanged: (value) {
                  setState(() {
                    _isRecurring = value;
                    if (!value) {
                      _recurringEndDate = null;
                    }
                  });
                },
                title: const Text('Recurring monthly'),
                subtitle:
                    const Text('Create monthly receivables until an end date'),
              ),
              if (_isRecurring) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _recurringEndDate ?? _dueDate,
                      firstDate: _dueDate,
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _recurringEndDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration:
                        const InputDecoration(labelText: 'Recurring until'),
                    child: Text(
                      _recurringEndDate == null
                          ? 'Select end date'
                          : '${_recurringEndDate!.day.toString().padLeft(2, '0')}/${_recurringEndDate!.month.toString().padLeft(2, '0')}/${_recurringEndDate!.year}',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'Notes (optional)'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(_isEdit ? 'Save Changes' : 'Add Receivable'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
