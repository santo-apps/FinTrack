import 'package:hive/hive.dart';

part 'receivable_model.g.dart';

@HiveType(typeId: 14)
class Receivable extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  double amount;

  @HiveField(3)
  DateTime dueDate;

  @HiveField(4)
  String currency;

  @HiveField(5)
  bool isReceived;

  @HiveField(6)
  DateTime? receivedDate;

  @HiveField(7)
  int remindBeforeDays;

  @HiveField(8)
  String? notes;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  String? accountId;

  @HiveField(11)
  bool isRecurring;

  @HiveField(12)
  DateTime? recurringEndDate;

  @HiveField(13)
  String? recurrenceGroupId;

  Receivable({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    this.currency = 'USD',
    this.isReceived = false,
    this.receivedDate,
    this.remindBeforeDays = 3,
    this.notes,
    required this.createdAt,
    this.accountId,
    this.isRecurring = false,
    this.recurringEndDate,
    this.recurrenceGroupId,
  });

  Receivable copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? dueDate,
    String? currency,
    bool? isReceived,
    DateTime? receivedDate,
    int? remindBeforeDays,
    String? notes,
    DateTime? createdAt,
    String? accountId,
    bool? isRecurring,
    DateTime? recurringEndDate,
    String? recurrenceGroupId,
  }) {
    return Receivable(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      currency: currency ?? this.currency,
      isReceived: isReceived ?? this.isReceived,
      receivedDate: receivedDate ?? this.receivedDate,
      remindBeforeDays: remindBeforeDays ?? this.remindBeforeDays,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      accountId: accountId ?? this.accountId,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringEndDate: recurringEndDate ?? this.recurringEndDate,
      recurrenceGroupId: recurrenceGroupId ?? this.recurrenceGroupId,
    );
  }

  bool get isOverdue {
    if (isReceived) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return dueDay.isBefore(today);
  }

  bool get isInReminderWindow {
    if (isReceived) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final reminderDate = dueDay.subtract(Duration(days: remindBeforeDays));
    return !today.isBefore(reminderDate) && !today.isAfter(dueDay);
  }
}
