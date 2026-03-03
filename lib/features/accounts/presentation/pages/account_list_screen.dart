import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/core/constants/app_constants.dart';
import 'package:fintrack/core/utils/custom_widgets.dart';
import 'package:fintrack/features/accounts/data/models/payment_account_model.dart';
import 'package:fintrack/features/accounts/presentation/providers/payment_account_provider.dart';
import 'package:fintrack/features/accounts/presentation/pages/account_form_screen.dart';
import 'package:fintrack/features/accounts/presentation/pages/account_transaction_screen.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';

class AccountListScreen extends StatefulWidget {
  final bool showBackButton;

  const AccountListScreen({super.key, this.showBackButton = false});

  @override
  State<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen> {
  late Map<String, bool> _expandedGroups = {};

  @override
  void initState() {
    super.initState();
    // Initialize all groups as expanded
    _expandedGroups = {};
  }

  Map<String, List<PaymentAccount>> _groupAccountsByType(
      List<PaymentAccount> accounts) {
    final grouped = <String, List<PaymentAccount>>{};
    for (final account in accounts) {
      grouped.putIfAbsent(account.accountType, () => []).add(account);
    }
    // Sort by account type name
    final sorted = <String, List<PaymentAccount>>{};
    for (final key in grouped.keys.toList()..sort()) {
      sorted[key] = grouped[key]!;
    }
    return sorted;
  }

  double _calculateGroupTotal(List<PaymentAccount> accounts) {
    return accounts.fold(0.0, (sum, account) => sum + account.balance);
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.watch<SettingsProvider>().currencySymbol;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Payment Accounts',
        showBackButton: widget.showBackButton,
      ),
      body: Consumer<PaymentAccountProvider>(
        builder: (context, provider, _) {
          final accounts = provider.accounts;

          if (accounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 80,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No accounts yet',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add a bank account, card, or wallet',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            );
          }

          final groupedAccounts = _groupAccountsByType(accounts);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.accentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Balance',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppUtils.formatCurrency(
                        provider.getTotalBalance(),
                        currencySymbol: currencySymbol,
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SummaryItem(
                          label: 'Active Accounts',
                          value: provider.activeAccounts.length.toString(),
                        ),
                        _SummaryItem(
                          label: 'Total Accounts',
                          value: accounts.length.toString(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Grouped Accounts
              Text(
                'Your Accounts',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 12),
              ...groupedAccounts.entries.map((entry) {
                final accountType = entry.key;
                final groupAccounts = entry.value;
                final isExpanded =
                    _expandedGroups.putIfAbsent(accountType, () => true);
                final groupTotal = _calculateGroupTotal(groupAccounts);

                return Column(
                  children: [
                    // Group Header
                    _AccountTypeHeader(
                      accountType: accountType,
                      accountCount: groupAccounts.length,
                      totalBalance: groupTotal,
                      currencySymbol: currencySymbol,
                      isExpanded: isExpanded,
                      onTap: () {
                        setState(() {
                          _expandedGroups[accountType] = !isExpanded;
                        });
                      },
                    ),
                    // Group Accounts
                    if (isExpanded) ...[
                      const SizedBox(height: 10),
                      ...groupAccounts.map((account) => _AccountCard(
                            account: account,
                            currencySymbol: currencySymbol,
                            onTap: () => _viewAccountTransactions(account),
                            onEdit: () => _editAccount(account),
                            onDelete: () => _deleteAccount(account),
                          )),
                    ],
                    const SizedBox(height: 14),
                  ],
                );
              }),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAccount,
        icon: const Icon(Icons.add),
        label: const Text('Add Account'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _addAccount() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AccountFormScreen(),
      ),
    );
  }

  void _editAccount(PaymentAccount account) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AccountFormScreen(account: account),
      ),
    );
  }

  Future<void> _deleteAccount(PaymentAccount account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Are you sure you want to delete "${account.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<PaymentAccountProvider>().deleteAccount(account.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account deleted successfully')),
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

  void _viewAccountTransactions(PaymentAccount account) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AccountTransactionScreen(account: account),
      ),
    );
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
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  final PaymentAccount account;
  final String currencySymbol;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AccountCard({
    required this.account,
    required this.currencySymbol,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = account.color != null
        ? Color(int.parse(account.color!.replaceFirst('#', '0xFF')))
        : AppTheme.primaryColor;

    return Dismissible(
      key: ValueKey(account.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (direction) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    _getIcon(),
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Account Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        account.typeLabel +
                            (account.bankName != null
                                ? ' • ${account.bankName}'
                                : ''),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.textSecondaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Balance
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      account.accountType.toLowerCase().contains('credit')
                          ? 'Outstanding'
                          : 'Balance',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppUtils.formatCurrency(
                        account.balance,
                        currencySymbol: currencySymbol,
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color:
                            account.accountType.toLowerCase().contains('credit')
                                ? AppTheme.errorColor
                                : AppTheme.textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),

                // Action Buttons
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.edit,
                        color: AppTheme.primaryColor, size: 18),
                    onPressed: onEdit,
                    tooltip: 'Edit',
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 18),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon() {
    final accountType = account.accountType.toLowerCase();

    if (accountType.contains('bank') || accountType.contains('savings')) {
      return Icons.account_balance;
    } else if (accountType.contains('credit')) {
      return Icons.credit_card;
    } else if (accountType.contains('debit')) {
      return Icons.payment;
    } else if (accountType.contains('wallet')) {
      return Icons.account_balance_wallet;
    } else if (accountType.contains('cash')) {
      return Icons.attach_money;
    } else if (accountType.contains('investment')) {
      return Icons.trending_up;
    } else if (accountType.contains('loan')) {
      return Icons.home;
    } else {
      return Icons.more_horiz;
    }
  }
}

class _AccountTypeHeader extends StatelessWidget {
  final String accountType;
  final int accountCount;
  final double totalBalance;
  final String currencySymbol;
  final bool isExpanded;
  final VoidCallback onTap;

  const _AccountTypeHeader({
    required this.accountType,
    required this.accountCount,
    required this.totalBalance,
    required this.currencySymbol,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      accountType,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$accountCount ${accountCount == 1 ? 'account' : 'accounts'}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppTheme.textSecondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppUtils.formatCurrency(
                      totalBalance,
                      currencySymbol: currencySymbol,
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
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
}
