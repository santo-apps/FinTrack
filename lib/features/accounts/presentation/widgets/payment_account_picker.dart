import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/features/accounts/data/models/payment_account_model.dart';
import 'package:fintrack/features/accounts/presentation/providers/payment_account_provider.dart';

class PaymentAccountPicker extends StatelessWidget {
  final PaymentAccount? selectedAccount;
  final Function(PaymentAccount) onAccountSelected;
  final bool showOnlyActive;
  final String? label;

  const PaymentAccountPicker({
    super.key,
    required this.selectedAccount,
    required this.onAccountSelected,
    this.showOnlyActive = true,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentAccountProvider>(
      builder: (context, provider, _) {
        final accounts =
            showOnlyActive ? provider.activeAccounts : provider.accounts;

        if (accounts.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.errorColor),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: AppTheme.errorColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No payment accounts available. Please add one first.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.errorColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null) ...[
              Text(
                label!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () => _showAccountPicker(context, accounts),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildAccountIcon(selectedAccount),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedAccount?.name ?? 'Select Payment Account',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: selectedAccount != null
                                    ? AppTheme.textColor
                                    : AppTheme.textSecondaryColor,
                              ),
                            ),
                            if (selectedAccount != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                selectedAccount!.typeLabel,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccountIcon(PaymentAccount? account) {
    final color = account?.color != null
        ? Color(int.parse(account!.color!.replaceFirst('#', '0xFF')))
        : AppTheme.primaryColor;

    IconData icon;
    if (account != null) {
      final accountType = account.accountType.toLowerCase();
      if (accountType.contains('bank') || accountType.contains('savings')) {
        icon = Icons.account_balance;
      } else if (accountType.contains('credit')) {
        icon = Icons.credit_card;
      } else if (accountType.contains('debit')) {
        icon = Icons.payment;
      } else if (accountType.contains('wallet')) {
        icon = Icons.account_balance_wallet;
      } else if (accountType.contains('cash')) {
        icon = Icons.attach_money;
      } else if (accountType.contains('investment')) {
        icon = Icons.trending_up;
      } else if (accountType.contains('loan')) {
        icon = Icons.home;
      } else {
        icon = Icons.more_horiz;
      }
    } else {
      icon = Icons.account_balance_wallet;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  void _showAccountPicker(BuildContext context, List<PaymentAccount> accounts) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Select Payment Account',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: ListView.builder(
                itemCount: accounts.length,
                itemBuilder: (context, index) {
                  final account = accounts[index];
                  final isSelected = selectedAccount?.id == account.id;
                  final color = account.color != null
                      ? Color(
                          int.parse(account.color!.replaceFirst('#', '0xFF')))
                      : AppTheme.primaryColor;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: isSelected ? 4 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ListTile(
                      onTap: () {
                        onAccountSelected(account);
                        Navigator.pop(context);
                      },
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getAccountIcon(account.accountType),
                          color: color,
                          size: 20,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              account.name,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textColor,
                              ),
                            ),
                          ),
                          if (account.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.successColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Default',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.successColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        account.typeLabel +
                            (account.bankName != null
                                ? ' • ${account.bankName}'
                                : ''),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle,
                              color: AppTheme.primaryColor)
                          : null,
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

  IconData _getAccountIcon(String accountType) {
    final type = accountType.toLowerCase();
    if (type.contains('bank') || type.contains('savings')) {
      return Icons.account_balance;
    } else if (type.contains('credit')) {
      return Icons.credit_card;
    } else if (type.contains('debit')) {
      return Icons.payment;
    } else if (type.contains('wallet')) {
      return Icons.account_balance_wallet;
    } else if (type.contains('cash')) {
      return Icons.attach_money;
    } else if (type.contains('investment')) {
      return Icons.trending_up;
    } else if (type.contains('loan')) {
      return Icons.home;
    } else {
      return Icons.more_horiz;
    }
  }
}
