import 'package:hive/hive.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  double amount;

  @HiveField(3)
  String category;

  @HiveField(4)
  String paymentMethod;

  @HiveField(5)
  DateTime date;

  @HiveField(6)
  String? notes;

  @HiveField(7)
  List<String> tags;

  @HiveField(8)
  String? receiptImagePath;

  @HiveField(9)
  bool isRecurring;

  @HiveField(10)
  String? recurringFrequency;

  @HiveField(11)
  String currency;

  @HiveField(12)
  String? accountId; // Link to PaymentAccount

  @HiveField(13)
  String? transactionType; // 'expense', 'income', 'transfer', 'payment'

  @HiveField(14)
  String? destinationAccountId; // For transfers and payments

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.paymentMethod,
    required this.date,
    this.notes,
    this.tags = const [],
    this.receiptImagePath,
    this.isRecurring = false,
    this.recurringFrequency,
    this.currency = 'USD',
    this.accountId,
    String? transactionType,
    this.destinationAccountId,
  }) : transactionType = transactionType ?? 'expense';

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    String? paymentMethod,
    DateTime? date,
    String? notes,
    List<String>? tags,
    String? receiptImagePath,
    bool? isRecurring,
    String? recurringFrequency,
    String? currency,
    String? accountId,
    String? transactionType,
    String? destinationAccountId,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
      currency: currency ?? this.currency,
      accountId: accountId ?? this.accountId,
      transactionType: transactionType ?? this.transactionType ?? 'expense',
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'paymentMethod': paymentMethod,
        'date': date.toIso8601String(),
        'notes': notes,
        'tags': tags,
        'receiptImagePath': receiptImagePath,
        'isRecurring': isRecurring,
        'recurringFrequency': recurringFrequency,
        'currency': currency,
        'accountId': accountId,
        'transactionType': transactionType ?? 'expense',
        'destinationAccountId': destinationAccountId,
      };

  static Expense fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      paymentMethod: json['paymentMethod'] as String,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
      tags: List<String>.from(json['tags'] as List? ?? []),
      receiptImagePath: json['receiptImagePath'] as String?,
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurringFrequency: json['recurringFrequency'] as String?,
      currency: json['currency'] as String? ?? 'USD',
      accountId: json['accountId'] as String?,
      transactionType: json['transactionType'] as String? ?? 'expense',
      destinationAccountId: json['destinationAccountId'] as String?,
    );
  }
}
