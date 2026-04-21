import 'package:flutter/foundation.dart';
import 'package:fintrack/database/hive_service.dart';
import 'package:fintrack/features/bill/data/models/bill_model.dart';
import 'package:fintrack/features/bill/data/models/bill_reminder_model.dart';
import 'package:fintrack/features/subscription/data/models/subscription_model.dart';

class BillProvider extends ChangeNotifier {
  List<Bill> _bills = [];
  DateTime _selectedMonth = DateTime.now();

  List<Bill> get bills => _bills;
  List<Bill> get upcomingBills => HiveService.getUpcomingBills();
  List<Bill> get overdueBills => HiveService.getOverdueBills();
  DateTime get selectedMonth => _selectedMonth;

  BillProvider() {
    _loadBills();
  }

  Future<void> initBills() async {
    _loadBills();
    notifyListeners();
  }

  void _loadBills() {
    _bills = HiveService.getAllBills();
  }

  Future<void> addBill(Bill bill) async {
    try {
      await HiveService.addBill(bill);
      _bills.add(bill);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateBill(Bill bill) async {
    try {
      await HiveService.updateBill(bill);
      final index = _bills.indexWhere((b) => b.id == bill.id);
      if (index != -1) {
        _bills[index] = bill;
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBill(String id) async {
    try {
      await HiveService.deleteBill(id);
      _bills.removeWhere((b) => b.id == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAsPaid(String billId) async {
    try {
      final bill = _bills.firstWhere((b) => b.id == billId);
      final updatedBill = bill.copyWith(
        isPaid: true,
        paidDate: DateTime.now(),
      );
      await updateBill(updatedBill);
    } catch (e) {
      rethrow;
    }
  }

  double getTotalOverdueBillsAmount() {
    return overdueBills.fold<double>(0, (sum, b) => sum + b.amount);
  }

  double getTotalUnpaidBillsAmount() {
    return _bills
        .where((b) => !b.isPaid)
        .fold<double>(0, (sum, b) => sum + b.amount);
  }

  int getOverdueBillsCount() {
    return overdueBills.length;
  }

  int getUpcomingBillsCount() {
    return upcomingBills.length;
  }

  Future<void> refreshData() async {
    _loadBills();
    notifyListeners();
  }

  void setSelectedMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month, 1);
    notifyListeners();
  }

  /// Get all bill reminders aggregated from multiple sources
  List<BillReminder> getAllReminders() {
    return getRemindersForMonth(_selectedMonth);
  }

  /// Get reminders filtered by month
  List<BillReminder> getRemindersForMonth(DateTime month) {
    final selectedMonth = DateTime(month.year, month.month, 1);
    final List<BillReminder> allReminders = [];

    final billReminders = _getRemindersFromBills(selectedMonth);
    final cardReminders = _getRemindersFromCreditCards(selectedMonth);
    final loanReminders = _getRemindersFromLoans(selectedMonth);
    final subscriptionReminders = _getRemindersFromSubscriptions(selectedMonth);

    allReminders
      ..addAll(billReminders)
      ..addAll(cardReminders)
      ..addAll(loanReminders)
      ..addAll(subscriptionReminders);

    if (kDebugMode) {
      print('🗓️ Month: ${selectedMonth.year}-${selectedMonth.month}');
      print('📝 Bills: ${billReminders.length} reminders');
      print('💳 Credit Cards: ${cardReminders.length} reminders');
      print('🏦 Loans: ${loanReminders.length} reminders');
      print('📱 Subscriptions: ${subscriptionReminders.length} reminders');
      print('📊 Total reminders: ${allReminders.length}');
    }

    allReminders.sort((a, b) {
      final dateCompare = a.dueDate.compareTo(b.dueDate);
      if (dateCompare != 0) {
        return dateCompare;
      }
      return a.name.compareTo(b.name);
    });

    return allReminders;
  }

  /// Get overdue reminders for selected month
  List<BillReminder> getOverdueReminders() {
    final reminders = getRemindersForMonth(_selectedMonth);
    return reminders
        .where((r) => r.status == BillReminderStatus.overdue)
        .toList();
  }

  /// Get pending reminders for selected month
  List<BillReminder> getPendingReminders() {
    final reminders = getRemindersForMonth(_selectedMonth);
    return reminders
        .where((r) => r.status == BillReminderStatus.pending)
        .toList();
  }

  /// Get completed reminders for selected month
  List<BillReminder> getCompletedReminders() {
    final reminders = getRemindersForMonth(_selectedMonth);
    return reminders
        .where((r) => r.status == BillReminderStatus.completed)
        .toList();
  }

  // Convert Bills to BillReminders
  List<BillReminder> _getRemindersFromBills(DateTime month) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<BillReminder> reminders = [];

    for (final bill in _bills) {
      final dueDate = _resolveBillDueDateForMonth(bill, month);
      final paidInSelectedMonth =
          bill.paidDate != null && _isSameMonth(bill.paidDate!, month);

      if (dueDate == null && !paidInSelectedMonth) {
        continue;
      }

      final effectiveDate = dueDate ?? bill.paidDate!;
      final status = bill.isPaid
          ? BillReminderStatus.completed
          : (DateTime(effectiveDate.year, effectiveDate.month,
                      effectiveDate.day)
                  .isBefore(today)
              ? BillReminderStatus.overdue
              : BillReminderStatus.pending);

      reminders.add(
        BillReminder(
          id: 'bill_${bill.id}_${month.year}_${month.month}',
          sourceId: bill.id,
          name: bill.name,
          amount: bill.amount,
          dueDate: effectiveDate,
          currency: bill.currency,
          type: BillReminderType.bill,
          status: status,
          notes: bill.notes,
          paidDate: bill.paidDate,
          isRecurring: bill.isRecurring,
        ),
      );
    }

    return reminders;
  }

  // Convert Credit Cards to BillReminders
  List<BillReminder> _getRemindersFromCreditCards(DateTime month) {
    final accounts = HiveService.getAllPaymentAccounts();
    final expenses = HiveService.getAllExpenses();
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    if (kDebugMode) {
      print('💳 Total accounts: ${accounts.length}');
      for (var acc in accounts) {
        print(
            '  Account: ${acc.name}, type: ${acc.accountType}, active: ${acc.isActive}, balance: ${acc.balance}');
      }
    }

    final creditCards = accounts.where((account) {
      final type = account.accountType.toLowerCase();
      final isCreditCard = type.contains('credit') || type.contains('card');
      final isActive = account.isActive;

      if (kDebugMode) {
        print(
            '  Checking: ${account.name} - isCreditCard: $isCreditCard, active: $isActive');
      }

      return isCreditCard && isActive;
    });

    if (kDebugMode) {
      print('💳 Filtered credit cards: ${creditCards.length}');
    }

    final List<BillReminder> reminders = [];
    for (var card in creditCards) {
      final monthDueDate = _resolveCardDueDateForMonth(card, month);
      if (monthDueDate == null) {
        continue;
      }

      final previousCycleDueDate =
          _calculateCardDueDate(monthDueDate, card.billingCycleDay, -1);
      final cycleStart = previousCycleDueDate.add(const Duration(days: 1));

      final cardPayments = expenses.where((e) {
        final type = e.transactionType ?? 'expense';
        final isPaymentLike = type == 'transfer' || type == 'payment';
        final cardMatch = e.destinationAccountId == card.id ||
            e.title.contains('Credit Card Payment - ${card.name}');
        return isPaymentLike &&
            cardMatch &&
            _isWithinInclusiveRange(e.date, cycleStart, monthDueDate);
      }).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      final hasPayment = cardPayments.isNotEmpty;
      final paidDate = hasPayment ? cardPayments.last.date : null;

      if (kDebugMode) {
        print(
            '  ${card.name} due: $monthDueDate, balance: ${card.balance}, hasPayment: $hasPayment');
      }

      BillReminderStatus status;
      if (hasPayment || card.balance <= 0) {
        status = BillReminderStatus.completed;
      } else if (DateTime(
              monthDueDate.year, monthDueDate.month, monthDueDate.day)
          .isBefore(startOfToday)) {
        status = BillReminderStatus.overdue;
      } else {
        status = BillReminderStatus.pending;
      }

      final reminderAmount = card.balance > 0
          ? card.balance
          : (hasPayment ? cardPayments.last.amount : 0.0);

      reminders.add(BillReminder(
        id: 'card_${card.id}_${month.year}_${month.month}',
        sourceId: card.id,
        name: 'Credit Card Payment - ${card.name}',
        amount: reminderAmount,
        dueDate: monthDueDate,
        currency: card.currency,
        type: BillReminderType.creditCard,
        status: status,
        paidDate: paidDate,
        accountName: card.name,
        notes: card.dueDate == null && card.billingCycleDay == null
            ? 'Credit card bill payment (set due date for accurate reminder)'
            : card.statementDate != null
                ? 'Statement date: ${card.statementDate!.day}/${card.statementDate!.month}/${card.statementDate!.year}'
                : 'Credit card bill payment',
      ));
    }

    return reminders;
  }

  // Convert Loans to BillReminders
  List<BillReminder> _getRemindersFromLoans(DateTime month) {
    final loans = HiveService.getAllLoans();
    final expenses = HiveService.getAllExpenses();
    final monthStart = _startOfMonth(month);
    final monthEnd = _endOfMonth(month);

    final List<BillReminder> reminders = [];
    for (var loan in loans) {
      if (loan.startDate.isAfter(monthEnd)) {
        continue;
      }

      final outstandingAmount =
          (loan.borrowedAmount - loan.paidAmount).clamp(0.0, double.infinity);
      final hasOutstanding = outstandingAmount > 0.01;

      final emiDueDate = _safeDayInMonth(month.year, month.month, loan.emiDate);
      final lastPaymentInMonth = loan.lastPaymentDate != null &&
          _isSameMonth(loan.lastPaymentDate!, month);
      final paymentFromExpenses = expenses.where((e) {
        final type = e.transactionType ?? 'expense';
        final isPaymentLike = type == 'payment' || type == 'transfer';
        final matchesLoan =
            e.title.contains('Loan EMI Payment - ${loan.lender}');
        return isPaymentLike &&
            matchesLoan &&
            _isWithinInclusiveRange(e.date, monthStart, monthEnd);
      }).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      final paidDate = lastPaymentInMonth
          ? loan.lastPaymentDate
          : (paymentFromExpenses.isNotEmpty
              ? paymentFromExpenses.last.date
              : null);
      final isPaidForMonth = paidDate != null && _isSameMonth(paidDate, month);

      if (!hasOutstanding && !isPaidForMonth) {
        continue;
      }

      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      BillReminderStatus status;

      if (kDebugMode) {
        print('🏦 Loan: ${loan.lender} (${loan.id})');
        print('  EMI Day: ${loan.emiDate}');
        print('  EMI Due In Month: $emiDueDate');
        print('  Last Payment Date: ${loan.lastPaymentDate}');
        print('  Payment Found In Month: $isPaidForMonth');
      }

      if (isPaidForMonth) {
        status = BillReminderStatus.completed;
      } else if (emiDueDate.isBefore(startOfToday)) {
        status = BillReminderStatus.overdue;
      } else {
        status = BillReminderStatus.pending;
      }

      final reminderAmount = hasOutstanding
          ? (outstandingAmount < loan.monthlyEmi
              ? outstandingAmount
              : loan.monthlyEmi)
          : loan.monthlyEmi;

      reminders.add(BillReminder(
        id: 'loan_${loan.id}_${month.year}_${month.month}',
        sourceId: loan.id,
        name: 'Loan EMI - ${loan.lender}',
        amount: reminderAmount,
        dueDate: emiDueDate,
        currency: loan.currency,
        type: BillReminderType.loan,
        status: status,
        paidDate: isPaidForMonth ? paidDate : null,
        lender: loan.lender,
        notes: 'Monthly EMI payment',
      ));
    }

    return reminders;
  }

  // Convert Subscriptions to BillReminders
  List<BillReminder> _getRemindersFromSubscriptions(DateTime month) {
    final subscriptions = HiveService.getAllSubscriptions();
    final expenses = HiveService.getAllExpenses();
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    if (kDebugMode) {
      print('📱 Total subscriptions: ${subscriptions.length}');
    }

    final List<BillReminder> reminders = [];

    for (final subscription in subscriptions) {
      final dueDate = _resolveSubscriptionDueDateForMonth(subscription, month);
      if (dueDate == null) {
        continue;
      }

      final previousDueDate =
          _subtractBillingCycle(dueDate, subscription.billingCycle);
      final periodStart = previousDueDate.add(const Duration(days: 1));
      final paymentWindowEnd =
          _isSameMonth(month, now) && dueDate.isBefore(now) ? now : dueDate;
      final periodPayments = expenses.where((expense) {
        final type = expense.transactionType ?? 'expense';
        final isPaymentLike =
            type == 'expense' || type == 'payment' || type == 'transfer';
        final matchesSubscription = expense.title
            .contains('Subscription Payment - ${subscription.name}');
        return isPaymentLike &&
            matchesSubscription &&
            _isWithinInclusiveRange(
                expense.date, periodStart, paymentWindowEnd);
      }).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      final currentPeriodPaid = periodPayments.isNotEmpty;
      final paidDate = currentPeriodPaid ? periodPayments.last.date : null;

      BillReminderStatus status;
      if (currentPeriodPaid) {
        status = BillReminderStatus.completed;
      } else if (DateTime(dueDate.year, dueDate.month, dueDate.day)
          .isBefore(startOfToday)) {
        status = BillReminderStatus.overdue;
      } else {
        status = BillReminderStatus.pending;
      }

      if (kDebugMode) {
        print('  Creating reminder for ${subscription.name}: status=$status, '
            'currentPeriodPaid=$currentPeriodPaid, dueDate=$dueDate, '
            'periodStart=$periodStart, expenseCount=${periodPayments.length}');
      }

      reminders.add(
        BillReminder(
          id: 'subscription_${subscription.id}_${month.year}_${month.month}',
          sourceId: subscription.id,
          name: 'Subscription - ${subscription.name}',
          amount: subscription.cost,
          dueDate: dueDate,
          currency: subscription.currency,
          type: BillReminderType.subscription,
          status: status,
          paidDate: paidDate,
          notes: subscription.notes,
          billingCycle: subscription.billingCycle,
        ),
      );
    }

    return reminders;
  }

  DateTime _calculateCardDueDate(
    DateTime anchor,
    int? billingCycleDay,
    int monthOffset,
  ) {
    final targetMonth = DateTime(anchor.year, anchor.month + monthOffset, 1);

    if (billingCycleDay == null) {
      return DateTime(targetMonth.year, targetMonth.month, 5);
    }

    return _safeDayInMonth(
      targetMonth.year,
      targetMonth.month,
      billingCycleDay,
    );
  }

  DateTime _addBillingCycle(DateTime date, String billingCycle) {
    switch (billingCycle.toLowerCase()) {
      case 'weekly':
        return date.add(const Duration(days: 7));
      case 'monthly':
        return _safeDayInMonth(date.year, date.month + 1, date.day);
      case 'quarterly':
        return _safeDayInMonth(date.year, date.month + 3, date.day);
      case 'yearly':
      case 'annual':
        return _safeDayInMonth(date.year + 1, date.month, date.day);
      default:
        return _safeDayInMonth(date.year, date.month + 1, date.day);
    }
  }

  DateTime _subtractBillingCycle(DateTime date, String billingCycle) {
    switch (billingCycle.toLowerCase()) {
      case 'weekly':
        return date.subtract(const Duration(days: 7));
      case 'monthly':
        return _safeDayInMonth(date.year, date.month - 1, date.day);
      case 'quarterly':
        return _safeDayInMonth(date.year, date.month - 3, date.day);
      case 'yearly':
      case 'annual':
        return _safeDayInMonth(date.year - 1, date.month, date.day);
      default:
        return _safeDayInMonth(date.year, date.month - 1, date.day);
    }
  }

  DateTime _startOfMonth(DateTime month) =>
      DateTime(month.year, month.month, 1);

  DateTime _endOfMonth(DateTime month) =>
      DateTime(month.year, month.month + 1, 0, 23, 59, 59, 999);

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  bool _isWithinInclusiveRange(DateTime value, DateTime start, DateTime end) {
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
    return !value.isBefore(startDay) && !value.isAfter(endDay);
  }

  DateTime _safeDayInMonth(int year, int month, int day) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(firstDay.year, firstDay.month + 1, 0).day;
    final clampedDay = day.clamp(1, lastDay);
    return DateTime(firstDay.year, firstDay.month, clampedDay);
  }

  DateTime? _resolveBillDueDateForMonth(Bill bill, DateTime month) {
    final monthStart = _startOfMonth(month);
    final monthEnd = _endOfMonth(month);

    if (!bill.isRecurring) {
      return _isSameMonth(bill.dueDate, month) ? bill.dueDate : null;
    }

    DateTime dueDate = bill.dueDate;
    if (dueDate.isAfter(monthEnd)) {
      return null;
    }

    int safetyCounter = 0;
    while (dueDate.isBefore(monthStart) && safetyCounter < 240) {
      dueDate = _addBillingCycle(dueDate, bill.recurringFrequency ?? 'monthly');
      safetyCounter++;
    }

    return _isSameMonth(dueDate, month) ? dueDate : null;
  }

  DateTime? _resolveCardDueDateForMonth(dynamic card, DateTime month) {
    final monthEnd = _endOfMonth(month);
    if (card.createdAt != null &&
        monthEnd.isBefore(card.createdAt as DateTime)) {
      return null;
    }

    final day = card.dueDate?.day ??
        card.billingCycleDay ??
        card.nextBillingDate?.day ??
        5;
    return _safeDayInMonth(month.year, month.month, day);
  }

  DateTime? _resolveSubscriptionDueDateForMonth(
    Subscription subscription,
    DateTime month,
  ) {
    if (!subscription.autoRenewal) {
      return _isSameMonth(subscription.renewalDate, month)
          ? subscription.renewalDate
          : null;
    }

    final monthStart = _startOfMonth(month);
    final monthEnd = _endOfMonth(month);
    DateTime dueDate = subscription.renewalDate;

    if (dueDate.isAfter(monthEnd)) {
      return null;
    }

    int safetyCounter = 0;
    while (dueDate.isBefore(monthStart) && safetyCounter < 240) {
      dueDate = _addBillingCycle(dueDate, subscription.billingCycle);
      safetyCounter++;
    }

    return _isSameMonth(dueDate, month) ? dueDate : null;
  }
}
