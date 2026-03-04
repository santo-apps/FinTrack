import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'package:fintrack/features/expense/data/models/expense_model.dart';
import 'package:fintrack/features/expense/presentation/providers/expense_provider.dart';
import 'package:fintrack/features/accounts/data/models/payment_account_model.dart';
import 'package:fintrack/features/accounts/presentation/providers/payment_account_provider.dart';
import 'package:fintrack/features/subscription/presentation/providers/subscription_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    Future.microtask(() {
      if (mounted) {
        final provider = Provider.of<BillProvider>(context, listen: false);
        provider.initBills();
        provider.setSelectedMonth(_selectedMonth);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: widget.showAppBar
            ? AppBar(
                title: const Text('Bill Reminders'),
                leading: widget.showBackButton
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      )
                    : null,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _showAddManualBillDialog(context),
                    tooltip: 'Add Manual Bill',
                  ),
                ],
              )
            : null,
        body: Column(
          children: [
            // Month Selector
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
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
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatMonth(_selectedMonth),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _nextMonth,
                    tooltip: 'Next Month',
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              child: TabBar(
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey.shade700,
                indicatorColor: Colors.blue,
                indicatorWeight: 3,
                labelPadding: const EdgeInsets.symmetric(horizontal: 12.0),
                labelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(
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
                      .where((r) => r.status == BillReminderStatus.pending)
                      .toList();
                  final completedReminders = billProvider
                      .getRemindersForMonth(_selectedMonth)
                      .where((r) => r.status == BillReminderStatus.completed)
                      .toList();

                  return TabBarView(
                    children: [
                      _buildRemindersList(pendingReminders, 'No pending bills'),
                      _buildRemindersList(overdueReminders, 'No overdue bills'),
                      _buildRemindersList(
                          completedReminders, 'No completed bills'),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'bill_list_fab_add',
          onPressed: () => _showAddManualBillDialog(context),
          tooltip: 'Add Manual Bill',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(List<BillReminder> reminders) {
    if (reminders.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.receipt_long,
        title: 'No Bills',
        description:
            'Add manual bills or they will appear from loans, subscriptions, and credit cards',
        actionLabel: 'Add Manual Bill',
        onAction: () => _showAddManualBillDialog(context),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<BillProvider>(context, listen: false).refreshData();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reminders.length,
        itemBuilder: (context, index) {
          return _buildReminderCard(reminders[index]);
        },
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
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(emptyMessage,
                style: GoogleFonts.poppins(
                    fontSize: 16, color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<BillProvider>(context, listen: false).refreshData();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$currency ${grandTotal.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
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
                Colors.purple,
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
              color: color.withOpacity(0.1),
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
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$count item${count > 1 ? "s" : ""}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$currency ${amount.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
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
    final daysUntilDue = reminder.getDaysUntilDue();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reminder.getTypeLabel(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? Colors.green.shade100
                          : (isOverdue
                              ? Colors.red.shade100
                              : Colors.orange.shade100),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      reminder.getStatusLabel(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isPaid
                            ? Colors.green.shade700
                            : (isOverdue
                                ? Colors.red.shade700
                                : Colors.orange.shade700),
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
                    style: GoogleFonts.poppins(
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
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (isPending && daysUntilDue >= 0)
                        Text(
                          daysUntilDue == 0
                              ? 'Due today'
                              : daysUntilDue == 1
                                  ? 'Due in 1 day'
                                  : 'Due in $daysUntilDue days',
                          style: GoogleFonts.poppins(
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
              if (!isPaid) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleMarkAsPaid(reminder),
                    icon: const Icon(Icons.check),
                    label: const Text('Mark as Paid'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
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
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit Account'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _confirmDeleteCompletedReminder(reminder),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete'),
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
            style: GoogleFonts.poppins(),
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
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
      return;
    }

    String? selectedAccountId;
    await showModalBottomSheet(
      context: context,
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
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedAccountId,
                  items: accounts
                      .map(
                        (account) => DropdownMenuItem<String>(
                          value: account.id,
                          child: SizedBox(
                            width: 250,
                            child: Text(
                              '${account.name} (${account.currency} ${account.balance.toStringAsFixed(2)})',
                              style: GoogleFonts.poppins(),
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
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: selectedAccountId == null
                      ? null
                      : () async {
                          final selectedAccount = accounts
                              .firstWhere((a) => a.id == selectedAccountId);

                          if (reminder.type == BillReminderType.loan) {
                            final loans = HiveService.getAllLoans();
                            final loan = loans.firstWhere(
                              (l) => l.id == reminder.sourceId,
                            );
                            final updatedLoan =
                                loan.copyWith(accountId: selectedAccount.id);
                            await Provider.of<LoanProvider>(context,
                                    listen: false)
                                .updateLoan(updatedLoan);
                          } else if (reminder.type ==
                              BillReminderType.creditCard) {
                            final cards = HiveService.getAllPaymentAccounts();
                            final card = cards.firstWhere(
                              (a) => a.id == reminder.sourceId,
                            );
                            final updatedCard = card.copyWith(
                                linkedAccountId: selectedAccount.id);
                            await Provider.of<PaymentAccountProvider>(context,
                                    listen: false)
                                .updateAccount(updatedCard);
                          }

                          if (mounted) {
                            Navigator.pop(context);
                            await Provider.of<BillProvider>(context,
                                    listen: false)
                                .refreshData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Bank account updated',
                                  style: GoogleFonts.poppins(),
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
                    style: GoogleFonts.poppins(
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
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            content: Text(
              'This will move the entry back to Pending to avoid accidental updates.',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: GoogleFonts.poppins()),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                ),
                child: Text(
                  'Delete',
                  style: GoogleFonts.poppins(
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
    try {
      switch (reminder.type) {
        case BillReminderType.bill:
          final bills = HiveService.getAllBills();
          final bill = bills.firstWhere((b) => b.id == reminder.sourceId);
          final updatedBill = bill.copyWith(isPaid: false, paidDate: null);
          await Provider.of<BillProvider>(context, listen: false)
              .updateBill(updatedBill);
          break;
        case BillReminderType.loan:
          final loans = HiveService.getAllLoans();
          final loan = loans.firstWhere((l) => l.id == reminder.sourceId);
          final updatedLoan = loan.copyWith(
            paidAmount: (loan.paidAmount - loan.monthlyEmi).clamp(
              0.0,
              loan.borrowedAmount,
            ),
            lastPaymentDate: null,
          );
          await Provider.of<LoanProvider>(context, listen: false)
              .updateLoan(updatedLoan);
          break;
        case BillReminderType.creditCard:
          await _promptCreditCardPendingAmount(reminder);
          return;
        case BillReminderType.subscription:
          final subscriptions = HiveService.getAllSubscriptions();
          final subscription = subscriptions.firstWhere(
            (s) => s.id == reminder.sourceId,
          );
          final previousRenewalDate = _subtractBillingCycle(
              subscription.renewalDate, subscription.billingCycle);
          final updatedSubscription =
              subscription.copyWith(renewalDate: previousRenewalDate);
          await Provider.of<SubscriptionProvider>(context, listen: false)
              .updateSubscription(updatedSubscription);
          break;
      }

      if (mounted) {
        await Provider.of<BillProvider>(context, listen: false).refreshData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Entry moved to pending',
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to update entry: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _promptCreditCardPendingAmount(BillReminder reminder) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Move Credit Card to Pending',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the outstanding amount to reopen this credit card bill.',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Outstanding amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              final entered = double.tryParse(controller.text.trim());
              if (entered == null || entered <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please enter a valid amount',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
                return;
              }

              final cards = HiveService.getAllPaymentAccounts();
              final card = cards.firstWhere((a) => a.id == reminder.sourceId);
              final updatedCard = card.copyWith(balance: entered);

              await Provider.of<PaymentAccountProvider>(context, listen: false)
                  .updateAccount(updatedCard);
              await Provider.of<BillProvider>(context, listen: false)
                  .refreshData();

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Entry moved to pending',
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime _subtractBillingCycle(DateTime date, String cycle) {
    switch (cycle.toLowerCase()) {
      case 'weekly':
        return date.subtract(const Duration(days: 7));
      case 'monthly':
        return DateTime(date.year, date.month - 1, date.day);
      case 'quarterly':
        return DateTime(date.year, date.month - 3, date.day);
      case 'yearly':
      case 'annual':
        return DateTime(date.year - 1, date.month, date.day);
      default:
        return DateTime(date.year, date.month - 1, date.day);
    }
  }

  void _markBillPaid(BillReminder reminder) {
    final accounts = HiveService.getAllPaymentAccounts();

    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please add an account first',
            style: GoogleFonts.poppins(),
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
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final filteredByType = accountTypes.isEmpty
              ? []
              : accounts
                  .where((a) => a.accountType == selectedType)
                  .where((a) =>
                      a.name.toLowerCase().contains(searchQuery.toLowerCase()))
                  .toList();

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
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
                        'Mark Bill as Paid',
                        style: GoogleFonts.poppins(
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
                  Text(
                    'Select Account Type:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    items: accountTypes
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type, style: GoogleFonts.poppins()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedType = value;
                        selectedAccountId = null;
                        searchQuery = '';
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
                    'Search Account:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by account name...',
                      hintStyle: GoogleFonts.poppins(fontSize: 12),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select Account:',
                    style: GoogleFonts.poppins(
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
                        style: GoogleFonts.poppins(
                            color: Colors.grey, fontSize: 13),
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: selectedAccountId,
                      items: filteredByType
                          .map((account) => DropdownMenuItem<String>(
                                value: account.id,
                                child: Text(
                                  '${account.name} (${account.currency} ${account.balance.toStringAsFixed(2)})',
                                  style: GoogleFonts.poppins(),
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
                          style: GoogleFonts.poppins(fontSize: 13)),
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
                          child: Text('Cancel', style: GoogleFonts.poppins()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: selectedAccountId == null
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  final selectedAccount = accounts.firstWhere(
                                      (a) => a.id == selectedAccountId);
                                  _processBillPayment(
                                      reminder, selectedAccount);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            disabledBackgroundColor: Colors.grey.shade300,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Confirm Payment',
                            style: GoogleFonts.poppins(
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
  ) async {
    try {
      final bills = HiveService.getAllBills();
      final bill = bills.firstWhere((b) => b.id == reminder.sourceId);

      final expenseId = const Uuid().v4();
      final expense = Expense(
        id: expenseId,
        title: 'Bill Payment - ${bill.name}',
        category: 'Bills & Utilities',
        amount: bill.amount,
        date: DateTime.now(),
        currency: bill.currency,
        paymentMethod: 'Bank Transfer',
        accountId: selectedAccount.id,
        notes: 'Paid bill: ${bill.name}',
        transactionType: 'payment',
      );

      final updatedBill = bill.copyWith(
        isPaid: true,
        paidDate: DateTime.now(),
      );

      final updatedAccount = selectedAccount.copyWith(
        balance: selectedAccount.balance - bill.amount,
      );

      if (mounted) {
        await Provider.of<BillProvider>(context, listen: false)
            .updateBill(updatedBill);
        await Provider.of<ExpenseProvider>(context, listen: false)
            .addExpense(expense);
        await Provider.of<PaymentAccountProvider>(context, listen: false)
            .updateAccount(updatedAccount);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bill marked as paid',
              style: GoogleFonts.poppins(),
            ),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => _reverseBillPayment(
                bill,
                selectedAccount,
                expenseId,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _reverseBillPayment(
    Bill bill,
    PaymentAccount paymentAccount,
    String expenseId,
  ) async {
    try {
      final revertedBill = bill.copyWith(
        isPaid: false,
        paidDate: null,
      );

      final restoredAccount = paymentAccount.copyWith(
        balance: paymentAccount.balance + bill.amount,
      );

      await Provider.of<ExpenseProvider>(context, listen: false)
          .deleteExpense(expenseId);
      await Provider.of<BillProvider>(context, listen: false)
          .updateBill(revertedBill);
      await Provider.of<PaymentAccountProvider>(context, listen: false)
          .updateAccount(restoredAccount);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bill payment reverted',
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error reverting payment: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _markLoanPaid(BillReminder reminder) {
    final accounts = HiveService.getAllPaymentAccounts();

    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please add an account first',
            style: GoogleFonts.poppins(),
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
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final filteredByType = accountTypes.isEmpty
              ? []
              : accounts
                  .where((a) => a.accountType == selectedType)
                  .where((a) =>
                      a.name.toLowerCase().contains(searchQuery.toLowerCase()))
                  .toList();

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
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
                        style: GoogleFonts.poppins(
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
                  Text(
                    'Select Account Type:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    items: accountTypes
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type, style: GoogleFonts.poppins()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedType = value;
                        selectedAccountId = null;
                        searchQuery = '';
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
                    'Search Account:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by account name...',
                      hintStyle: GoogleFonts.poppins(fontSize: 12),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select Account:',
                    style: GoogleFonts.poppins(
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
                        style: GoogleFonts.poppins(
                            color: Colors.grey, fontSize: 13),
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: selectedAccountId,
                      items: filteredByType
                          .map((account) => DropdownMenuItem<String>(
                                value: account.id,
                                child: Text(
                                  '${account.name} (${account.currency} ${account.balance.toStringAsFixed(2)})',
                                  style: GoogleFonts.poppins(),
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
                          style: GoogleFonts.poppins(fontSize: 13)),
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
                          child: Text('Cancel', style: GoogleFonts.poppins()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: selectedAccountId == null
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  final selectedAccount = accounts.firstWhere(
                                      (a) => a.id == selectedAccountId);
                                  _processLoanPayment(
                                      reminder, selectedAccount);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            disabledBackgroundColor: Colors.grey.shade300,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Confirm Payment',
                            style: GoogleFonts.poppins(
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
  ) async {
    try {
      final loans = HiveService.getAllLoans();
      final loan = loans.firstWhere((l) => l.id == reminder.sourceId);

      final expenseId = const Uuid().v4();
      final expense = Expense(
        id: expenseId,
        title: 'Loan EMI Payment - ${loan.lender}',
        category: 'Loan Repayment',
        amount: loan.monthlyEmi,
        date: DateTime.now(),
        currency: loan.currency,
        paymentMethod: 'Bank Transfer',
        accountId: paymentAccount.id,
        notes: 'EMI payment to ${loan.lender}',
        transactionType: 'payment',
      );

      final updatedPaymentAccount = paymentAccount.copyWith(
        balance: paymentAccount.balance - loan.monthlyEmi,
      );

      await Provider.of<LoanProvider>(context, listen: false)
          .makePayment(loan.id, loan.monthlyEmi);
      await Provider.of<ExpenseProvider>(context, listen: false)
          .addExpense(expense);
      await Provider.of<PaymentAccountProvider>(context, listen: false)
          .updateAccount(updatedPaymentAccount);

      if (mounted) {
        await Provider.of<BillProvider>(context, listen: false).refreshData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Loan EMI payment recorded',
              style: GoogleFonts.poppins(),
            ),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => _reverseLoanPayment(
                loan,
                paymentAccount,
                expenseId,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _reverseLoanPayment(
    Loan loan,
    PaymentAccount paymentAccount,
    String expenseId,
  ) async {
    try {
      final restoredPaymentAccount = paymentAccount.copyWith(
        balance: paymentAccount.balance + loan.monthlyEmi,
      );

      final updatedLoan = loan.copyWith(
        paidAmount: loan.paidAmount - loan.monthlyEmi,
        lastPaymentDate: null,
      );

      await Provider.of<ExpenseProvider>(context, listen: false)
          .deleteExpense(expenseId);
      await Provider.of<LoanProvider>(context, listen: false)
          .updateLoan(updatedLoan);
      await Provider.of<PaymentAccountProvider>(context, listen: false)
          .updateAccount(restoredPaymentAccount);

      if (mounted) {
        await Provider.of<BillProvider>(context, listen: false).refreshData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Loan payment reversed',
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error reversing payment: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _markCreditCardPaid(BillReminder reminder) {
    final accounts = HiveService.getAllPaymentAccounts();

    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please add an account first',
            style: GoogleFonts.poppins(),
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
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final filteredByType = accountTypes.isEmpty
              ? []
              : accounts
                  .where((a) => a.accountType == selectedType)
                  .where((a) =>
                      a.name.toLowerCase().contains(searchQuery.toLowerCase()))
                  .toList();

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
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
                        style: GoogleFonts.poppins(
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
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select Account Type:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    items: accountTypes
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type, style: GoogleFonts.poppins()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedType = value;
                        selectedAccountId = null;
                        searchQuery = '';
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
                    'Search Account:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by account name...',
                      hintStyle: GoogleFonts.poppins(fontSize: 12),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select Account:',
                    style: GoogleFonts.poppins(
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
                        style: GoogleFonts.poppins(
                            color: Colors.grey, fontSize: 13),
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: selectedAccountId,
                      items: filteredByType
                          .map((account) => DropdownMenuItem<String>(
                                value: account.id,
                                child: Text(
                                  '${account.name} (${account.currency} ${account.balance.toStringAsFixed(2)})',
                                  style: GoogleFonts.poppins(),
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
                          style: GoogleFonts.poppins(fontSize: 13)),
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
                          child: Text('Cancel', style: GoogleFonts.poppins()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: selectedAccountId == null
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  final selectedAccount = accounts.firstWhere(
                                      (a) => a.id == selectedAccountId);
                                  _processCreditCardPayment(
                                      reminder, selectedAccount);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            disabledBackgroundColor: Colors.grey.shade300,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Confirm Payment',
                            style: GoogleFonts.poppins(
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
  ) async {
    try {
      final creditCardAccount = HiveService.getAllPaymentAccounts()
          .firstWhere((a) => a.id == reminder.sourceId);

      final expenseId = const Uuid().v4();
      final expense = Expense(
        id: expenseId,
        title: 'Credit Card Payment - ${reminder.accountName}',
        category: 'Credit Card Payment',
        amount: reminder.amount,
        date: DateTime.now(),
        currency: reminder.currency,
        paymentMethod: 'Bank Transfer',
        accountId: paymentAccount.id,
        destinationAccountId: creditCardAccount.id,
        notes: 'Paid credit card bill',
        transactionType: 'transfer',
      );

      final updatedPaymentAccount = paymentAccount.copyWith(
        balance: paymentAccount.balance - reminder.amount,
      );

      final updatedCreditCardAccount = creditCardAccount.copyWith(
        balance: 0.0,
      );

      await Provider.of<ExpenseProvider>(context, listen: false)
          .addExpense(expense);
      await Provider.of<PaymentAccountProvider>(context, listen: false)
          .updateAccount(updatedPaymentAccount);
      await Provider.of<PaymentAccountProvider>(context, listen: false)
          .updateAccount(updatedCreditCardAccount);

      if (mounted) {
        await Provider.of<BillProvider>(context, listen: false).refreshData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Credit card payment recorded',
              style: GoogleFonts.poppins(),
            ),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => _reverseCreditCardPayment(
                reminder,
                paymentAccount,
                creditCardAccount,
                expenseId,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _reverseCreditCardPayment(
    BillReminder reminder,
    PaymentAccount paymentAccount,
    PaymentAccount creditCardAccount,
    String expenseId,
  ) async {
    try {
      final restoredPaymentAccount = paymentAccount.copyWith(
        balance: paymentAccount.balance + reminder.amount,
      );

      final restoredCreditCardAccount =
          creditCardAccount.copyWith(balance: reminder.amount);

      await Provider.of<ExpenseProvider>(context, listen: false)
          .deleteExpense(expenseId);
      await Provider.of<PaymentAccountProvider>(context, listen: false)
          .updateAccount(restoredPaymentAccount);
      await Provider.of<PaymentAccountProvider>(context, listen: false)
          .updateAccount(restoredCreditCardAccount);

      if (mounted) {
        await Provider.of<BillProvider>(context, listen: false).refreshData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Credit card payment reversed',
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error reversing payment: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _markSubscriptionPaid(BillReminder reminder) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Mark Subscription as Paid',
                    style: GoogleFonts.poppins(
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
            Text(
              'This will advance the renewal date for ${reminder.name}.',
              style: GoogleFonts.poppins(fontSize: 16),
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
                    child: Text('Cancel', style: GoogleFonts.poppins()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      final subscriptions = HiveService.getAllSubscriptions();
                      final subscription = subscriptions.firstWhere(
                        (s) => s.id == reminder.sourceId,
                      );

                      DateTime nextRenewalDate = subscription.renewalDate;
                      switch (subscription.billingCycle.toLowerCase()) {
                        case 'weekly':
                          nextRenewalDate =
                              nextRenewalDate.add(const Duration(days: 7));
                          break;
                        case 'monthly':
                          nextRenewalDate = DateTime(
                            nextRenewalDate.year,
                            nextRenewalDate.month + 1,
                            nextRenewalDate.day,
                          );
                          break;
                        case 'quarterly':
                          nextRenewalDate = DateTime(
                            nextRenewalDate.year,
                            nextRenewalDate.month + 3,
                            nextRenewalDate.day,
                          );
                          break;
                        case 'yearly':
                        case 'annual':
                          nextRenewalDate = DateTime(
                            nextRenewalDate.year + 1,
                            nextRenewalDate.month,
                            nextRenewalDate.day,
                          );
                          break;
                      }

                      final updatedSubscription =
                          subscription.copyWith(renewalDate: nextRenewalDate);
                      await Provider.of<SubscriptionProvider>(context,
                              listen: false)
                          .updateSubscription(updatedSubscription);

                      if (mounted) {
                        await Provider.of<BillProvider>(context, listen: false)
                            .refreshData();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Subscription renewal date updated',
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Mark as Paid',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddManualBillDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddEditBillScreen(bill: null),
    );
  }

  void _showReminderDetails(BillReminder reminder) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
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
                    style: GoogleFonts.poppins(
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
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
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
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.poppins()),
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
          bottom: MediaQuery.of(context).viewInsets.bottom,
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
                    style: GoogleFonts.poppins(
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
                title: const Text('Recurring Bill'),
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
                            value: f, child: Text(f.toUpperCase())))
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
                    style: GoogleFonts.poppins(
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
