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
      debugPrint('🗓️ Month: ${selectedMonth.year}-${selectedMonth.month}');
      debugPrint('📝 Bills: ${billReminders.length} reminders');
      debugPrint('💳 Credit Cards: ${cardReminders.length} reminders');
      debugPrint('🏦 Loans: ${loanReminders.length} reminders');
      debugPrint('📱 Subscriptions: ${subscriptionReminders.length} reminders');
      debugPrint('📊 Total reminders: ${allReminders.length}');
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
        .where((r) =>
            r.status == BillReminderStatus.pending ||
            r.status == BillReminderStatus.partiallyPaid)
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
      final BillReminderStatus status;
      if (bill.isPaid) {
        status = BillReminderStatus.completed;
      } else if (bill.isPartiallyPaid()) {
        status = BillReminderStatus.partiallyPaid;
      } else if (DateTime(
              effectiveDate.year, effectiveDate.month, effectiveDate.day)
          .isBefore(today)) {
        status = BillReminderStatus.overdue;
      } else {
        status = BillReminderStatus.pending;
      }

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
          paidAmount: bill.paidAmount,
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
      debugPrint('💳 Total accounts: ${accounts.length}');
      for (var acc in accounts) {
        debugPrint(
            '  Account: ${acc.name}, type: ${acc.accountType}, active: ${acc.isActive}, balance: ${acc.balance}');
      }
    }

    final creditCards = accounts.where((account) {
      final type = account.accountType.toLowerCase();
      final isCreditCard = type.contains('credit') || type.contains('card');
      final isActive = account.isActive;

      if (kDebugMode) {
        debugPrint(
            '  Checking: ${account.name} - isCreditCard: $isCreditCard, active: $isActive');
      }

      return isCreditCard && isActive;
    });

    if (kDebugMode) {
      debugPrint('💳 Filtered credit cards: ${creditCards.length}');
    }

    final List<BillReminder> reminders = [];
    for (var card in creditCards) {
      final monthDueDate = _resolveCardDueDateForMonth(card, month);
      if (monthDueDate == null) {
        continue;
      }

      final statementDay =
          card.statementDate?.day ?? card.billingCycleDay ?? 15;
      final cycleEnd = _resolveCycleEndForDueDate(monthDueDate, statementDay);
      final previousCycleEnd =
          _safeDayInMonth(cycleEnd.year, cycleEnd.month - 1, statementDay);
      final cycleStart = previousCycleEnd.add(const Duration(days: 1));

      final statementCharges = expenses.where((e) {
        final type = e.transactionType ?? 'expense';
        final isCharge = type == 'expense' &&
            e.accountId == card.id &&
            !e.title.contains('Credit Card Payment - ${card.name}');
        final isRefund = type == 'income' && e.accountId == card.id;
        if (!(isCharge || isRefund)) {
          return false;
        }
        return _isWithinInclusiveRange(e.date, cycleStart, cycleEnd);
      }).toList();

      final statementAmount = statementCharges.fold<double>(0, (sum, e) {
        final type = e.transactionType ?? 'expense';
        if (type == 'income') {
          return sum - e.amount;
        }
        return sum + e.amount;
      }).clamp(0.0, double.infinity);

      final accountOutstanding = (card.balance as num)
          .toDouble()
          .clamp(0.0, double.infinity)
          .toDouble();
      final billedAmount =
          accountOutstanding > 0.0 ? accountOutstanding : statementAmount;

      final paymentWindowStart = cycleEnd.add(const Duration(days: 1));
      final cardPayments = expenses.where((e) {
        final type = e.transactionType ?? 'expense';
        final isPaymentLike = type == 'transfer' || type == 'payment';
        final cardMatch = e.destinationAccountId == card.id ||
            e.title.contains('Credit Card Payment - ${card.name}');
        return isPaymentLike &&
            cardMatch &&
            _isWithinInclusiveRange(e.date, paymentWindowStart, monthDueDate);
      }).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      final paidAmount =
          cardPayments.fold<double>(0, (sum, payment) => sum + payment.amount);
      final hasPayment = paidAmount > 0.0;
      final paidDate = hasPayment ? cardPayments.last.date : null;

      if (kDebugMode) {
        debugPrint(
            '  ${card.name} due: $monthDueDate, balance: ${card.balance}, hasPayment: $hasPayment');
      }

      BillReminderStatus status;
      if (billedAmount <= 0.0 || paidAmount >= billedAmount) {
        status = BillReminderStatus.completed;
      } else if (paidAmount > 0.0) {
        status = BillReminderStatus.partiallyPaid;
      } else if (DateTime(
              monthDueDate.year, monthDueDate.month, monthDueDate.day)
          .isBefore(startOfToday)) {
        status = BillReminderStatus.overdue;
      } else {
        status = BillReminderStatus.pending;
      }

      final reminderAmount = billedAmount;

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
        paidAmount: paidAmount,
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

  DateTime _resolveCycleEndForDueDate(DateTime dueDate, int statementDay) {
    final statementThisMonth =
        _safeDayInMonth(dueDate.year, dueDate.month, statementDay);

    if (statementThisMonth.isBefore(dueDate)) {
      return statementThisMonth;
    }

    return _safeDayInMonth(dueDate.year, dueDate.month - 1, statementDay);
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

      final firstEmiThisMonth = _safeDayInMonth(
          loan.startDate.year, loan.startDate.month, loan.emiDate);
      final firstDueDate = loan.startDate.isAfter(firstEmiThisMonth)
          ? _safeDayInMonth(
              loan.startDate.year, loan.startDate.month + 1, loan.emiDate)
          : firstEmiThisMonth;

      final outstandingAmount =
          (loan.borrowedAmount - loan.paidAmount).clamp(0.0, double.infinity);
      final hasOutstanding = outstandingAmount > 0.01;

      final emiDueDate = _safeDayInMonth(month.year, month.month, loan.emiDate);
      if (emiDueDate.isBefore(firstDueDate)) {
        continue;
      }
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
        debugPrint('🏦 Loan: ${loan.lender} (${loan.id})');
        debugPrint('  EMI Day: ${loan.emiDate}');
        debugPrint('  EMI Due In Month: $emiDueDate');
        debugPrint('  Last Payment Date: ${loan.lastPaymentDate}');
        debugPrint('  Payment Found In Month: $isPaidForMonth');
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
      debugPrint('📱 Total subscriptions: ${subscriptions.length}');
    }

    final List<BillReminder> reminders = [];

    for (final subscription in subscriptions) {
      final dueDate = _resolveSubscriptionDueDateForMonth(subscription, month);
      if (dueDate == null) {
        continue;
      }

      if (subscription.isArchived &&
          subscription.archivedAt != null &&
          dueDate.isAfter(subscription.archivedAt!)) {
        // Keep historical reminders visible, but suppress future dues after archive.
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

      // Only treat already-executed payments as paid. Planned/future entries
      // should not move reminders to Completed.
      final executedPayments = periodPayments
          .where((expense) =>
              !expense.date.isAfter(now) && _isSameMonth(expense.date, month))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      final currentPeriodPaid = executedPayments.isNotEmpty;
      final paidDate = currentPeriodPaid ? executedPayments.last.date : null;
      final paidAmount = executedPayments.fold<double>(
        0,
        (sum, payment) => sum + payment.amount,
      );

      final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
      BillReminderStatus status;
      if (paidAmount >= subscription.cost && paidAmount > 0.0) {
        status = BillReminderStatus.completed;
      } else if (paidAmount > 0.0) {
        status = BillReminderStatus.partiallyPaid;
      } else if (dueDay.isBefore(startOfToday)) {
        status = BillReminderStatus.overdue;
      } else {
        status = BillReminderStatus.pending;
      }

      if (kDebugMode) {
        debugPrint(
            '  Creating reminder for ${subscription.name}: status=$status, '
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
          paidAmount: paidAmount,
          notes: subscription.notes,
          billingCycle: subscription.billingCycle,
        ),
      );
    }

    return reminders;
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
