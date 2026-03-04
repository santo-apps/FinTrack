import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/core/constants/app_constants.dart';
import 'package:fintrack/core/theme/app_theme.dart';
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
  bool _assetsExpanded = false;
  bool _loansExpanded = false;

  double _effectiveInvestmentValue(dynamic investment) {
    final marketValue = investment.getCurrentValue();
    final investedCost = investment.getTotalInvestmentValue();
    return (marketValue <= 0 && investedCost > 0) ? investedCost : marketValue;
  }

  @override
  Widget build(BuildContext context) {
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Net Worth Summary Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Net Worth',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppUtils.formatCurrency(
                              totalNetWorth,
                              currencySymbol: currencySymbol,
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: isNegative
                                  ? Colors.red.shade700
                                  : AppTheme.primaryColor,
                            ),
                          ),
                          if (isNegative) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 24,
                              color: Colors.red.shade700,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricBox(
                              label: 'Total Assets',
                              value: AppUtils.formatCurrency(
                                totalAssets,
                                currencySymbol: currencySymbol,
                              ),
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MetricBox(
                              label: 'Total Loans',
                              value: AppUtils.formatCurrency(
                                totalLoans,
                                currencySymbol: currencySymbol,
                              ),
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Assets Section
              Card(
                elevation: _assetsExpanded ? 6 : 2,
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
                        _assetsExpanded = expanded;
                      });
                    },
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
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Accounts subsection
                            Text(
                              'Accounts',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (accounts.isEmpty)
                              _EmptySection(message: 'No asset accounts found')
                            else
                              ...accounts.map((account) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              account.name,
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              account.accountType,
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
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
                                    ],
                                  ),
                                );
                              }),
                            const SizedBox(height: 16),
                            Divider(color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'Investments',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (investments.isEmpty)
                              _EmptySection(message: 'No investments found')
                            else
                              ...investments.map((investment) {
                                final effectiveValue =
                                    _effectiveInvestmentValue(investment);
                                final invested =
                                    investment.getTotalInvestmentValue();
                                final gain = effectiveValue - invested;
                                final gainPercent =
                                    invested > 0 ? (gain / invested) * 100 : 0;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              investment.name,
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              '${investment.type} • Gain/Loss: ${AppUtils.formatCurrency(gain, currencySymbol: currencySymbol)} (${gainPercent.toStringAsFixed(1)}%)',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        AppUtils.formatCurrency(
                                          effectiveValue,
                                          currencySymbol: currencySymbol,
                                        ),
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
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

              // Loans Section
              Card(
                elevation: _loansExpanded ? 6 : 2,
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
                        _loansExpanded = expanded;
                      });
                    },
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
                      if (loans.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _EmptySection(message: 'No loans found'),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              ...loans.map((loan) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              loan.lender,
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              '${loan.remainingMonths} months remaining',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        AppUtils.formatCurrency(
                                          loan.pendingAmount,
                                          currencySymbol: currencySymbol,
                                        ),
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.red.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
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

  const _MetricBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color.withOpacity(0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
