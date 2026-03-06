import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/core/constants/app_constants.dart';
import 'package:fintrack/features/accounts/presentation/providers/payment_account_provider.dart';
import 'package:fintrack/features/investment/presentation/providers/investment_provider.dart';
import 'package:fintrack/features/loan/presentation/providers/loan_provider.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';

class NetWorthBreakdownScreen extends StatefulWidget {
  final double assets;
  final double loans;
  final double netWorth;

  const NetWorthBreakdownScreen({
    required this.assets,
    required this.loans,
    required this.netWorth,
    super.key,
  });

  @override
  State<NetWorthBreakdownScreen> createState() =>
      _NetWorthBreakdownScreenState();
}

class _NetWorthBreakdownScreenState extends State<NetWorthBreakdownScreen> {
  double _effectiveInvestmentValue(dynamic investment) {
    final marketValue = investment.getCurrentValue();
    final investedCost = investment.getTotalInvestmentValue();
    return (marketValue <= 0 && investedCost > 0) ? investedCost : marketValue;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Net Worth Breakdown'),
      ),
      body: Consumer4<PaymentAccountProvider, InvestmentProvider, LoanProvider,
          SettingsProvider>(
        builder: (context, accountProvider, investmentProvider, loanProvider,
            settings, _) {
          final accounts = accountProvider.activeAccounts
              .where((account) =>
                  !account.accountType.toLowerCase().contains('credit'))
              .toList();
          final investments = investmentProvider.investments;
          final loans = loanProvider.activeLoans;
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
          final totalLoans = loans.fold<double>(
            0,
            (sum, loan) => sum + loan.pendingAmount,
          );
          final totalNetWorth = totalAssets - totalLoans;

          final isNegative = totalNetWorth < 0;
          final assetShare = totalAssets + totalLoans > 0
              ? (totalAssets / (totalAssets + totalLoans))
              : 0.0;
          final loanShare = totalAssets + totalLoans > 0
              ? (totalLoans / (totalAssets + totalLoans))
              : 0.0;

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
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Net Worth',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                AppUtils.formatCurrency(
                                  totalNetWorth,
                                  currencySymbol: currencySymbol,
                                ),
                                style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: isNegative
                                      ? Colors.red.shade700
                                      : colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          if (isNegative) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 22,
                              color: Colors.red.shade700,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SizedBox(
                          height: 6,
                          child: Row(
                            children: [
                              Expanded(
                                flex:
                                    (assetShare * 1000).round().clamp(0, 1000),
                                child: Container(color: Colors.green.shade500),
                              ),
                              Expanded(
                                flex: (loanShare * 1000).round().clamp(0, 1000),
                                child: Container(color: Colors.red.shade500),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final assetsMetric = _MetricBox(
                            label: 'Assets',
                            value: AppUtils.formatCurrency(
                              totalAssets,
                              currencySymbol: currencySymbol,
                            ),
                            color: Colors.green.shade700,
                            icon: Icons.trending_up,
                          );

                          final loansMetric = _MetricBox(
                            label: 'Loans',
                            value: AppUtils.formatCurrency(
                              totalLoans,
                              currencySymbol: currencySymbol,
                            ),
                            color: Colors.red.shade700,
                            icon: Icons.account_balance,
                          );

                          if (constraints.maxWidth < 380) {
                            return Column(
                              children: [
                                assetsMetric,
                                const SizedBox(height: 6),
                                loansMetric,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: assetsMetric),
                              const SizedBox(width: 10),
                              Expanded(child: loansMetric),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
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
                      'Assets',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      AppUtils.formatCurrency(
                        totalAssets,
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Accounts',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
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
                            const SizedBox(height: 10),
                            Text(
                              'Investments',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
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
                      'Loans',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      AppUtils.formatCurrency(
                        totalLoans,
                        currencySymbol: currencySymbol,
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        child: Column(
                          children: [
                            if (loans.isEmpty)
                              const _EmptySection(message: 'No loans found')
                            else
                              ...loans.map((loan) {
                                return _DataRowItem(
                                  title: loan.lender,
                                  subtitle:
                                      '${loan.remainingMonths} months remaining',
                                  value: AppUtils.formatCurrency(
                                    loan.pendingAmount,
                                    currencySymbol: currencySymbol,
                                  ),
                                  valueColor: Colors.red.shade700,
                                );
                              }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MetricBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
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
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 20,
            width: double.infinity,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
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
