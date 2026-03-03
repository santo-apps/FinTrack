/// Unified model to represent all types of payment reminders
/// from bills, credit cards, loans, and subscriptions
class BillReminder {
  final String id;
  final String name;
  final double amount;
  final DateTime dueDate;
  final String currency;
  final BillReminderType type;
  final BillReminderStatus status;
  final String? notes;
  final DateTime? paidDate;
  final String
      sourceId; // Original ID from source (bill/loan/subscription/account)

  // Additional metadata based on type
  final String? accountName; // For credit cards
  final String? lender; // For loans
  final bool? isRecurring; // For bills
  final String? billingCycle; // For subscriptions

  BillReminder({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.currency,
    required this.type,
    required this.status,
    required this.sourceId,
    this.notes,
    this.paidDate,
    this.accountName,
    this.lender,
    this.isRecurring,
    this.billingCycle,
  });

  bool isOverdue() {
    return status == BillReminderStatus.overdue;
  }

  int getDaysUntilDue() {
    return dueDate.difference(DateTime.now()).inDays;
  }

  String getTypeLabel() {
    switch (type) {
      case BillReminderType.bill:
        return 'Bill';
      case BillReminderType.creditCard:
        return 'Credit Card';
      case BillReminderType.loan:
        return 'Loan EMI';
      case BillReminderType.subscription:
        return 'Subscription';
    }
  }

  String getStatusLabel() {
    switch (status) {
      case BillReminderStatus.overdue:
        return 'OVERDUE';
      case BillReminderStatus.pending:
        return 'PENDING';
      case BillReminderStatus.completed:
        return 'PAID';
    }
  }
}

enum BillReminderType {
  bill,
  creditCard,
  loan,
  subscription,
}

enum BillReminderStatus {
  overdue,
  pending,
  completed,
}
