import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/core/utils/custom_widgets.dart';
import 'package:fintrack/features/accounts/presentation/providers/payment_account_provider.dart';
import 'package:fintrack/features/expense/presentation/providers/expense_provider.dart';
import 'package:fintrack/features/receivable/data/models/receivable_model.dart';
import 'package:fintrack/features/receivable/presentation/providers/receivable_provider.dart';
import 'package:fintrack/features/receivable/presentation/pages/receivable_overview_screen.dart';
import 'package:fintrack/features/receivable/presentation/widgets/add_edit_receivable_dialog.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';

class ReceivableListScreen extends StatefulWidget {
  final bool showAppBar;
  final bool showBackButton;

  const ReceivableListScreen({
    super.key,
    this.showAppBar = true,
    this.showBackButton = false,
  });

  @override
  State<ReceivableListScreen> createState() => _ReceivableListScreenState();
}

class _ReceivableListScreenState extends State<ReceivableListScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _selectedMonth;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ReceivableProvider>().refreshData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openAddEditDialog({Receivable? receivable}) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddEditReceivableDialog(receivable: receivable),
    );
  }

  Future<void> _confirmDelete(Receivable receivable) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete receivable?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600),
                child:
                    const Text('Delete', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return;
    if (!mounted) return;
    await context.read<ReceivableProvider>().deleteReceivable(receivable.id);
  }

  Future<void> _markAsReceived(Receivable item) async {
    await context.read<ReceivableProvider>().markAsReceived(item);
    if (!mounted) return;
    await context.read<ExpenseProvider>().refreshData();
    if (!mounted) return;
    context.read<PaymentAccountProvider>().refreshData();
  }

  Future<void> _markAsPending(Receivable item) async {
    await context.read<ReceivableProvider>().markAsPending(item);
    if (!mounted) return;
    await context.read<ExpenseProvider>().refreshData();
    if (!mounted) return;
    context.read<PaymentAccountProvider>().refreshData();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: widget.showAppBar
          ? CustomAppBar(
              title: 'Receivables',
              showBackButton: widget.showBackButton,
              actions: [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ReceivableOverviewScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bar_chart_rounded),
                  tooltip: 'Receivable Overview',
                ),
              ],
            )
          : null,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(() {
                      _selectedMonth = DateTime(
                          _selectedMonth.year, _selectedMonth.month - 1, 1);
                    }),
                  ),
                  Text(
                    _formatMonth(_selectedMonth),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => setState(() {
                      _selectedMonth = DateTime(
                          _selectedMonth.year, _selectedMonth.month + 1, 1);
                    }),
                  ),
                ],
              ),
            ),
            Container(
              color: Theme.of(context).colorScheme.surface,
              child: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: 'Pending'),
                  Tab(text: 'Received'),
                ],
              ),
            ),
            Expanded(
              child: Consumer<ReceivableProvider>(
                builder: (context, provider, _) {
                  final pending = provider.getPendingForMonth(_selectedMonth);
                  final received = provider.getReceivedForMonth(_selectedMonth);
                  final pendingTotal =
                      provider.getPendingTotalForMonth(_selectedMonth);
                  final overdueCount =
                      pending.where((item) => item.isOverdue).length;

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(
                        context,
                        items: pending,
                        emptyMessage: 'No pending receivables',
                        currencySymbol: settings.currencySymbol,
                        summaryCard: _buildPendingSummaryCard(
                          pendingCount: pending.length,
                          pendingTotal: pendingTotal,
                          overdueCount: overdueCount,
                          currencySymbol: settings.currencySymbol,
                        ),
                      ),
                      _buildList(
                        context,
                        items: received,
                        emptyMessage: 'No received entries',
                        currencySymbol: settings.currencySymbol,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _tabController.index == 0
          ? AdaptiveBottomFab(
              child: FloatingActionButton(
                mini: true,
                heroTag: 'receivable_pending_add_fab',
                onPressed: () => _openAddEditDialog(),
                tooltip: 'Add Receivable',
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                child: const Icon(Icons.add),
              ),
            )
          : null,
    );
  }

  Widget _buildList(
    BuildContext context, {
    required List<Receivable> items,
    required String emptyMessage,
    required String currencySymbol,
    Widget? summaryCard,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 16, 16, contentBottomPadding(context)),
      itemCount: items.length + (summaryCard == null ? 0 : 1),
      itemBuilder: (context, index) {
        if (summaryCard != null && index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: summaryCard,
          );
        }

        final item = items[summaryCard == null ? index : index - 1];
        final isOverdue = item.isOverdue;
        final isReminder = item.isInReminderWindow;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: item.isReceived
                            ? Colors.green.shade100
                            : isOverdue
                                ? Colors.red.shade100
                                : isReminder
                                    ? Colors.orange.shade100
                                    : Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.isReceived
                            ? 'RECEIVED'
                            : isOverdue
                                ? 'OVERDUE'
                                : isReminder
                                    ? 'REMINDER'
                                    : 'PENDING',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: item.isReceived
                              ? Colors.green.shade800
                              : isOverdue
                                  ? Colors.red.shade800
                                  : isReminder
                                      ? Colors.orange.shade800
                                      : Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$currencySymbol ${item.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Date: ${item.dueDate.day.toString().padLeft(2, '0')}/${item.dueDate.month.toString().padLeft(2, '0')}/${item.dueDate.year} • Reminder: ${item.remindBeforeDays} day(s) before',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.notes!,
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openAddEditDialog(receivable: item),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit', maxLines: 1, softWrap: false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDelete(item),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label:
                            const Text('Delete', maxLines: 1, softWrap: false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade300),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: item.isReceived
                      ? OutlinedButton.icon(
                          onPressed: () => _markAsPending(item),
                          icon: const Icon(Icons.restore, size: 16),
                          label: const Text('Move to Pending'),
                        )
                      : ElevatedButton.icon(
                          onPressed: () => _markAsReceived(item),
                          icon:
                              const Icon(Icons.check_circle_outline, size: 16),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          label: const Text('Mark Received'),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPendingSummaryCard({
    required int pendingCount,
    required int overdueCount,
    required double pendingTotal,
    required String currencySymbol,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: _summaryTile('Pending', '$pendingCount'),
            ),
            Expanded(
              child: _summaryTile('Overdue', '$overdueCount'),
            ),
            Expanded(
              child: _summaryTile(
                'Amount',
                '$currencySymbol ${pendingTotal.toStringAsFixed(2)}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  String _formatMonth(DateTime date) {
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
    return '${monthNames[date.month - 1]} ${date.year}';
  }
}
