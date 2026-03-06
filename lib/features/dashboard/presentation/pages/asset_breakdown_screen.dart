import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/core/constants/app_constants.dart';
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
  double _effectiveInvestmentValue(Investment investment) {
    final marketValue = investment.getCurrentValue();
    final investedCost = investment.getTotalInvestmentValue();
    return (marketValue <= 0 && investedCost > 0) ? investedCost : marketValue;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
          final accountShare =
              totalAssets > 0 ? (accountTotal / totalAssets) : 0.0;
          final investmentShare =
              totalAssets > 0 ? (investmentTotal / totalAssets) : 0.0;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: [
              Card(
                elevation: 3,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Assets',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppUtils.formatCurrency(
                          totalAssets,
                          currencySymbol: currencySymbol,
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SizedBox(
                          height: 8,
                          child: Row(
                            children: [
                              Expanded(
                                flex: (accountShare * 1000)
                                    .round()
                                    .clamp(0, 1000),
                                child: Container(color: Colors.green.shade500),
                              ),
                              Expanded(
                                flex: (investmentShare * 1000)
                                    .round()
                                    .clamp(0, 1000),
                                child: Container(color: colorScheme.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryMetric(
                              title: 'Accounts',
                              value: AppUtils.formatCurrency(
                                accountTotal,
                                currencySymbol: currencySymbol,
                              ),
                              icon: Icons.account_balance_wallet_outlined,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SummaryMetric(
                              title: 'Investments',
                              value: AppUtils.formatCurrency(
                                investmentTotal,
                                currencySymbol: currencySymbol,
                              ),
                              icon: Icons.trending_up_outlined,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const AccountListScreen(showBackButton: true),
                          ),
                        );
                      },
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                      label: const Text('Accounts'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
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
                      label: const Text('Investments'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: false,
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        child: Column(
                          children: [
                            if (accounts.isEmpty)
                              const _EmptySection(
                                  message: 'No asset accounts found')
                            else
                              ...accounts.map((account) {
                                return _DataRowItem(
                                  title: account.name,
                                  subtitle: account.accountType,
                                  value: AppUtils.formatCurrency(
                                    account.balance,
                                    currencySymbol: currencySymbol,
                                  ),
                                  valueColor: Colors.green.shade700,
                                );
                              }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: false,
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
                        color: colorScheme.primary,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        child: Column(
                          children: [
                            if (investments.isEmpty)
                              const _EmptySection(
                                  message: 'No investments found')
                            else
                              ...investments.map((investment) {
                                final effectiveValue =
                                    _effectiveInvestmentValue(investment);
                                final invested =
                                    investment.getTotalInvestmentValue();
                                final gain = effectiveValue - invested;
                                final gainPercent =
                                    invested > 0 ? (gain / invested) * 100 : 0;

                                return _DataRowItem(
                                  title: investment.name,
                                  subtitle:
                                      '${investment.type} • ${gain >= 0 ? 'Gain' : 'Loss'}: ${AppUtils.formatCurrency(gain, currencySymbol: currencySymbol)} (${gainPercent.toStringAsFixed(1)}%)',
                                  value: AppUtils.formatCurrency(
                                    effectiveValue,
                                    currencySymbol: currencySymbol,
                                  ),
                                  valueColor: colorScheme.primary,
                                );
                              }),
                          ],
                        ),
                      ),
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

class _SummaryMetric extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String total;
  final Color totalColor;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.total,
    required this.totalColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              size: 18, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          total,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: totalColor,
          ),
        ),
      ],
    );
  }
}

class _DataRowItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final Color valueColor;

  const _DataRowItem({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
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
