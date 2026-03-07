import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/core/constants/app_constants.dart';
import 'package:fintrack/core/utils/custom_widgets.dart';
import 'package:fintrack/database/hive_service.dart';
import 'package:fintrack/features/accounts/data/models/payment_account_model.dart';
import 'package:fintrack/features/accounts/presentation/providers/payment_account_provider.dart';
import 'package:fintrack/features/accounts/presentation/pages/account_form_screen.dart';
import 'package:fintrack/features/accounts/presentation/pages/account_transaction_screen.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';

class AccountListScreen extends StatefulWidget {
  final bool showBackButton;
  final bool showAppBar;

  const AccountListScreen({
    super.key,
    this.showBackButton = false,
    this.showAppBar = true,
  });

  @override
  State<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen> {
  static const String _expandedGroupsSettingKey =
      'account_list_expanded_groups';
  late Map<String, bool> _expandedGroups = {};

  @override
  void initState() {
    super.initState();
    // Initialize groups map; categories default to collapsed on first render
    _expandedGroups = {};
    _loadExpandedGroups();
  }

  Future<void> _loadExpandedGroups() async {
    final saved = HiveService.getSetting(
      _expandedGroupsSettingKey,
      defaultValue: <String, dynamic>{},
    );

    if (saved is! Map) return;

    final restored = <String, bool>{};
    saved.forEach((key, value) {
      restored[key.toString()] = value == true;
    });

    if (!mounted) return;
    setState(() {
      _expandedGroups = restored;
    });
  }

  Future<void> _saveExpandedGroups() async {
    await HiveService.saveSetting(_expandedGroupsSettingKey, _expandedGroups);
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
      appBar: widget.showAppBar
          ? CustomAppBar(
              title: 'Payment Accounts',
              showBackButton: widget.showBackButton,
            )
          : null,
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

          void setAllGroupsExpanded(bool expanded) {
            setState(() {
              _expandedGroups = {
                for (final key in groupedAccounts.keys) key: expanded,
              };
            });
            _saveExpandedGroups();
          }

          final allGroupsExpanded = groupedAccounts.keys.isNotEmpty &&
              groupedAccounts.keys.every((key) => _expandedGroups[key] == true);

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
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Balance',
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
                        provider.getTotalBalance(),
                        currencySymbol: currencySymbol,
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Your Accounts',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 30,
                    child: FilledButton(
                      onPressed: () => setAllGroupsExpanded(!allGroupsExpanded),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        allGroupsExpanded ? 'Collapse all' : 'Expand all',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...groupedAccounts.entries.map((entry) {
                final accountType = entry.key;
                final groupAccounts = entry.value;
                final isExpanded =
                    _expandedGroups.putIfAbsent(accountType, () => false);
                final groupTotal = _calculateGroupTotal(groupAccounts);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Card(
                    color: Colors.white,
                    elevation: 1,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: AppTheme.primaryColor.withOpacity(0.12),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
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
                            _saveExpandedGroups();
                          },
                        ),
                        if (isExpanded) ...[
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: AppTheme.dividerColor,
                            indent: 12,
                            endIndent: 12,
                          ),
                          ...groupAccounts.asMap().entries.map((entry) {
                            final index = entry.key;
                            final account = entry.value;
                            return _AccountCard(
                              account: account,
                              currencySymbol: currencySymbol,
                              embedded: true,
                              showDivider: index != groupAccounts.length - 1,
                              onTap: () => _viewAccountTransactions(account),
                              onEdit: () => _editAccount(account),
                              onDelete: () => _deleteAccount(account),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 4),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        heroTag: 'account_list_fab_add',
        onPressed: _addAccount,
        tooltip: 'Add Account',
        child: const Icon(Icons.add),
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
            fontSize: 18,
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

class _AccountCard extends StatelessWidget {
  final PaymentAccount account;
  final String currencySymbol;
  final bool embedded;
  final bool showDivider;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AccountCard({
    required this.account,
    required this.currencySymbol,
    this.embedded = false,
    this.showDivider = true,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = account.color != null
        ? Color(int.parse(account.color!.replaceFirst('#', '0xFF')))
        : AppTheme.primaryColor;
    final isCredit = account.accountType.toLowerCase().contains('credit');

    final accountContent = InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          account.name,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.edit,
                              color: AppTheme.primaryColor, size: 16),
                          onPressed: onEdit,
                          tooltip: 'Edit',
                        ),
                      ),
                      const SizedBox(width: 2),
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 16),
                          onPressed: onDelete,
                          tooltip: 'Delete',
                        ),
                      ),
                    ],
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        isCredit ? 'Outstanding' : 'Balance',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            AppUtils.formatCurrency(
                              account.balance,
                              currencySymbol: currencySymbol,
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isCredit
                                  ? AppTheme.errorColor
                                  : AppTheme.textColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Show statement and due dates for credit cards
                  if (isCredit &&
                      (account.statementDate != null ||
                          account.dueDate != null)) ...[
                    const SizedBox(height: 6),
                    if (account.statementDate != null)
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_outlined,
                            size: 10,
                            color: AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Statement: ${account.statementDate!.day.toString().padLeft(2, '0')}/${account.statementDate!.month.toString().padLeft(2, '0')}/${account.statementDate!.year}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    if (account.dueDate != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.alarm_outlined,
                            size: 10,
                            color: AppTheme.errorColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Due: ${account.dueDate!.day.toString().padLeft(2, '0')}/${account.dueDate!.month.toString().padLeft(2, '0')}/${account.dueDate!.year}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppTheme.errorColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Dismissible(
      key: ValueKey(account.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: EdgeInsets.only(bottom: embedded ? 0 : 10),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          borderRadius: BorderRadius.circular(embedded ? 0 : 10),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (direction) => onDelete(),
      child: embedded
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                accountContent,
                if (showDivider)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppTheme.dividerColor,
                    indent: 12,
                    endIndent: 12,
                  ),
              ],
            )
          : Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: accountContent,
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      accountType,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
              const SizedBox(width: 12),
              Flexible(
                flex: 4,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Column(
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
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
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
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
