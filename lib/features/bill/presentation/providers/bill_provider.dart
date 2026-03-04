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
    final List<BillReminder> allReminders = [];

    // Add manual bills
    final billReminders = _getRemindersFromBills();
    allReminders.addAll(billReminders);
    if (kDebugMode) {
      print('📝 Bills: ${billReminders.length} reminders');
    }

    // Add credit card payments
    final cardReminders = _getRemindersFromCreditCards();
    allReminders.addAll(cardReminders);
    if (kDebugMode) {
      print('💳 Credit Cards: ${cardReminders.length} reminders');
      for (var reminder in cardReminders) {
        print('  - ${reminder.name}: ${reminder.dueDate} (${reminder.status})');
      }
    }

    // Add loan EMI payments
    final loanReminders = _getRemindersFromLoans();
    allReminders.addAll(loanReminders);
    if (kDebugMode) {
      print('🏦 Loans: ${loanReminders.length} reminders');
    }

    // Add subscription renewals
    final subscriptionReminders = _getRemindersFromSubscriptions();
    allReminders.addAll(subscriptionReminders);
    if (kDebugMode) {
      print('📱 Subscriptions: ${subscriptionReminders.length} reminders');
      for (var reminder in subscriptionReminders) {
        print('  - ${reminder.name}: ${reminder.dueDate} (${reminder.status})');
      }
    }

    if (kDebugMode) {
      print('📊 Total reminders: ${allReminders.length}');
    }

    // Sort by due date
    allReminders.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return allReminders;
  }

  /// Get reminders filtered by month
  List<BillReminder> getRemindersForMonth(DateTime month) {
    final allReminders = getAllReminders();

    if (kDebugMode) {
      print('🗓️ Filtering for month: ${month.year}-${month.month}');
      print('🗓️ All reminders before filtering: ${allReminders.length}');
    }

    final filtered = allReminders.where((reminder) {
      // Match by due date month for all reminders
      final matches = reminder.dueDate.year == month.year &&
          reminder.dueDate.month == month.month;

      if (kDebugMode && !matches) {
        print('  ❌ Filtered out: ${reminder.name} (${reminder.dueDate})');
      }
      if (kDebugMode && matches) {
        print('  ✅ Including: ${reminder.name} (${reminder.dueDate})');
      }

      return matches;
    }).toList();

    if (kDebugMode) {
      print('🗓️ Reminders after filtering: ${filtered.length}');
    }

    return filtered;
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
  List<BillReminder> _getRemindersFromBills() {
    return _bills.map((bill) {
      BillReminderStatus status;
      if (bill.isPaid) {
        status = BillReminderStatus.completed;
      } else if (bill.isOverdue()) {
        status = BillReminderStatus.overdue;
      } else {
        status = BillReminderStatus.pending;
      }

      return BillReminder(
        id: 'bill_${bill.id}',
        sourceId: bill.id,
        name: bill.name,
        amount: bill.amount,
        dueDate: bill.dueDate,
        currency: bill.currency,
        type: BillReminderType.bill,
        status: status,
        notes: bill.notes,
        paidDate: bill.paidDate,
        isRecurring: bill.isRecurring,
      );
    }).toList();
  }

  // Convert Credit Cards to BillReminders
  List<BillReminder> _getRemindersFromCreditCards() {
    final accounts = HiveService.getAllPaymentAccounts();
    final now = DateTime.now();

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
      final nextBillingDate = card.nextBillingDate ??
          _calculateCardDueDate(now, card.billingCycleDay);
      if (kDebugMode) {
        print(
            '  ${card.name} next billing: $nextBillingDate, balance: ${card.balance}');
      }

      // Determine status - check balance FIRST, then date
      BillReminderStatus status;
      if (card.balance <= 0) {
        // Balance is paid off - mark as completed
        status = BillReminderStatus.completed;
      } else if (nextBillingDate.isBefore(now)) {
        // Has balance and date has passed - overdue
        status = BillReminderStatus.overdue;
      } else {
        // Has balance and date is upcoming - pending
        status = BillReminderStatus.pending;
      }

      reminders.add(BillReminder(
        id: 'card_${card.id}_${nextBillingDate.toString()}',
        sourceId: card.id,
        name: 'Credit Card Payment - ${card.name}',
        amount: card.balance > 0 ? card.balance : 0,
        dueDate: nextBillingDate,
        currency: card.currency,
        type: BillReminderType.creditCard,
        status: status,
        accountName: card.name,
        notes: card.billingCycleDay == null
            ? 'Credit card bill payment (set billing cycle day for accurate due date)'
            : 'Credit card bill payment',
      ));
    }

    return reminders;
  }

  // Convert Loans to BillReminders
  List<BillReminder> _getRemindersFromLoans() {
    final loans = HiveService.getAllLoans();
    final activeLoans = loans.where((loan) => !loan.isCompleted);

    final List<BillReminder> reminders = [];
    for (var loan in activeLoans) {
      final nextEmiDate = loan.nextEmiDate;
      if (nextEmiDate == null) continue;

      BillReminderStatus status;
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);
      final emiDueThisMonth = DateTime(now.year, now.month, loan.emiDate);

      // Check if payment was made this month
      final lastPayment = loan.lastPaymentDate;
      final isPaidThisMonth = lastPayment != null &&
          lastPayment.year == currentMonth.year &&
          lastPayment.month == currentMonth.month;

      if (kDebugMode) {
        print('🏦 Loan: ${loan.lender} (${loan.id})');
        print('  EMI Day: ${loan.emiDate}');
        print('  EMI Due This Month: $emiDueThisMonth');
        print('  Next EMI Date: $nextEmiDate');
        print('  Last Payment Date: $lastPayment');
        print('  Is Paid This Month: $isPaidThisMonth');
      }

      if (isPaidThisMonth) {
        // Payment made for this month's EMI
        status = BillReminderStatus.completed;
        if (kDebugMode) {
          print('  Status: COMPLETED ✅');
        }
      } else if (emiDueThisMonth.isBefore(now)) {
        // EMI was due this month but hasn't been paid yet
        status = BillReminderStatus.overdue;
        if (kDebugMode) {
          print('  Status: OVERDUE ⚠️');
        }
      } else {
        // EMI is upcoming this month
        status = BillReminderStatus.pending;
        if (kDebugMode) {
          print('  Status: PENDING ⏳');
        }
      }

      reminders.add(BillReminder(
        id: 'loan_${loan.id}_${emiDueThisMonth.toString()}',
        sourceId: loan.id,
        name: 'Loan EMI - ${loan.lender}',
        amount: loan.monthlyEmi,
        dueDate: emiDueThisMonth, // Use current month's EMI date
        currency: loan.currency,
        type: BillReminderType.loan,
        status: status,
        lender: loan.lender,
        notes: 'Monthly EMI payment',
      ));
    }

    return reminders;
  }

  // Convert Subscriptions to BillReminders
  List<BillReminder> _getRemindersFromSubscriptions() {
    final subscriptions = HiveService.getAllSubscriptions();

    if (kDebugMode) {
      print('📱 Total subscriptions: ${subscriptions.length}');
    }

    final activeSubscriptions = subscriptions.where((sub) {
      if (kDebugMode) {
        print(
            '  ${sub.name}: autoRenewal=${sub.autoRenewal}, renewalDate=${sub.renewalDate}');
      }
      return true;
    });

    if (kDebugMode) {
      print(
          '📱 Subscriptions considered for reminders: ${activeSubscriptions.length}');
    }

    return activeSubscriptions.map((subscription) {
      BillReminderStatus status;
      final now = DateTime.now();
      final effectiveDueDate = _getEffectiveSubscriptionDueDate(subscription);

      // Check if renewal date has passed
      if (effectiveDueDate.isBefore(now)) {
        status = BillReminderStatus.overdue;
      } else {
        status = BillReminderStatus.pending;
      }

      if (kDebugMode) {
        print('  Creating reminder for ${subscription.name}: status=$status');
      }

      return BillReminder(
        id: 'subscription_${subscription.id}',
        sourceId: subscription.id,
        name: 'Subscription - ${subscription.name}',
        amount: subscription.cost,
        dueDate: effectiveDueDate,
        currency: subscription.currency,
        type: BillReminderType.subscription,
        status: status,
        notes: subscription.notes,
        billingCycle: subscription.billingCycle,
      );
    }).toList();
  }

  DateTime _calculateCardDueDate(DateTime now, int? billingCycleDay) {
    // If no billing cycle day is set, default to the 5th of next month
    if (billingCycleDay == null) {
      return DateTime(now.year, now.month + 1, 5);
    }

    // Helper to get the last day of a month
    int getLastDayOfMonth(int year, int month) {
      if (month == 12) {
        return DateTime(year + 1, 1, 0).day;
      } else {
        return DateTime(year, month + 1, 0).day;
      }
    }

    // Clamp billing day to valid range for current month
    int daysInCurrentMonth = getLastDayOfMonth(now.year, now.month);
    int validBillingDay = billingCycleDay > daysInCurrentMonth
        ? daysInCurrentMonth
        : billingCycleDay;

    final currentMonthDueDate = DateTime(now.year, now.month, validBillingDay);

    // If the due date hasn't passed this month, use it
    if (currentMonthDueDate.isAfter(now) ||
        currentMonthDueDate.isAtSameMomentAs(now)) {
      return currentMonthDueDate;
    }

    // Otherwise, use the billing day in the next month
    int nextMonth = now.month == 12 ? 1 : now.month + 1;
    int nextYear = now.month == 12 ? now.year + 1 : now.year;
    int daysInNextMonth = getLastDayOfMonth(nextYear, nextMonth);
    int validNextBillingDay =
        billingCycleDay > daysInNextMonth ? daysInNextMonth : billingCycleDay;

    return DateTime(nextYear, nextMonth, validNextBillingDay);
  }

  DateTime _getFallbackCardDueDate(DateTime now) {
    return DateTime(now.year, now.month, now.day + 1);
  }

  DateTime _getEffectiveSubscriptionDueDate(Subscription subscription) {
    if (!subscription.autoRenewal) {
      return subscription.renewalDate;
    }

    DateTime dueDate = subscription.renewalDate;
    final now = DateTime.now();
    int safetyCounter = 0;

    while (dueDate.isBefore(DateTime(now.year, now.month, now.day)) &&
        safetyCounter < 240) {
      dueDate = _addBillingCycle(dueDate, subscription.billingCycle);
      safetyCounter++;
    }

    return dueDate;
  }

  DateTime _addBillingCycle(DateTime date, String billingCycle) {
    switch (billingCycle.toLowerCase()) {
      case 'weekly':
        return date.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(date.year, date.month + 1, date.day);
      case 'quarterly':
        return DateTime(date.year, date.month + 3, date.day);
      case 'yearly':
      case 'annual':
        return DateTime(date.year + 1, date.month, date.day);
      default:
        return DateTime(date.year, date.month + 1, date.day);
    }
  }
}
