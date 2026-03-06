import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/core/utils/custom_widgets.dart';
import 'package:fintrack/features/accounts/data/models/payment_account_model.dart';
import 'package:fintrack/features/accounts/data/models/account_type_model.dart';
import 'package:fintrack/features/accounts/presentation/providers/payment_account_provider.dart';
import 'package:fintrack/features/accounts/presentation/providers/account_type_provider.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';

class AccountFormScreen extends StatefulWidget {
  final PaymentAccount? account;

  const AccountFormScreen({super.key, this.account});

  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late TextEditingController _accountNumberController;
  late TextEditingController _bankNameController;
  late TextEditingController _creditLimitController;
  late TextEditingController _notesController;

  String? _selectedAccountType;
  bool _isDefault = false;
  bool _isActive = true;
  String? _selectedColor;
  DateTime? _expiryDate;
  String? _cardNetwork;
  String? _linkedAccountId;

  final List<String> _accountColors = [
    '#6366F1', // Indigo
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#EF4444', // Red
    '#F59E0B', // Amber
    '#10B981', // Green
    '#3B82F6', // Blue
    '#06B6D4', // Cyan
  ];

  final List<String> _cardNetworks = [
    'Visa',
    'Mastercard',
    'American Express',
    'Discover',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name);
    _balanceController = TextEditingController(
      text: widget.account?.balance.toStringAsFixed(2) ?? '0.00',
    );
    _accountNumberController =
        TextEditingController(text: widget.account?.accountNumber);
    _bankNameController = TextEditingController(text: widget.account?.bankName);
    _creditLimitController = TextEditingController(
      text: widget.account?.creditLimit?.toStringAsFixed(2),
    );
    _notesController = TextEditingController(text: widget.account?.notes);

    if (widget.account != null) {
      _selectedAccountType = widget.account!.accountType;
      _isDefault = widget.account!.isDefault;
      _isActive = widget.account!.isActive;
      _selectedColor = widget.account!.color;
      _expiryDate = widget.account!.expiryDate;
      _linkedAccountId = widget.account!.linkedAccountId;
      _cardNetwork = widget.account!.cardNetwork;
    } else {
      _selectedColor = _accountColors[0];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    _creditLimitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.account != null;

    return Scaffold(
      appBar: CustomAppBar(
        title: isEdit ? 'Edit Account' : 'Add Account',
        showBackButton: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Account Type
            Text(
              'Account Type',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Consumer<AccountTypeProvider>(
              builder: (context, accountTypeProvider, child) {
                final accountTypes = accountTypeProvider.activeAccountTypes;

                return DropdownSearch<AccountTypeModel>(
                  selectedItem: _selectedAccountType != null
                      ? accountTypeProvider
                          .getAccountTypeByName(_selectedAccountType!)
                      : null,
                  items: accountTypes,
                  itemAsString: (AccountTypeModel type) => type.name,
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      hintText: 'Select account type',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: AppTheme.primaryColor, width: 2),
                      ),
                    ),
                  ),
                  popupProps: PopupPropsMultiSelection.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        hintText: 'Search account type...',
                        prefixIcon: const Icon(Icons.search),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    menuProps: MenuProps(
                      borderRadius: BorderRadius.circular(8),
                      elevation: 4,
                    ),
                    itemBuilder: (context, item, isSelected) {
                      final color = item.color != null
                          ? Color(
                              int.parse(item.color!.replaceFirst('#', '0xFF')))
                          : AppTheme.primaryColor;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withOpacity(0.1) : null,
                        ),
                        child: Row(
                          children: [
                            if (item.icon != null)
                              Text(
                                item.icon!,
                                style: GoogleFonts.poppins(fontSize: 20),
                              )
                            else
                              Icon(
                                Icons.category,
                                color: isSelected
                                    ? color
                                    : AppTheme.textSecondaryColor,
                                size: 20,
                              ),
                            const SizedBox(width: 12),
                            Text(
                              item.name,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected ? color : AppTheme.textColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  onChanged: (AccountTypeModel? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedAccountType = newValue.name;
                      });
                    }
                  },
                  validator: (AccountTypeModel? value) {
                    if (value == null) {
                      return 'Please select an account type';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // Account Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Account Name',
                hintText: 'e.g., Primary Checking',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter account name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Balance
            TextFormField(
              controller: _balanceController,
              decoration: InputDecoration(
                labelText:
                    _selectedAccountType?.toLowerCase().contains('credit') ==
                            true
                        ? 'Outstanding Balance'
                        : 'Current Balance',
                hintText: '0.00',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter balance';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Credit Limit (for credit cards)
            if (_selectedAccountType?.toLowerCase().contains('credit') ==
                true) ...[
              TextFormField(
                controller: _creditLimitController,
                decoration: const InputDecoration(
                  labelText: 'Credit Limit',
                  hintText: '0.00',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
            ],

            // Bank Name
            if (_selectedAccountType?.toLowerCase().contains('bank') == true ||
                _selectedAccountType?.toLowerCase().contains('credit') ==
                    true ||
                _selectedAccountType?.toLowerCase().contains('debit') ==
                    true) ...[
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(
                  labelText: 'Bank Name',
                  hintText: 'e.g., Chase, Bank of America',
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Account Number
            TextFormField(
              controller: _accountNumberController,
              decoration: const InputDecoration(
                labelText: 'Account/Card Number (last 4 digits)',
                hintText: '1234',
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
            ),
            const SizedBox(height: 16),

            // Card Network (for cards)
            if (_selectedAccountType?.toLowerCase().contains('credit') ==
                    true ||
                _selectedAccountType?.toLowerCase().contains('debit') ==
                    true) ...[
              Text(
                'Card Network',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _cardNetwork,
                    isExpanded: true,
                    hint: const Text('Select network'),
                    items: _cardNetworks.map((network) {
                      return DropdownMenuItem(
                        value: network,
                        child: Text(network),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _cardNetwork = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Expiry Date (for cards)
            if (_selectedAccountType?.toLowerCase().contains('credit') ==
                    true ||
                _selectedAccountType?.toLowerCase().contains('debit') ==
                    true) ...[
              Text(
                'Expiry Date',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectExpiryDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _expiryDate != null
                            ? '${_expiryDate!.month.toString().padLeft(2, '0')}/${_expiryDate!.year}'
                            : 'Select expiry date',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: _expiryDate != null
                              ? AppTheme.textColor
                              : AppTheme.textSecondaryColor,
                        ),
                      ),
                      Icon(Icons.calendar_today,
                          color: AppTheme.textSecondaryColor, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Linked Account
            Text(
              'Linked Account (Optional)',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Link this account to another account (e.g., debit card to bank account)',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Consumer<PaymentAccountProvider>(
              builder: (context, accountProvider, child) {
                // Filter out current account from list
                final availableAccounts = accountProvider.accounts
                    .where((acc) => acc.id != widget.account?.id)
                    .toList();

                return DropdownSearch<PaymentAccount>(
                  selectedItem: _linkedAccountId != null
                      ? availableAccounts.firstWhere(
                          (acc) => acc.id == _linkedAccountId,
                          orElse: () => availableAccounts.isNotEmpty
                              ? availableAccounts.first
                              : PaymentAccount(
                                  id: '',
                                  name: '',
                                  accountType: '',
                                  createdAt: DateTime.now(),
                                ),
                        )
                      : null,
                  items: availableAccounts,
                  itemAsString: (PaymentAccount acc) => acc.displayName,
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      hintText: 'Select linked account (optional)',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: AppTheme.primaryColor, width: 2),
                      ),
                    ),
                  ),
                  popupProps: PopupPropsMultiSelection.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        hintText: 'Search accounts...',
                        prefixIcon: const Icon(Icons.search),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    menuProps: MenuProps(
                      borderRadius: BorderRadius.circular(8),
                      elevation: 4,
                    ),
                    itemBuilder: (context, item, isSelected) {
                      final color = item.color != null
                          ? Color(
                              int.parse(item.color!.replaceFirst('#', '0xFF')))
                          : AppTheme.primaryColor;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withOpacity(0.1) : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  item.accountType.isNotEmpty
                                      ? item.accountType[0].toUpperCase()
                                      : '?',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.displayName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textColor,
                                    ),
                                  ),
                                  Text(
                                    item.accountType,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppTheme.textSecondaryColor,
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
                  onChanged: (PaymentAccount? newValue) {
                    setState(() {
                      _linkedAccountId = newValue?.id;
                    });
                  },
                  clearButtonProps: const ClearButtonProps(isVisible: true),
                );
              },
            ),
            const SizedBox(height: 24),

            //
            // Color Selection
            Text(
              'Account Color',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _accountColors.map((colorHex) {
                final color =
                    Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
                final isSelected = _selectedColor == colorHex;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = colorHex;
                    });
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Add any additional notes',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Switches
            SwitchListTile(
              title: Text(
                'Set as Default Account',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textColor,
                ),
              ),
              subtitle: Text(
                'Use this account by default for transactions',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              value: _isDefault,
              onChanged: (value) {
                setState(() {
                  _isDefault = value;
                });
              },
              activeColor: AppTheme.primaryColor,
            ),
            SwitchListTile(
              title: Text(
                'Active Account',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textColor,
                ),
              ),
              subtitle: Text(
                'Show this account in your active accounts',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
              activeColor: AppTheme.primaryColor,
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveAccount,
                child: Text(isEdit ? 'Update Account' : 'Add Account'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _selectExpiryDate() async {
    final initialDate = _expiryDate ??
        DateTime.now().add(const Duration(days: 1095)); // 3 years
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 years
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
        _expiryDate = picked;
      });
    }
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAccountType == null || _selectedAccountType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account type')),
      );
      return;
    }

    final name = _nameController.text.trim();
    final balance = double.tryParse(_balanceController.text.trim()) ?? 0.0;
    final accountNumber = _accountNumberController.text.trim();
    final bankName = _bankNameController.text.trim();
    final creditLimit = double.tryParse(_creditLimitController.text.trim());
    final notes = _notesController.text.trim();

    final currencyCode = context.read<SettingsProvider>().currency;

    final account = PaymentAccount(
      id: widget.account?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      accountType: _selectedAccountType!,
      balance: balance,
      accountNumber: accountNumber.isNotEmpty ? accountNumber : null,
      bankName: bankName.isNotEmpty ? bankName : null,
      currency: currencyCode,
      color: _selectedColor,
      isDefault: _isDefault,
      isActive: _isActive,
      createdAt: widget.account?.createdAt ?? DateTime.now(),
      lastUpdated: DateTime.now(),
      notes: notes.isNotEmpty ? notes : null,
      creditLimit: creditLimit,
      expiryDate: _expiryDate,
      cardNetwork: _cardNetwork,
      linkedAccountId: _linkedAccountId,
    );

    try {
      final provider = context.read<PaymentAccountProvider>();
      if (widget.account == null) {
        await provider.addAccount(account);
      } else {
        await provider.updateAccount(account);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.account == null
                ? 'Account added successfully'
                : 'Account updated successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}
