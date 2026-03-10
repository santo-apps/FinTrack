import 'package:hive/hive.dart';

part 'bill_model.g.dart';

@HiveType(typeId: 4)
class Bill extends HiveObject {
  static const Object _unset = Object();

  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double amount;

  @HiveField(3)
  DateTime dueDate;

  @HiveField(4)
  bool isPaid;

  @HiveField(5)
  bool isRecurring;

  @HiveField(6)
  String? recurringFrequency;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  String currency;

  @HiveField(9)
  String? notes;

  @HiveField(10)
  DateTime? paidDate;

  Bill({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
    this.isRecurring = false,
    this.recurringFrequency,
    required this.createdAt,
    this.currency = 'USD',
    this.notes,
    this.paidDate,
  });

  Bill copyWith({
    String? id,
    String? name,
    double? amount,
    DateTime? dueDate,
    bool? isPaid,
    bool? isRecurring,
    Object? recurringFrequency = _unset,
    DateTime? createdAt,
    String? currency,
    Object? notes = _unset,
    Object? paidDate = _unset,
  }) {
    return Bill(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringFrequency: recurringFrequency == _unset
          ? this.recurringFrequency
          : recurringFrequency as String?,
      createdAt: createdAt ?? this.createdAt,
      currency: currency ?? this.currency,
      notes: notes == _unset ? this.notes : notes as String?,
      paidDate: paidDate == _unset ? this.paidDate : paidDate as DateTime?,
    );
  }

  bool isOverdue() {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return !isPaid && dueDay.isBefore(startOfToday);
  }

  int getDaysUntilDue() {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return dueDay.difference(startOfToday).inDays;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'dueDate': dueDate.toIso8601String(),
        'isPaid': isPaid,
        'isRecurring': isRecurring,
        'recurringFrequency': recurringFrequency,
        'createdAt': createdAt.toIso8601String(),
        'currency': currency,
        'notes': notes,
        'paidDate': paidDate?.toIso8601String(),
      };

  static Bill fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['dueDate'] as String),
      isPaid: json['isPaid'] as bool? ?? false,
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurringFrequency: json['recurringFrequency'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      currency: json['currency'] as String? ?? 'USD',
      notes: json['notes'] as String?,
      paidDate: json['paidDate'] != null
          ? DateTime.parse(json['paidDate'] as String)
          : null,
    );
  }
}
