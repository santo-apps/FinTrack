import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/core/utils/custom_widgets.dart';
import 'package:fintrack/features/receivable/presentation/providers/receivable_provider.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';

class ReceivableOverviewScreen extends StatefulWidget {
  const ReceivableOverviewScreen({super.key});

  @override
  State<ReceivableOverviewScreen> createState() =>
      _ReceivableOverviewScreenState();
}

class _ReceivableOverviewScreenState extends State<ReceivableOverviewScreen> {
  bool _showAllMonths = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receivable Overview'),
      ),
      body: Consumer2<ReceivableProvider, SettingsProvider>(
        builder: (context, provider, settings, _) {
          final pendingCount = provider.getOverallPendingCount();
          final receivedCount = provider.getOverallReceivedCount();
          final pendingTotal = provider.getOverallPendingTotal();
          final receivedTotal = provider.getOverallReceivedTotal();
          final overallTotal = pendingTotal + receivedTotal;
          final collectionRate = overallTotal == 0
              ? 0.0
              : (((receivedTotal / overallTotal) * 100).clamp(0, 100))
                  .toDouble();

          final monthly = <String, _MonthlySummary>{};
          for (final item in provider.receivables) {
            final key =
                '${item.dueDate.year}-${item.dueDate.month.toString().padLeft(2, '0')}';
            final value = monthly.putIfAbsent(key, () => _MonthlySummary());
            if (item.receivedAmount > 0) {
              value.receivedCount += 1;
              value.receivedTotal += item.receivedAmount;
            }
            if (item.outstandingAmount > 0) {
              value.pendingCount += 1;
              value.pendingTotal += item.outstandingAmount;
            }
          }

          final now = DateTime.now();
          final currentMonth = DateTime(now.year, now.month);
          final keys = monthly.keys.toList()
            ..sort((a, b) {
              final aParts = a.split('-');
              final bParts = b.split('-');
              final aMonth = aParts.length == 2
                  ? DateTime(int.parse(aParts[0]), int.parse(aParts[1]))
                  : DateTime(1970);
              final bMonth = bParts.length == 2
                  ? DateTime(int.parse(bParts[0]), int.parse(bParts[1]))
                  : DateTime(1970);

              final aIsFuture = aMonth.isAfter(currentMonth);
              final bIsFuture = bMonth.isAfter(currentMonth);

              if (aIsFuture != bIsFuture) {
                return aIsFuture ? 1 : -1;
              }

              if (aIsFuture) {
                return aMonth.compareTo(bMonth);
              }

              return bMonth.compareTo(aMonth);
            });

          final visibleMonthKeys =
              _showAllMonths ? keys : keys.take(6).toList();

          return ListView(
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, contentBottomPadding(context, hasFab: false)),
            children: [
              _TopSummaryCard(
                currencySymbol: settings.currencySymbol,
                pendingCount: pendingCount,
                receivedCount: receivedCount,
                pendingTotal: pendingTotal,
                receivedTotal: receivedTotal,
                collectionRate: collectionRate,
              ),
              const SizedBox(height: 14),
              _SectionHeader(
                title: 'Monthly Trend',
                subtitle: 'Pending and received receivables by month',
                icon: Icons.calendar_month,
              ),
              const SizedBox(height: 8),
              if (keys.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      'No receivable data available yet.',
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                )
              else
                ...visibleMonthKeys.map((key) {
                  final summary = monthly[key]!;
                  final monthTotal =
                      summary.pendingTotal + summary.receivedTotal;
                  final monthRate = monthTotal == 0
                      ? 0.0
                      : (((summary.receivedTotal / monthTotal) * 100)
                              .clamp(0, 100))
                          .toDouble();
                  return _MonthlyCard(
                    title: _formatMonthLabel(key),
                    pendingCount: summary.pendingCount,
                    receivedCount: summary.receivedCount,
                    pendingTotal: summary.pendingTotal,
                    receivedTotal: summary.receivedTotal,
                    collectionRate: monthRate,
                    currencySymbol: settings.currencySymbol,
                  );
                }),
              if (keys.length > 6) ...[
                const SizedBox(height: 4),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showAllMonths = !_showAllMonths;
                      });
                    },
                    icon: Icon(
                        _showAllMonths ? Icons.expand_less : Icons.expand_more),
                    label: Text(_showAllMonths
                        ? 'Show less'
                        : 'Show all months (${keys.length})'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _formatMonthLabel(String yearMonth) {
    final parts = yearMonth.split('-');
    if (parts.length != 2) return yearMonth;

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null || month < 1 || month > 12) {
      return yearMonth;
    }

    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${monthNames[month - 1]} $year';
  }
}

class _TopSummaryCard extends StatelessWidget {
  final String currencySymbol;
  final int pendingCount;
  final int receivedCount;
  final double pendingTotal;
  final double receivedTotal;
  final double collectionRate;

  const _TopSummaryCard({
    required this.currencySymbol,
    required this.pendingCount,
    required this.receivedCount,
    required this.pendingTotal,
    required this.receivedTotal,
    required this.collectionRate,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Theme.of(context).colorScheme.primary,
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.75),
      ],
    );

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(gradient: gradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overall Receivables',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$currencySymbol ${(pendingTotal + receivedTotal).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Collection Rate ${collectionRate.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: (collectionRate / 100).clamp(0, 1),
                      backgroundColor: Colors.white.withValues(alpha: 0.28),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: _Metric(
                      label: 'Pending',
                      count: pendingCount,
                      amount: pendingTotal,
                      currencySymbol: currencySymbol,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  Expanded(
                    child: _Metric(
                      label: 'Received',
                      count: receivedCount,
                      amount: receivedTotal,
                      currencySymbol: currencySymbol,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon,
              color: Theme.of(context).colorScheme.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthlyCard extends StatelessWidget {
  final String title;
  final int pendingCount;
  final int receivedCount;
  final double pendingTotal;
  final double receivedTotal;
  final double collectionRate;
  final String currencySymbol;

  const _MonthlyCard({
    required this.title,
    required this.pendingCount,
    required this.receivedCount,
    required this.pendingTotal,
    required this.receivedTotal,
    required this.collectionRate,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  '${collectionRate.toStringAsFixed(0)}% collected',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                minHeight: 7,
                value: (collectionRate / 100).clamp(0, 1),
                backgroundColor: Colors.orange.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Pending',
                    count: pendingCount,
                    amount: pendingTotal,
                    currencySymbol: currencySymbol,
                    color: Colors.orange.shade700,
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Received',
                    count: receivedCount,
                    amount: receivedTotal,
                    currencySymbol: currencySymbol,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final int count;
  final double amount;
  final String currencySymbol;
  final Color? color;

  const _Metric({
    required this.label,
    required this.count,
    required this.amount,
    required this.currencySymbol,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('$count item${count == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 12,
              color: color,
            )),
        const SizedBox(height: 2),
        Text('$currencySymbol ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            )),
      ],
    );
  }
}

class _MonthlySummary {
  int pendingCount = 0;
  int receivedCount = 0;
  double pendingTotal = 0;
  double receivedTotal = 0;
}
