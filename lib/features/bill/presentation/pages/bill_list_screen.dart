import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:fintrack/core/utils/custom_widgets.dart';
import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/database/hive_service.dart';
import 'package:fintrack/features/bill/data/models/bill_model.dart';
import 'package:fintrack/features/bill/data/models/bill_reminder_model.dart';
import 'package:fintrack/features/bill/presentation/providers/bill_provider.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';
import 'package:fintrack/features/loan/data/models/loan_model.dart';
import 'package:fintrack/features/loan/presentation/providers/loan_provider.dart';
import 'package:fintrack/features/loan/presentation/widgets/add_edit_loan_dialog.dart';
import 'package:fintrack/features/expense/data/models/expense_model.dart';
import 'package:fintrack/features/expense/presentation/providers/expense_provider.dart';
import 'package:fintrack/features/accounts/data/models/payment_account_model.dart';
import 'package:fintrack/features/accounts/presentation/providers/payment_account_provider.dart';
import 'package:fintrack/features/accounts/presentation/pages/account_form_screen.dart';
import 'package:fintrack/features/subscription/data/models/subscription_model.dart';
import 'package:fintrack/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:fintrack/features/subscription/presentation/pages/subscription_list_screen.dart';

class BillListScreen extends StatefulWidget {
  final bool showAppBar;
  final bool showBackButton;

  const BillListScreen({
    super.key,
    this.showAppBar = true,
    this.showBackButton = false,
  });

  @override
  State<BillListScreen> createState() => _BillListScreenState();
}

class _BillListScreenState extends State<BillListScreen> {
  late DateTime _selectedMonth;
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  void _showPaymentSnackBar(
    String message, {
    SnackBarAction? action,
    Color? backgroundColor,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle()),
        action: action,
        duration: const Duration(seconds: 4),
        backgroundColor: backgroundColor,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    final provider = context.read<BillProvider>();
    Future.microtask(() {
      if (mounted) {
        provider.initBills();
        provider.setSelectedMonth(_selectedMonth);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _messengerKey,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: widget.showAppBar
              ? CustomAppBar(
                  title: 'Bill Reminders',
                  showBackButton: widget.showBackButton,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _showAddManualBillDialog(context),
                      tooltip: 'Add Manual Bill',
                    ),
                  ],
                )
              : null,
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                // Month Selector
                Container(
                  color: Theme.of(context).colorScheme.surface,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.chevron_left,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        onPressed: _previousMonth,
                        tooltip: 'Previous Month',
                      ),
                      InkWell(
                        onTap: _showMonthPicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Theme.of(context).dividerColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatMonth(_selectedMonth),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        onPressed: _nextMonth,
                        tooltip: 'Next Month',
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: TabBar(
                    labelColor: Theme.of(context).colorScheme.onSurface,
                    unselectedLabelColor:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    indicatorWeight: 3,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 12.0),
                    labelStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: const [
                      Tab(text: 'Pending'),
                      Tab(text: 'Overdue'),
                      Tab(text: 'Completed'),
                    ],
                  ),
                ),
                Expanded(
                  child: Consumer<BillProvider>(
                    builder: (context, billProvider, _) {
                      final overdueReminders = billProvider
                          .getRemindersForMonth(_selectedMonth)
                          .where((r) => r.status == BillReminderStatus.overdue)
                          .toList();
                      final pendingReminders = billProvider
                          .getRemindersForMonth(_selectedMonth)
                          .where((r) =>
                              r.status == BillReminderStatus.pending ||
                              r.status == BillReminderStatus.partiallyPaid)
                          .toList();
                      final completedReminders = billProvider
                          .getRemindersForMonth(_selectedMonth)
                          .where(
                              (r) => r.status == BillReminderStatus.completed)
                          .toList();

                      return TabBarView(
                        children: [
                          _buildRemindersList(
                              pendingReminders, 'No pending bills'),
                          _buildRemindersList(
                              overdueReminders, 'No overdue bills'),
                          _buildRemindersList(
                              completedReminders, 'No completed bills'),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: AdaptiveBottomFab(
            child: FloatingActionButton(
              mini: true,
              heroTag: 'bill_list_fab_add',
              onPressed: () => _showAddManualBillDialog(context),
              tooltip: 'Add Manual Bill',
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRemindersList(
      List<BillReminder> reminders, String emptyMessage) {
    if (reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(emptyMessage,
                style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<BillProvider>(context, listen: false).refreshData();
      },
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          contentBottomPadding(context),
        ),
        itemCount: reminders.length + 1, // +1 for summary section
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildSummarySection(reminders);
          }
          return _buildReminderCard(reminders[index - 1]);
        },
      ),
    );
  }

  Widget _buildSummarySection(List<BillReminder> reminders) {
    // Calculate breakdowns by type
    final subscriptions = reminders
        .where((r) => r.type == BillReminderType.subscription)
        .toList();
    final creditCards =
        reminders.where((r) => r.type == BillReminderType.creditCard).toList();
    final loans =
        reminders.where((r) => r.type == BillReminderType.loan).toList();
    final bills =
        reminders.where((r) => r.type == BillReminderType.bill).toList();

    final subscriptionTotal =
        subscriptions.fold(0.0, (sum, r) => sum + r.amount);
    final creditCardTotal = creditCards.fold(0.0, (sum, r) => sum + r.amount);
    final loanTotal = loans.fold(0.0, (sum, r) => sum + r.amount);
    final billTotal = bills.fold(0.0, (sum, r) => sum + r.amount);
    final grandTotal =
        subscriptionTotal + creditCardTotal + loanTotal + billTotal;

    final currency = reminders.isNotEmpty ? reminders.first.currency : 'USD';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  '$currency ${grandTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (subscriptions.isNotEmpty)
              _buildSummaryRow(
                'Subscriptions',
                subscriptions.length,
                subscriptionTotal,
                currency,
                Icons.subscriptions,
                AppTheme.primaryColor,
              ),
            if (creditCards.isNotEmpty)
              _buildSummaryRow(
                'Credit Cards',
                creditCards.length,
                creditCardTotal,
                currency,
                Icons.credit_card,
                Colors.blue,
              ),
            if (loans.isNotEmpty)
              _buildSummaryRow(
                'Loans',
                loans.length,
                loanTotal,
                currency,
                Icons.account_balance,
                Colors.orange,
              ),
            if (bills.isNotEmpty)
              _buildSummaryRow(
                'Bills',
                bills.length,
                billTotal,
                currency,
                Icons.receipt_long,
                Colors.green,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    int count,
    double amount,
    String currency,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  '$count item${count > 1 ? "s" : ""}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$currency ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(BillReminder reminder) {
    final isOverdue = reminder.status == BillReminderStatus.overdue;
    final isPending = reminder.status == BillReminderStatus.pending;
    final isPaid = reminder.status == BillReminderStatus.completed;
    final isPartiallyPaid = reminder.status == BillReminderStatus.partiallyPaid;
    final daysUntilDue = reminder.getDaysUntilDue();
    final dueStatusText = daysUntilDue == 0
        ? 'Due today'
        : daysUntilDue == 1
            ? 'Due in 1 day'
            : 'Due in $daysUntilDue days';

    if (isPending) {
      final dueDay = DateTime(
        reminder.dueDate.year,
        reminder.dueDate.month,
        reminder.dueDate.day,
      );
      final today = DateTime.now();
      final todayDay = DateTime(today.year, today.month, today.day);
      assert(() {
        debugPrint(
          '🧪 DueDateCheck | ${reminder.name} | raw=${reminder.dueDate.toIso8601String()} | '
          'dueDay=${dueDay.toIso8601String()} | today=${todayDay.toIso8601String()} | '
          'daysUntilDue=$daysUntilDue | label=$dueStatusText',
        );
        return true;
      }());
    }

    // Badge color and text based on status
    Color badgeBg;
    Color badgeFg;
    if (isPaid) {
      badgeBg = Colors.green.shade100;
      badgeFg = Colors.green.shade700;
    } else if (isOverdue) {
      badgeBg = Colors.red.shade100;
      badgeFg = Colors.red.shade700;
    } else if (isPartiallyPaid) {
      badgeBg = Colors.amber.shade100;
      badgeFg = Colors.amber.shade800;
    } else {
      badgeBg = Colors.orange.shade100;
      badgeFg = Colors.orange.shade700;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: () => _showReminderDetails(reminder),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reminder.getTypeLabel(),
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      reminder.getStatusLabel(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: badgeFg,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${reminder.currency} ${reminder.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatDate(reminder.dueDate),
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if ((isPending || isPartiallyPaid) && daysUntilDue >= 0)
                        Text(
                          dueStatusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: daysUntilDue == 0
                                ? Colors.red.shade600
                                : daysUntilDue <= 3
                                    ? Colors.orange.shade600
                                    : Colors.blue.shade600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              // Partial payment progress
              if (isPartiallyPaid) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Paid: ${reminder.currency} ${reminder.paidAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.amber.shade900,
                        ),
                      ),
                      Text(
                        'Remaining: ${reminder.currency} ${(reminder.amount - reminder.paidAmount).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (!isPaid) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showEditReminderDialog(reminder),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text(
                          'Edit',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDeleteSourceReminder(reminder),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text(
                          'Delete',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          style: TextStyle(fontSize: 13),
                        ),
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
                  child: ElevatedButton.icon(
                    onPressed: () => _handleMarkAsPaid(reminder),
                    icon: const Icon(Icons.payment, size: 16),
                    label: Text(
                      isPartiallyPaid ? 'Pay Remaining' : 'Pay Now',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                      style: const TextStyle(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _editCompletedReminderAccount(reminder),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text(
                          'Edit Bank',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13.5),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _confirmDeleteCompletedReminder(reminder),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text(
                          'Delete',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          style: TextStyle(),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade300),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleMarkAsPaid(BillReminder reminder) {
    switch (reminder.type) {
      case BillReminderType.bill:
        _markBillPaid(reminder);
        break;
      case BillReminderType.loan:
        _markLoanPaid(reminder);
        break;
      case BillReminderType.creditCard:
        _markCreditCardPaid(reminder);
        break;
      case BillReminderType.subscription:
        _markSubscriptionPaid(reminder);
        break;
    }
  }

  Future<void> _editCompletedReminderAccount(BillReminder reminder) async {
    if (reminder.status != BillReminderStatus.completed) return;

    final accounts = HiveService.getAllPaymentAccounts();
    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please add an account first',
            style: TextStyle(),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (reminder.type == BillReminderType.bill ||
        reminder.type == BillReminderType.subscription) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Account mapping is not stored for this reminder type. Use Delete to move it back to Pending and mark as paid again.',
              style: TextStyle(),
            ),
          ),
        );
      }
      return;
    }

    String? selectedAccountId;
    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Update Bank Account',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedAccountId,
                  items: accounts
                      .map(
                        (account) => DropdownMenuItem<String>(
                          value: account.id,
                          child: SizedBox(
                            width: 250,
                            child: Text(
                              '${account.name} (${account.currency} ${account.balance.toStringAsFixed(2)})',
                              style: TextStyle(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setModalState(() {
                      selectedAccountId = value;
                    });
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  hint: Text(
                    'Select account',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: selectedAccountId == null
                      ? null
                      : () async {
                          final loanProvider = context.read<LoanProvider>();
                          final paymentAccountProvider =
                              context.read<PaymentAccountProvider>();
                          final billProvider = context.read<BillProvider>();
                          final messenger = ScaffoldMessenger.of(context);

                          final selectedAccount = accounts
                              .firstWhere((a) => a.id == selectedAccountId);

                          if (reminder.type == BillReminderType.loan) {
                            final loans = HiveService.getAllLoans();
                            final loan = loans.firstWhere(
                              (l) => l.id == reminder.sourceId,
                            );
                            final updatedLoan =
                                loan.copyWith(accountId: selectedAccount.id);
                            await loanProvider.updateLoan(updatedLoan);
                          } else if (reminder.type ==
                              BillReminderType.creditCard) {
                            final cards = HiveService.getAllPaymentAccounts();
                            final card = cards.firstWhere(
                              (a) => a.id == reminder.sourceId,
                            );
                            final updatedCard = card.copyWith(
                                linkedAccountId: selectedAccount.id);
                            await paymentAccountProvider
                                .updateAccount(updatedCard);
                          }

                          if (!mounted) return;
                          if (!context.mounted) return;
                          {
                            Navigator.pop(context);
                            await billProvider.refreshData();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Bank account updated',
                                  style: TextStyle(),
                                ),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Save Changes',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteCompletedReminder(BillReminder reminder) async {
    if (reminder.status != BillReminderStatus.completed) return;

    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Delete Completed Entry?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            content: Text(
              'This will move the entry back to Pending to avoid accidental updates.',
              style: TextStyle(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: TextStyle()),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                ),
                child: Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return;

    await _moveCompletedReminderToPending(reminder);
  }

  Future<void> _moveCompletedReminderToPending(BillReminder reminder) async {
    final billProvider = context.read<BillProvider>();
    final loanProvider = context.read<LoanProvider>();
    final subscriptionProvider = context.read<SubscriptionProvider>();
    final expenseProvider = context.read<ExpenseProvider>();
    final paymentAccountProvider = context.read<PaymentAccountProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      switch (reminder.type) {
        case BillReminderType.bill:
          final bills = HiveService.getAllBills();
          final bill = bills.firstWhere((b) => b.id == reminder.sourceId);
          final reversedAmount = await _reverseRecordedPayments(
            candidates: HiveService.getAllExpenses().where((expense) {
              final type = expense.transactionType ?? 'expense';
              final inMonth = expense.date.year == reminder.dueDate.year &&
                  expense.date.month == reminder.dueDate.month;
              return type == 'payment' &&
                  expense.title.contains('Bill Payment - ${bill.name}') &&
                  inMonth;
            }).toList(),
            amountToReverse:
                reminder.paidAmount > 0 ? reminder.paidAmount : bill.paidAmount,
            expenseProvider: expenseProvider,
            paymentAccountProvider: paymentAccountProvider,
          );

          final updatedBill = bill.copyWith(
            isPaid: false,
            paidDate: null,
            paidAmount: (bill.paidAmount - reversedAmount)
                .clamp(0.0, double.infinity)
                .toDouble(),
          );
          await billProvider.updateBill(updatedBill);
          break;
        case BillReminderType.loan:
          final loans = HiveService.getAllLoans();
          final loan = loans.firstWhere((l) => l.id == reminder.sourceId);

          final reversedAmount = await _reverseRecordedPayments(
            candidates: HiveService.getAllExpenses().where((expense) {
              final type = expense.transactionType ?? 'expense';
              final inMonth = expense.date.year == reminder.dueDate.year &&
                  expense.date.month == reminder.dueDate.month;
              return (type == 'payment' || type == 'transfer') &&
                  expense.title.contains('Loan EMI Payment - ${loan.lender}') &&
                  inMonth;
            }).toList(),
            amountToReverse:
                reminder.paidAmount > 0 ? reminder.paidAmount : loan.monthlyEmi,
            expenseProvider: expenseProvider,
            paymentAccountProvider: paymentAccountProvider,
          );

          final updatedLoan = loan.copyWith(
            paidAmount: (loan.paidAmount - reversedAmount).clamp(
              0.0,
              loan.borrowedAmount,
            ),
            lastPaymentDate: null,
          );
          await loanProvider.updateLoan(updatedLoan);
          await loanProvider.refreshData();
          break;
        case BillReminderType.creditCard:
          await _reopenCreditCardReminder(reminder);
          break;
        case BillReminderType.subscription:
          final subscriptions = HiveService.getAllSubscriptions();
          final subscription = subscriptions.firstWhere(
            (s) => s.id == reminder.sourceId,
          );

          await _reverseRecordedPayments(
            candidates: HiveService.getAllExpenses().where((expense) {
              final type = expense.transactionType ?? 'expense';
              final inMonth = expense.date.year == reminder.dueDate.year &&
                  expense.date.month == reminder.dueDate.month;
              return (type == 'payment' ||
                      type == 'transfer' ||
                      type == 'expense') &&
                  expense.title.contains(
                      'Subscription Payment - ${subscription.name}') &&
                  inMonth;
            }).toList(),
            amountToReverse: reminder.paidAmount > 0
                ? reminder.paidAmount
                : subscription.cost,
            expenseProvider: expenseProvider,
            paymentAccountProvider: paymentAccountProvider,
          );

          // Refresh subscription provider to ensure UI updates
          await subscriptionProvider.refreshData();
          break;
      }

      if (!mounted) return;
      if (context.mounted) {
        // Refresh bill provider to update the reminder list
        await billProvider.refreshData();

        // Force a rebuild by setting state if needed
        setState(() {});

        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Entry moved to pending',
              style: TextStyle(),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update entry: $e',
            style: TextStyle(),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<double> _reverseRecordedPayments({
    required List<Expense> candidates,
    required double amountToReverse,
    required ExpenseProvider expenseProvider,
    required PaymentAccountProvider paymentAccountProvider,
  }) async {
    if (amountToReverse <= 0) {
      return 0.0;
    }

    final sortedCandidates = [...candidates]
      ..sort((a, b) => b.date.compareTo(a.date));

    var remaining = amountToReverse;
    var reversedTotal = 0.0;
    final sourceAccountRefunds = <String, double>{};

    for (final payment in sortedCandidates) {
      if (remaining <= 0) break;

      final reversalAmount =
          payment.amount <= remaining ? payment.amount : remaining;

      if (payment.amount <= remaining + 0.0001) {
        await expenseProvider.deleteExpense(payment.id);
      } else {
        await expenseProvider.updateExpense(
          payment.copyWith(amount: payment.amount - reversalAmount),
        );
      }

      if (payment.accountId != null && payment.accountId!.isNotEmpty) {
        sourceAccountRefunds[payment.accountId!] =
            (sourceAccountRefunds[payment.accountId!] ?? 0) + reversalAmount;
      }

      reversedTotal += reversalAmount;
      remaining -= reversalAmount;
    }

    for (final entry in sourceAccountRefunds.entries) {
      final sourceAccount = HiveService.getAllPaymentAccounts().firstWhere(
        (account) => account.id == entry.key,
        orElse: () => throw Exception('Source payment account not found'),
      );

      await paymentAccountProvider.updateAccount(
        sourceAccount.copyWith(balance: sourceAccount.balance + entry.value),
      );
    }

    return reversedTotal;
  }

  Future<void> _reopenCreditCardReminder(BillReminder reminder) async {
    final paymentAccountProvider = context.read<PaymentAccountProvider>();
    final expenseProvider = context.read<ExpenseProvider>();
    final billProvider = context.read<BillProvider>();

    final creditCards = HiveService.getAllPaymentAccounts();
    final expenses = HiveService.getAllExpenses();
    final creditCard = creditCards.firstWhere((a) => a.id == reminder.sourceId,
        orElse: () => throw Exception('Credit card account not found'));

    final monthStart =
        DateTime(reminder.dueDate.year, reminder.dueDate.month, 1);
    final monthEnd = DateTime(
        reminder.dueDate.year, reminder.dueDate.month + 1, 0, 23, 59, 59, 999);

    final paymentCandidates = expenses.where((expense) {
      final type = expense.transactionType ?? 'expense';
      final isPaymentLike = type == 'transfer' || type == 'payment';
      final matchesCard = expense.destinationAccountId == creditCard.id ||
          expense.title
              .contains('Credit Card Payment - ${reminder.accountName}');
      final inMonth =
          !expense.date.isBefore(monthStart) && !expense.date.isAfter(monthEnd);
      return isPaymentLike && matchesCard && inMonth;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    var amountToReopen =
        (reminder.paidAmount > 0 ? reminder.paidAmount : reminder.amount)
            .clamp(0.0, double.infinity)
            .toDouble();

    final accountRecredits = <String, double>{};
    var cardBalanceDelta = 0.0;

    for (final payment in paymentCandidates) {
      if (amountToReopen <= 0) break;

      final removableAmount =
          payment.amount <= amountToReopen ? payment.amount : amountToReopen;

      if (payment.amount <= amountToReopen + 0.0001) {
        await expenseProvider.deleteExpense(payment.id);
      } else {
        await expenseProvider.updateExpense(
          payment.copyWith(amount: payment.amount - removableAmount),
        );
      }

      if (payment.accountId != null && payment.accountId!.isNotEmpty) {
        accountRecredits[payment.accountId!] =
            (accountRecredits[payment.accountId!] ?? 0) + removableAmount;
      }

      cardBalanceDelta += removableAmount;
      amountToReopen -= removableAmount;
    }

    for (final entry in accountRecredits.entries) {
      final account = HiveService.getAllPaymentAccounts().firstWhere(
        (a) => a.id == entry.key,
        orElse: () => throw Exception('Source payment account not found'),
      );
      await paymentAccountProvider.updateAccount(
          account.copyWith(balance: account.balance + entry.value));
    }

    await paymentAccountProvider.updateAccount(
      creditCard.copyWith(balance: creditCard.balance + cardBalanceDelta),
    );

    await billProvider.refreshData();
  }

  void _markBillPaid(BillReminder reminder) {
    final accounts = HiveService.getAllPaymentAccounts();

    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please add an account first',
            style: TextStyle(),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final bills = HiveService.getAllBills();
    final bill = bills.firstWhere((b) => b.id == reminder.sourceId);
    final remainingAmount = bill.remainingAmount();

    final accountTypes =
        <String>{...accounts.map((a) => a.accountType)}.toList()..sort();
    String? selectedType = accountTypes.isNotEmpty ? accountTypes.first : null;
    String? selectedAccountId;
    final amountController =
        TextEditingController(text: remainingAmount.toStringAsFixed(2));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final filteredByType = accountTypes.isEmpty
              ? []
              : accounts.where((a) => a.accountType == selectedType).toList();

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom +
                  effectiveBottomInset(context),
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pay Bill',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  // Payment amount field
                  Text(
                    'Payment Amount:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'Enter amount',
                      helperText:
                          'Total due: ${reminder.currency} ${reminder.amount.toStringAsFixed(2)}'
                          '${bill.paidAmount > 0 ? ' (already paid: ${reminder.currency} ${bill.paidAmount.toStringAsFixed(2)})' : ''}',
                      helperStyle:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    style: const TextStyle(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select Account Type:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    items: accountTypes
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type, style: TextStyle()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedType = value;
                        selectedAccountId = null;
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select Account:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (filteredByType.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'No accounts found',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: selectedAccountId,
                      items: filteredByType
                          .map((account) => DropdownMenuItem<String>(
                                value: account.id,
                                child: Text(
                                  '${account.name} (${account.currency} ${account.balance.toStringAsFixed(2)})',
                                  style: TextStyle(),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedAccountId = value;
                        });
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      hint: Text('Choose account',
                          style: TextStyle(fontSize: 13)),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text('Cancel', style: TextStyle()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: selectedAccountId == null
                              ? null
                              : () {
                                  final enteredAmount = double.tryParse(
                                      amountController.text.trim());
                                  if (enteredAmount == null ||
                                      enteredAmount <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Please enter a valid amount',
                                            style: TextStyle()),
                                        backgroundColor: AppTheme.errorColor,
                                      ),
                                    );
                                    return;
                                  }
                                  if (enteredAmount > remainingAmount) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Payment cannot exceed remaining due (${reminder.currency} ${remainingAmount.toStringAsFixed(2)})',
                                          style: TextStyle(),
                                        ),
                                        backgroundColor: AppTheme.errorColor,
                                      ),
                                    );
                                    return;
                                  }
                                  Navigator.pop(context);
                                  final selectedAccount = accounts.firstWhere(
                                      (a) => a.id == selectedAccountId);
                                  _processBillPayment(
                                      reminder, selectedAccount, enteredAmount);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            disabledBackgroundColor: Colors.grey.shade300,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Confirm Payment',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _processBillPayment(
    BillReminder reminder,
    PaymentAccount selectedAccount,
    double paymentAmount,
  ) async {
    final billProvider = context.read<BillProvider>();
    final expenseProvider = context.read<ExpenseProvider>();
    final paymentAccountProvider = context.read<PaymentAccountProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final bills = HiveService.getAllBills();
      final bill = bills.firstWhere((b) => b.id == reminder.sourceId);

      final newPaidAmount = bill.paidAmount + paymentAmount;
      final isFullyPaid = newPaidAmount >= bill.amount;

      final expenseId = const Uuid().v4();
      final expense = Expense(
        id: expenseId,
        title: 'Bill Payment - ${bill.name}',
        category: 'Bills & Utilities',
        amount: paymentAmount,
        date: DateTime.now(),
        currency: bill.currency,
        paymentMethod: 'Bank Transfer',
        accountId: selectedAccount.id,
        notes: 'Paid bill: ${bill.name}',
        transactionType: 'payment',
      );

      final updatedBill = bill.copyWith(
        isPaid: isFullyPaid,
        paidDate: isFullyPaid ? DateTime.now() : null,
        paidAmount: newPaidAmount,
      );

      // Check if payment account is a credit card
      final isCreditCard =
          selectedAccount.accountType.toLowerCase().contains('credit');
      final updatedAccount = selectedAccount.copyWith(
        balance: isCreditCard
            ? selectedAccount.balance +
                paymentAmount // Credit card: increase debt
            : selectedAccount.balance -
                paymentAmount, // Other: decrease balance
      );

      await billProvider.updateBill(updatedBill);
      await expenseProvider.addExpense(expense);
      await paymentAccountProvider.updateAccount(updatedAccount);
      await billProvider.refreshData();

      if (!mounted) return;
      _showPaymentSnackBar(
        isFullyPaid ? 'Bill marked as paid' : 'Partial payment recorded',
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _reverseBillPayment(
            bill,
            selectedAccount,
            expenseId,
            paymentAmount,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: TextStyle()),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _reverseBillPayment(
    Bill bill,
    PaymentAccount paymentAccount,
    String expenseId,
    double paymentAmount,
  ) async {
    final expenseProvider = context.read<ExpenseProvider>();
    final billProvider = context.read<BillProvider>();
    final paymentAccountProvider = context.read<PaymentAccountProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final revertedPaidAmount =
          (bill.paidAmount - paymentAmount).clamp(0.0, double.infinity);
      final revertedBill = bill.copyWith(
        isPaid: false,
        paidDate: null,
        paidAmount: revertedPaidAmount,
      );

      // Check if payment account is a credit card
      final isCreditCard =
          paymentAccount.accountType.toLowerCase().contains('credit');
      final restoredAccount = paymentAccount.copyWith(
        balance: isCreditCard
            ? paymentAccount.balance -
                paymentAmount // Credit card: decrease debt
            : paymentAccount.balance + paymentAmount, // Other: restore balance
      );

      await expenseProvider.deleteExpense(expenseId);
      await billProvider.updateBill(revertedBill);
      await paymentAccountProvider.updateAccount(restoredAccount);

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Bill payment reverted',
            style: TextStyle(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Error reverting payment: $e',
            style: TextStyle(),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _markLoanPaid(BillReminder reminder) {
    final accounts = HiveService.getAllPaymentAccounts();

    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please add an account first',
            style: TextStyle(),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final accountTypes =
        <String>{...accounts.map((a) => a.accountType)}.toList()..sort();
    String? selectedType = accountTypes.isNotEmpty ? accountTypes.first : null;
    String? selectedAccountId;
    final remainingAmount = (reminder.amount - reminder.paidAmount)
        .clamp(0.0, reminder.amount)
        .toDouble();
    final payableAmount =
        remainingAmount > 0 ? remainingAmount : reminder.amount;
    final amountController =
        TextEditingController(text: payableAmount.toStringAsFixed(2));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final filteredByType = accountTypes.isEmpty
              ? []
              : accounts.where((a) => a.accountType == selectedType).toList();

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom +
                  effectiveBottomInset(context),
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Record Loan EMI Payment',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  // Payment amount field
                  Text(
                    'Payment Amount:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'Enter amount',
                      helperText:
                          'Remaining due: ${reminder.currency} ${payableAmount.toStringAsFixed(2)}',
                      helperStyle:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    style: const TextStyle(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select Account Type:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    items: accountTypes
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type, style: TextStyle()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedType = value;
                        selectedAccountId = null;
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select Account:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (filteredByType.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'No accounts found',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: selectedAccountId,
                      items: filteredByType
                          .map((account) => DropdownMenuItem<String>(
                                value: account.id,
                                child: Text(
                                  '${account.name} (${account.currency} ${account.balance.toStringAsFixed(2)})',
                                  style: TextStyle(),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedAccountId = value;
                        });
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      hint: Text('Choose account',
                          style: TextStyle(fontSize: 13)),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text('Cancel', style: TextStyle()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: selectedAccountId == null
                              ? null
                              : () {
                                  final enteredAmount = double.tryParse(
                                      amountController.text.trim());
                                  if (enteredAmount == null ||
                                      enteredAmount <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Please enter a valid amount',
                                            style: TextStyle()),
                                        backgroundColor: AppTheme.errorColor,
                                      ),
                                    );
                                    return;
                                  }
                                  if (enteredAmount > payableAmount) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Payment cannot exceed remaining due (${reminder.currency} ${payableAmount.toStringAsFixed(2)})',
                                          style: TextStyle(),
                                        ),
                                        backgroundColor: AppTheme.errorColor,
                                      ),
                                    );
                                    return;
                                  }
                                  Navigator.pop(context);
                                  final selectedAccount = accounts.firstWhere(
                                      (a) => a.id == selectedAccountId);
                                  _processLoanPayment(
                                      reminder, selectedAccount, enteredAmount);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            disabledBackgroundColor: Colors.grey.shade300,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Confirm Payment',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _processLoanPayment(
    BillReminder reminder,
    PaymentAccount paymentAccount,
    double paymentAmount,
  ) async {
    final loanProvider = context.read<LoanProvider>();
    final expenseProvider = context.read<ExpenseProvider>();
    final paymentAccountProvider = context.read<PaymentAccountProvider>();
    final billProvider = context.read<BillProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final loans = HiveService.getAllLoans();
      final loan = loans.firstWhere((l) => l.id == reminder.sourceId);

      final expenseId = const Uuid().v4();
      final expense = Expense(
        id: expenseId,
        title: 'Loan EMI Payment - ${loan.lender}',
        category: 'Loan Repayment',
        amount: paymentAmount,
        date: DateTime.now(),
        currency: loan.currency,
        paymentMethod: 'Bank Transfer',
        accountId: paymentAccount.id,
        notes: 'EMI payment to ${loan.lender}',
        transactionType: 'payment',
      );

      // Check if payment account is a credit card
      final isCreditCard =
          paymentAccount.accountType.toLowerCase().contains('credit');
      final updatedPaymentAccount = paymentAccount.copyWith(
        balance: isCreditCard
            ? paymentAccount.balance +
                paymentAmount // Credit card: increase debt
            : paymentAccount.balance - paymentAmount, // Other: decrease balance
      );

      await loanProvider.makePayment(loan.id, paymentAmount);
      await expenseProvider.addExpense(expense);
      await paymentAccountProvider.updateAccount(updatedPaymentAccount);

      await billProvider.refreshData();
      if (!mounted) return;
      _showPaymentSnackBar(
        paymentAmount >= loan.monthlyEmi
            ? 'Loan EMI payment recorded'
            : 'Partial loan payment recorded',
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _reverseLoanPayment(
            loan,
            paymentAccount,
            expenseId,
            paymentAmount,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: TextStyle()),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _reverseLoanPayment(
    Loan loan,
    PaymentAccount paymentAccount,
    String expenseId,
    double paymentAmount,
  ) async {
    final expenseProvider = context.read<ExpenseProvider>();
    final loanProvider = context.read<LoanProvider>();
    final paymentAccountProvider = context.read<PaymentAccountProvider>();
    final billProvider = context.read<BillProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      // Check if payment account is a credit card
      final isCreditCard =
          paymentAccount.accountType.toLowerCase().contains('credit');
      final restoredPaymentAccount = paymentAccount.copyWith(
        balance: isCreditCard
            ? paymentAccount.balance -
                paymentAmount // Credit card: decrease debt
            : paymentAccount.balance + paymentAmount, // Other: restore balance
      );

      final updatedLoan = loan.copyWith(
        paidAmount:
            (loan.paidAmount - paymentAmount).clamp(0.0, double.infinity),
        lastPaymentDate: null,
      );

      await expenseProvider.deleteExpense(expenseId);
      await loanProvider.updateLoan(updatedLoan);
      await paymentAccountProvider.updateAccount(restoredPaymentAccount);

      await billProvider.refreshData();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Loan payment reversed',
            style: TextStyle(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Error reversing payment: $e',
            style: TextStyle(),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _markCreditCardPaid(BillReminder reminder) {
    final accounts = HiveService.getAllPaymentAccounts();

    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please add an account first',
            style: TextStyle(),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final accountTypes =
        <String>{...accounts.map((a) => a.accountType)}.toList()..sort();
    String? selectedType = accountTypes.isNotEmpty ? accountTypes.first : null;
    String? selectedAccountId;
    final remainingAmount = (reminder.amount - reminder.paidAmount)
        .clamp(0.0, reminder.amount)
        .toDouble();
    final payableAmount =
        remainingAmount > 0 ? remainingAmount : reminder.amount;
    final amountController =
        TextEditingController(text: payableAmount.toStringAsFixed(2));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final filteredByType = accountTypes.isEmpty
              ? []
              : accounts.where((a) => a.accountType == selectedType).toList();

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom +
                  effectiveBottomInset(context),
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pay Credit Card Bill',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Amount: ${reminder.currency} ${reminder.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Payment amount field
                  Text(
                    'Payment Amount:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'Enter amount',
                      helperText:
                          'Balance due: ${reminder.currency} ${payableAmount.toStringAsFixed(2)}',
                      helperStyle:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    style: const TextStyle(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select Account Type:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    items: accountTypes
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type, style: TextStyle()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedType = value;
                        selectedAccountId = null;
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select Account:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (filteredByType.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'No accounts found',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: selectedAccountId,
                      items: filteredByType
                          .map((account) => DropdownMenuItem<String>(
                                value: account.id,
                                child: Text(
                                  '${account.name} (${account.currency} ${account.balance.toStringAsFixed(2)})',
                                  style: TextStyle(),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedAccountId = value;
                        });
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      hint: Text('Choose account',
                          style: TextStyle(fontSize: 13)),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text('Cancel', style: TextStyle()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: selectedAccountId == null
                              ? null
                              : () {
                                  final enteredAmount = double.tryParse(
                                      amountController.text.trim());
                                  if (enteredAmount == null ||
                                      enteredAmount <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Please enter a valid amount',
                                            style: TextStyle()),
                                        backgroundColor: AppTheme.errorColor,
                                      ),
                                    );
                                    return;
                                  }
                                  if (enteredAmount > payableAmount) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Payment cannot exceed remaining due (${reminder.currency} ${payableAmount.toStringAsFixed(2)})',
                                          style: TextStyle(),
                                        ),
                                        backgroundColor: AppTheme.errorColor,
                                      ),
                                    );
                                    return;
                                  }
                                  Navigator.pop(context);
                                  final selectedAccount = accounts.firstWhere(
                                      (a) => a.id == selectedAccountId);
                                  _processCreditCardPayment(
                                      reminder, selectedAccount, enteredAmount);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            disabledBackgroundColor: Colors.grey.shade300,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Confirm Payment',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _processCreditCardPayment(
    BillReminder reminder,
    PaymentAccount paymentAccount,
    double paymentAmount,
  ) async {
    final expenseProvider = context.read<ExpenseProvider>();
    final paymentAccountProvider = context.read<PaymentAccountProvider>();
    final billProvider = context.read<BillProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final creditCardAccount = HiveService.getAllPaymentAccounts()
          .firstWhere((a) => a.id == reminder.sourceId);

      final expenseId = const Uuid().v4();
      final expense = Expense(
        id: expenseId,
        title: 'Credit Card Payment - ${reminder.accountName}',
        category: 'Credit Card Payment',
        amount: paymentAmount,
        date: DateTime.now(),
        currency: reminder.currency,
        paymentMethod: 'Bank Transfer',
        accountId: paymentAccount.id,
        destinationAccountId: creditCardAccount.id,
        notes: 'Paid credit card bill',
        transactionType: 'transfer',
      );

      final updatedPaymentAccount = paymentAccount.copyWith(
        balance: paymentAccount.balance - paymentAmount,
      );

      final newCreditCardBalance = (creditCardAccount.balance - paymentAmount)
          .clamp(0.0, double.infinity);
      final updatedCreditCardAccount = creditCardAccount.copyWith(
        balance: newCreditCardBalance,
      );

      await expenseProvider.addExpense(expense);
      await paymentAccountProvider.updateAccount(updatedPaymentAccount);
      await paymentAccountProvider.updateAccount(updatedCreditCardAccount);

      await billProvider.refreshData();
      if (!mounted) return;
      _showPaymentSnackBar(
        paymentAmount >= reminder.amount
            ? 'Credit card payment recorded'
            : 'Partial credit card payment recorded',
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _reverseCreditCardPayment(
            reminder,
            paymentAccount,
            creditCardAccount,
            expenseId,
            paymentAmount,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: TextStyle()),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _reverseCreditCardPayment(
    BillReminder reminder,
    PaymentAccount paymentAccount,
    PaymentAccount creditCardAccount,
    String expenseId,
    double paymentAmount,
  ) async {
    final expenseProvider = context.read<ExpenseProvider>();
    final paymentAccountProvider = context.read<PaymentAccountProvider>();
    final billProvider = context.read<BillProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final restoredPaymentAccount = paymentAccount.copyWith(
        balance: paymentAccount.balance + paymentAmount,
      );

      final restoredCreditCardAccount = creditCardAccount.copyWith(
        balance: creditCardAccount.balance + paymentAmount,
      );

      await expenseProvider.deleteExpense(expenseId);
      await paymentAccountProvider.updateAccount(restoredPaymentAccount);
      await paymentAccountProvider.updateAccount(restoredCreditCardAccount);

      await billProvider.refreshData();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Credit card payment reversed',
            style: TextStyle(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Error reversing payment: $e',
            style: TextStyle(),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _markSubscriptionPaid(BillReminder reminder) {
    final accounts = HiveService.getAllPaymentAccounts();

    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please add an account first',
            style: TextStyle(),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final accountTypes =
        <String>{...accounts.map((a) => a.accountType)}.toList()..sort();
    String? selectedType = accountTypes.isNotEmpty ? accountTypes.first : null;
    String? selectedAccountId;
    final remainingAmount = (reminder.amount - reminder.paidAmount)
        .clamp(0.0, reminder.amount)
        .toDouble();
    final payableAmount =
        remainingAmount > 0 ? remainingAmount : reminder.amount;
    final amountController =
        TextEditingController(text: payableAmount.toStringAsFixed(2));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final filteredByType = accountTypes.isEmpty
              ? []
              : accounts.where((a) => a.accountType == selectedType).toList();

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom +
                  effectiveBottomInset(context),
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pay Subscription',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  // Payment amount field
                  Text(
                    'Payment Amount:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'Enter amount',
                      helperText:
                          'Remaining due: ${reminder.currency} ${payableAmount.toStringAsFixed(2)}',
                      helperStyle:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    style: const TextStyle(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select Account Type:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    items: accountTypes
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type, style: TextStyle()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedType = value;
                        selectedAccountId = null;
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select Account:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (filteredByType.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'No accounts found',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: selectedAccountId,
                      items: filteredByType
                          .map((account) => DropdownMenuItem<String>(
                                value: account.id,
                                child: Text(
                                  '${account.name} (${account.currency} ${account.balance.toStringAsFixed(2)})',
                                  style: TextStyle(),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedAccountId = value;
                        });
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      hint: Text('Choose account',
                          style: TextStyle(fontSize: 13)),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text('Cancel', style: TextStyle()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: selectedAccountId == null
                              ? null
                              : () {
                                  final enteredAmount = double.tryParse(
                                      amountController.text.trim());
                                  if (enteredAmount == null ||
                                      enteredAmount <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Please enter a valid amount',
                                            style: TextStyle()),
                                        backgroundColor: AppTheme.errorColor,
                                      ),
                                    );
                                    return;
                                  }
                                  if (enteredAmount > payableAmount) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Payment cannot exceed remaining due (${reminder.currency} ${payableAmount.toStringAsFixed(2)})',
                                          style: TextStyle(),
                                        ),
                                        backgroundColor: AppTheme.errorColor,
                                      ),
                                    );
                                    return;
                                  }
                                  Navigator.pop(context);
                                  final selectedAccount = accounts.firstWhere(
                                      (a) => a.id == selectedAccountId);
                                  _processSubscriptionPayment(
                                      reminder, selectedAccount, enteredAmount);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            disabledBackgroundColor: Colors.grey.shade300,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Confirm Payment',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _processSubscriptionPayment(
    BillReminder reminder,
    PaymentAccount selectedAccount,
    double paymentAmount,
  ) async {
    final expenseProvider = context.read<ExpenseProvider>();
    final paymentAccountProvider = context.read<PaymentAccountProvider>();
    final billProvider = context.read<BillProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final subscriptions = HiveService.getAllSubscriptions();
      final subscription = subscriptions.firstWhere(
        (s) => s.id == reminder.sourceId,
      );

      // Create expense record to track this payment
      // The bill provider will detect this expense to mark the period as paid
      final expenseId = const Uuid().v4();
      final expense = Expense(
        id: expenseId,
        title: 'Subscription Payment - ${subscription.name}',
        category: 'Subscriptions',
        amount: paymentAmount,
        date: DateTime.now(),
        currency: subscription.currency,
        paymentMethod: 'Bank Transfer',
        accountId: selectedAccount.id,
        notes: 'Paid subscription: ${subscription.name}',
        transactionType: 'payment',
      );

      // Update account balance
      // Check if payment account is a credit card
      final isCreditCard =
          selectedAccount.accountType.toLowerCase().contains('credit');
      final updatedAccount = selectedAccount.copyWith(
        balance: isCreditCard
            ? selectedAccount.balance +
                paymentAmount // Credit card: increase debt
            : selectedAccount.balance -
                paymentAmount, // Other: decrease balance
      );

      // No need to update subscription - payment is tracked via expense record
      await expenseProvider.addExpense(expense);
      await paymentAccountProvider.updateAccount(updatedAccount);
      await billProvider.refreshData();

      if (!mounted) return;
      _showPaymentSnackBar(
        paymentAmount >= subscription.cost
            ? 'Subscription payment recorded'
            : 'Partial subscription payment recorded',
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _reverseSubscriptionPayment(
            subscription,
            selectedAccount,
            expenseId,
            paymentAmount,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: TextStyle()),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _reverseSubscriptionPayment(
    Subscription subscription,
    PaymentAccount paymentAccount,
    String expenseId,
    double paymentAmount,
  ) async {
    final expenseProvider = context.read<ExpenseProvider>();
    final paymentAccountProvider = context.read<PaymentAccountProvider>();
    final billProvider = context.read<BillProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      // Restore account balance
      // Check if payment account is a credit card
      final isCreditCard =
          paymentAccount.accountType.toLowerCase().contains('credit');
      final restoredAccount = paymentAccount.copyWith(
        balance: isCreditCard
            ? paymentAccount.balance -
                paymentAmount // Credit card: decrease debt
            : paymentAccount.balance + paymentAmount, // Other: restore balance
      );

      // Delete expense record - this will automatically mark period as unpaid
      await expenseProvider.deleteExpense(expenseId);
      await paymentAccountProvider.updateAccount(restoredAccount);

      await billProvider.refreshData();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Subscription payment reversed',
            style: TextStyle(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Error reversing payment: $e',
            style: TextStyle(),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showEditReminderDialog(BillReminder reminder) {
    switch (reminder.type) {
      case BillReminderType.bill:
        final bills = HiveService.getAllBills();
        final bill = _firstWhereOrNull(bills, (b) => b.id == reminder.sourceId);
        if (bill == null) return;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => AddEditBillScreen(bill: bill),
        ).then((_) {
          if (mounted) context.read<BillProvider>().refreshData();
        });
        break;
      case BillReminderType.loan:
        final loans = HiveService.getAllLoans();
        final loan = _firstWhereOrNull(loans, (l) => l.id == reminder.sourceId);
        if (loan == null) return;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => AddEditLoanDialog(loan: loan),
        ).then((_) {
          if (mounted) context.read<BillProvider>().refreshData();
        });
        break;
      case BillReminderType.subscription:
        final subs = HiveService.getAllSubscriptions();
        final sub = _firstWhereOrNull(subs, (s) => s.id == reminder.sourceId);
        if (sub == null) return;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => AddEditSubscriptionScreen(subscription: sub),
        ).then((_) {
          if (mounted) context.read<BillProvider>().refreshData();
        });
        break;
      case BillReminderType.creditCard:
        final accts = HiveService.getAllPaymentAccounts();
        final account =
            _firstWhereOrNull(accts, (a) => a.id == reminder.sourceId);
        if (account == null) return;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => AccountFormScreen(account: account),
        ).then((_) {
          if (mounted) context.read<BillProvider>().refreshData();
        });
        break;
    }
  }

  void _confirmDeleteSourceReminder(BillReminder reminder) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete ${reminder.accountName ?? reminder.name}?',
          style: const TextStyle(),
        ),
        content: Text(
          'This will permanently delete this record and cannot be undone.',
          style: const TextStyle(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteSourceReminder(reminder);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSourceReminder(BillReminder reminder) async {
    final billProvider = context.read<BillProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      switch (reminder.type) {
        case BillReminderType.bill:
          await billProvider.deleteBill(reminder.sourceId);
          break;
        case BillReminderType.loan:
          await context.read<LoanProvider>().deleteLoan(reminder.sourceId);
          break;
        case BillReminderType.subscription:
          await context
              .read<SubscriptionProvider>()
              .deleteSubscription(reminder.sourceId);
          break;
        case BillReminderType.creditCard:
          await context
              .read<PaymentAccountProvider>()
              .deleteAccount(reminder.sourceId);
          break;
      }
      await billProvider.refreshData();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Deleted successfully', style: const TextStyle()),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error deleting: $e', style: const TextStyle()),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showAddManualBillDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const AddEditBillScreen(bill: null),
    );
  }

  void _showReminderDetails(BillReminder reminder) {
    // Fetch payment details for completed reminders
    String? paymentAccountName;
    String? paymentType;

    if (reminder.status == BillReminderStatus.completed) {
      final expenseProvider =
          Provider.of<ExpenseProvider>(context, listen: false);
      final accountProvider =
          Provider.of<PaymentAccountProvider>(context, listen: false);

      // Find the expense associated with this bill payment
      // Try multiple strategies to find the matching expense
      Expense? expense;

      // Strategy 1: Match by notes containing the name and amount (any transaction type)
      expense = _firstWhereOrNull(
        expenseProvider.expenses,
        (e) =>
            (e.notes?.contains(reminder.name) ?? false) &&
            (e.amount - reminder.amount).abs() <
                0.01, // Allow small floating point differences
      );

      // Strategy 2: Match by title containing the name and amount
      expense ??= _firstWhereOrNull(
        expenseProvider.expenses,
        (e) =>
            e.title.contains(reminder.name) &&
            (e.amount - reminder.amount).abs() < 0.01,
      );

      // Strategy 3: Match by category and amount (for specific payment categories)
      if (expense == null) {
        final categories = [
          'Bills & Utilities',
          'Subscriptions',
          'Loan Repayment',
          'Credit Card Payment'
        ];
        expense = _firstWhereOrNull(
          expenseProvider.expenses,
          (e) =>
              categories.contains(e.category) &&
              (e.amount - reminder.amount).abs() < 0.01,
        );
      }

      if (expense != null && expense.accountId != null) {
        paymentType = expense.paymentMethod;
        final account = _firstWhereOrNull(
          accountProvider.accounts,
          (a) => a.id == expense!.accountId,
        );
        if (account != null) {
          paymentAccountName = account.name;
        }
      }
    }

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            effectiveBottomInset(context) + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      reminder.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildDetailRow('Type', reminder.getTypeLabel()),
              _buildDetailRow('Amount',
                  '${reminder.currency} ${reminder.amount.toStringAsFixed(2)}'),
              _buildDetailRow('Due Date', _formatDate(reminder.dueDate)),
              _buildDetailRow('Status', reminder.getStatusLabel()),
              if (reminder.status == BillReminderStatus.completed &&
                  paymentType == null &&
                  paymentAccountName == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 20, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Payment details not available for this transaction',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (paymentType != null)
                _buildDetailRow('Payment Type', paymentType),
              if (paymentAccountName != null)
                _buildDetailRow('Payment Account', paymentAccountName),
              if (reminder.notes != null)
                _buildDetailRow('Notes', reminder.notes!),
              if (reminder.lender != null)
                _buildDetailRow('Lender', reminder.lender!),
              if (reminder.accountName != null)
                _buildDetailRow('Account', reminder.accountName!),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle()),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatMonth(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
      Provider.of<BillProvider>(context, listen: false)
          .setSelectedMonth(_selectedMonth);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
      Provider.of<BillProvider>(context, listen: false)
          .setSelectedMonth(_selectedMonth);
    });
  }

  void _showMonthPicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      helpText: 'Select Month',
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month, 1);
        Provider.of<BillProvider>(context, listen: false)
            .setSelectedMonth(_selectedMonth);
      });
    }
  }

  T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T item) test) {
    for (final item in items) {
      if (test(item)) {
        return item;
      }
    }
    return null;
  }
}

// Add manual bill screen (simplified version)
class AddEditBillScreen extends StatefulWidget {
  final Bill? bill;

  const AddEditBillScreen({super.key, this.bill});

  @override
  State<AddEditBillScreen> createState() => _AddEditBillScreenState();
}

class _AddEditBillScreenState extends State<AddEditBillScreen> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late DateTime _selectedDueDate;
  late bool _isRecurring;
  late String _recurringFrequency;

  @override
  void initState() {
    super.initState();
    if (widget.bill != null) {
      _nameController = TextEditingController(text: widget.bill!.name);
      _amountController =
          TextEditingController(text: widget.bill!.amount.toString());
      _notesController = TextEditingController(text: widget.bill!.notes ?? '');
      _selectedDueDate = widget.bill!.dueDate;
      _isRecurring = widget.bill!.isRecurring;
      _recurringFrequency = widget.bill!.recurringFrequency ?? 'monthly';
    } else {
      _nameController = TextEditingController();
      _amountController = TextEditingController();
      _notesController = TextEditingController();
      _selectedDueDate = DateTime.now().add(const Duration(days: 7));
      _isRecurring = false;
      _recurringFrequency = 'monthly';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom +
              effectiveBottomInset(context),
          left: 16,
          right: 16,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.bill != null ? 'Edit Bill' : 'Add Manual Bill',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Bill Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Due Date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(_formatDate(_selectedDueDate)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Add any additional notes',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text(
                  'Recurring Bill',
                  style: TextStyle(),
                ),
                value: _isRecurring,
                onChanged: (value) =>
                    setState(() => _isRecurring = value ?? false),
              ),
              if (_isRecurring) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButton<String>(
                    value: _recurringFrequency,
                    isExpanded: true,
                    items: const ['monthly', 'quarterly', 'yearly']
                        .map((f) => DropdownMenuItem(
                              value: f,
                              child: Text(
                                f.toUpperCase(),
                                style: TextStyle(),
                              ),
                            ))
                        .toList(),
                    onChanged: (value) => setState(
                        () => _recurringFrequency = value ?? 'monthly'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _saveBill(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    widget.bill != null ? 'Update Bill' : 'Add Bill',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  void _saveBill(BuildContext context) {
    if (_nameController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    final currencyCode =
        Provider.of<SettingsProvider>(context, listen: false).currency;

    final bill = widget.bill != null
        ? widget.bill!.copyWith(
            name: _nameController.text,
            amount: double.parse(_amountController.text),
            dueDate: _selectedDueDate,
            notes: _notesController.text,
            currency: currencyCode,
            isRecurring: _isRecurring,
            recurringFrequency: _isRecurring ? _recurringFrequency : null,
          )
        : Bill(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: _nameController.text,
            amount: double.parse(_amountController.text),
            dueDate: _selectedDueDate,
            createdAt: DateTime.now(),
            notes: _notesController.text,
            currency: currencyCode,
            isRecurring: _isRecurring,
            recurringFrequency: _isRecurring ? _recurringFrequency : null,
          );

    if (widget.bill != null) {
      Provider.of<BillProvider>(context, listen: false).updateBill(bill);
    } else {
      Provider.of<BillProvider>(context, listen: false).addBill(bill);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.bill != null ? 'Bill updated' : 'Bill added',
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
