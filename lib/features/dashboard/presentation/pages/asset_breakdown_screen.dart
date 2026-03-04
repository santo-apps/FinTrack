import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/core/constants/app_constants.dart';
import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/features/accounts/presentation/pages/account_list_screen.dart';
import 'package:fintrack/features/accounts/presentation/providers/payment_account_provider.dart';
import 'package:fintrack/features/investment/data/models/investment_model.dart';
import 'package:fintrack/features/investment/presentation/pages/investment_portfolio_screen.dart';
import 'package:fintrack/features/investment/presentation/providers/investment_provider.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';

class AssetBreakdownScreen extends StatefulWidget {
  const AssetBreakdownScreen({super.key});

  @override
  State<AssetBreakdownScreen> createState() => _AssetBreakdownScreenState();
}

class _AssetBreakdownScreenState extends State<AssetBreakdownScreen> {
  bool _accountsExpanded = false;
  bool _investmentsExpanded = false;

  double _effectiveInvestmentValue(Investment investment) {
    final marketValue = investment.getCurrentValue();
    final investedCost = investment.getTotalInvestmentValue();
    return (marketValue <= 0 && investedCost > 0) ? investedCost : marketValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Breakdown'),
      ),
      body: Consumer3<PaymentAccountProvider, InvestmentProvider,
          SettingsProvider>(
        builder: (context, accountProvider, investmentProvider, settings, _) {
          final accounts = accountProvider.activeAccounts
              .where((account) =>
                  !account.accountType.toLowerCase().contains('credit'))
              .toList();
          final investments = investmentProvider.investments;
          final currencySymbol = settings.currencySymbol;

          final accountTotal = accounts.fold<double>(
            0,
            (sum, account) => sum + account.balance,
          );
          final investmentTotal = investments.fold<double>(
            0,
            (sum, investment) => sum + _effectiveInvestmentValue(investment),
          );
          final totalAssets = accountTotal + investmentTotal;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Assets',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppUtils.formatCurrency(
                          totalAssets,
                          currencySymbol: currencySymbol,
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Accounts: ${AppUtils.formatCurrency(accountTotal, currencySymbol: currencySymbol)}',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Investments: ${AppUtils.formatCurrency(investmentTotal, currencySymbol: currencySymbol)}',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const AccountListScreen(showBackButton: true),
                          ),
                        );
                      },
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                      label: const Text('Manage Accounts'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const InvestmentPortfolioScreen(
                              showAppBar: true,
                              showBackButton: true,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.trending_up_outlined),
                      label: const Text('Manage Investments'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                elevation: _accountsExpanded ? 6 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _accountsExpanded = expanded;
                      });
                    },
                    title: Text(
                      'Accounts',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      AppUtils.formatCurrency(
                        accountTotal,
                        currencySymbol: currencySymbol,
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                    children: [
                      if (accounts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _EmptySection(
                            message: 'No asset accounts found',
                          ),
                        )
                      else
                        ...accounts.map((account) {
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            title: Text(
                              account.name,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              account.accountType,
                              style: GoogleFonts.poppins(fontSize: 11),
                            ),
                            trailing: Text(
                              AppUtils.formatCurrency(
                                account.balance,
                                currencySymbol: currencySymbol,
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.green.shade700,
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: _investmentsExpanded ? 6 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _investmentsExpanded = expanded;
                      });
                    },
                    title: Text(
                      'Investments',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      AppUtils.formatCurrency(
                        investmentTotal,
                        currencySymbol: currencySymbol,
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    children: [
                      if (investments.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _EmptySection(message: 'No investments found'),
                        )
                      else
                        ...investments.map((investment) {
                          final effectiveValue =
                              _effectiveInvestmentValue(investment);
                          final invested = investment.getTotalInvestmentValue();
                          final gain = effectiveValue - invested;
                          final gainPercent =
                              invested > 0 ? (gain / invested) * 100 : 0;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            title: Text(
                              investment.name,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${investment.type} • Gain/Loss: ${AppUtils.formatCurrency(gain, currencySymbol: currencySymbol)} (${gainPercent.toStringAsFixed(1)}%)',
                              style: GoogleFonts.poppins(fontSize: 11),
                            ),
                            trailing: Text(
                              AppUtils.formatCurrency(
                                effectiveValue,
                                currencySymbol: currencySymbol,
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String message;

  const _EmptySection({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
}
