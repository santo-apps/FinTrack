import 'package:hive/hive.dart';

part 'receivable_model.g.dart';

@HiveType(typeId: 14)
class Receivable extends HiveObject {
  static const Object _unset = Object();

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

  @HiveField(14)
  double receivedAmount;

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
    this.receivedAmount = 0,
  });

  Receivable copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? dueDate,
    String? currency,
    bool? isReceived,
    Object? receivedDate = _unset,
    int? remindBeforeDays,
    Object? notes = _unset,
    DateTime? createdAt,
    Object? accountId = _unset,
    bool? isRecurring,
    Object? recurringEndDate = _unset,
    Object? recurrenceGroupId = _unset,
    double? receivedAmount,
  }) {
    return Receivable(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      currency: currency ?? this.currency,
      isReceived: isReceived ?? this.isReceived,
      receivedDate: receivedDate == _unset
          ? this.receivedDate
          : receivedDate as DateTime?,
      remindBeforeDays: remindBeforeDays ?? this.remindBeforeDays,
      notes: notes == _unset ? this.notes : notes as String?,
      createdAt: createdAt ?? this.createdAt,
      accountId: accountId == _unset ? this.accountId : accountId as String?,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringEndDate: recurringEndDate == _unset
          ? this.recurringEndDate
          : recurringEndDate as DateTime?,
      recurrenceGroupId: recurrenceGroupId == _unset
          ? this.recurrenceGroupId
          : recurrenceGroupId as String?,
      receivedAmount: receivedAmount ?? this.receivedAmount,
    );
  }

  double get outstandingAmount {
    final remaining = amount - receivedAmount;
    if (remaining <= 0.000001) return 0;
    return (remaining * 100).roundToDouble() / 100;
  }

  bool get isPartiallyReceived {
    return receivedAmount > 0 && receivedAmount < amount;
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'currency': currency,
      'isReceived': isReceived,
      'receivedDate': receivedDate?.toIso8601String(),
      'remindBeforeDays': remindBeforeDays,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'accountId': accountId,
      'isRecurring': isRecurring,
      'recurringEndDate': recurringEndDate?.toIso8601String(),
      'recurrenceGroupId': recurrenceGroupId,
      'receivedAmount': receivedAmount,
    };
  }

  static Receivable fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value, DateTime fallback) {
      if (value is DateTime) {
        return value;
      }
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value) ?? fallback;
      }
      return fallback;
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value is DateTime) {
        return value;
      }
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    final now = DateTime.now();

    return Receivable(
      id: json['id']?.toString() ?? now.microsecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      dueDate: parseDate(json['dueDate'], now),
      currency: json['currency']?.toString() ?? 'USD',
      isReceived: json['isReceived'] == true,
      receivedDate: parseNullableDate(json['receivedDate']),
      remindBeforeDays: (json['remindBeforeDays'] as num?)?.toInt() ?? 3,
      notes: json['notes']?.toString(),
      createdAt: parseDate(json['createdAt'], now),
      accountId: json['accountId']?.toString(),
      isRecurring: json['isRecurring'] == true,
      recurringEndDate: parseNullableDate(json['recurringEndDate']),
      recurrenceGroupId: json['recurrenceGroupId']?.toString(),
      receivedAmount: (json['receivedAmount'] as num?)?.toDouble() ??
          (json['isReceived'] == true
              ? (json['amount'] as num?)?.toDouble() ?? 0
              : 0),
    );
  }
}
