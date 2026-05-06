import 'package:hive/hive.dart';

part 'loan_model.g.dart';

@HiveType(typeId: 9)
class Loan extends HiveObject {
  static const Object _unset = Object();

  @HiveField(0)
  String id;

  @HiveField(1)
  String lender;

  @HiveField(2)
  double borrowedAmount;

  @HiveField(3)
  double interestRate;

  @HiveField(4)
  int tenureMonths;

  @HiveField(5)
  double monthlyEmi;

  @HiveField(6)
  DateTime startDate;

  @HiveField(7)
  DateTime endDate;

  @HiveField(8)
  int emiDate; // Day of month when EMI is due (1-31)

  @HiveField(9)
  double paidAmount;

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  String currency;

  @HiveField(12)
  String? notes;

  @HiveField(13)
  String? accountId; // Link to PaymentAccount

  @HiveField(14)
  DateTime? lastPaymentDate; // Track when last payment was made

  @HiveField(15)
  double interestPaidAmount; // Track interest-only payments separately

  Loan({
    required this.id,
    required this.lender,
    required this.borrowedAmount,
    required this.interestRate,
    required this.tenureMonths,
    required this.monthlyEmi,
    required this.startDate,
    required this.endDate,
    required this.emiDate,
    this.paidAmount = 0.0,
    required this.createdAt,
    this.currency = 'USD',
    this.notes,
    this.accountId,
    this.lastPaymentDate,
    this.interestPaidAmount = 0.0,
  });

  double get pendingAmount => borrowedAmount - paidAmount;

  double get totalPayable {
    return monthlyEmi * tenureMonths;
  }

  double get totalInterest {
    return totalPayable - borrowedAmount;
  }

  int get remainingMonths {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;

    final months = ((endDate.year - now.year) * 12 + endDate.month - now.month);
    return months > 0 ? months : 0;
  }

  bool get isCompleted {
    return paidAmount >= borrowedAmount || DateTime.now().isAfter(endDate);
  }

  DateTime? get nextEmiDate {
    if (isCompleted) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime safeDayInMonth(int year, int month, int day) {
      final firstDay = DateTime(year, month, 1);
      final lastDay = DateTime(firstDay.year, firstDay.month + 1, 0).day;
      final clampedDay = day.clamp(1, lastDay);
      return DateTime(firstDay.year, firstDay.month, clampedDay);
    }

    var nextDate = safeDayInMonth(now.year, now.month, emiDate);

    final firstEmiInStartMonth =
        safeDayInMonth(startDate.year, startDate.month, emiDate);
    final firstDueDate = startDate.isAfter(firstEmiInStartMonth)
        ? safeDayInMonth(startDate.year, startDate.month + 1, emiDate)
        : firstEmiInStartMonth;

    if (nextDate.isBefore(today)) {
      nextDate = safeDayInMonth(now.year, now.month + 1, emiDate);
    }

    if (nextDate.isBefore(firstDueDate)) {
      nextDate = firstDueDate;
    }

    final endDay = DateTime(endDate.year, endDate.month, endDate.day);
    return nextDate.isAfter(endDay) ? null : nextDate;
  }

  Loan copyWith({
    String? id,
    String? lender,
    double? borrowedAmount,
    double? interestRate,
    int? tenureMonths,
    double? monthlyEmi,
    DateTime? startDate,
    DateTime? endDate,
    int? emiDate,
    double? paidAmount,
    DateTime? createdAt,
    String? currency,
    String? notes,
    String? accountId,
    Object? lastPaymentDate = _unset,
    double? interestPaidAmount,
  }) {
    return Loan(
      id: id ?? this.id,
      lender: lender ?? this.lender,
      borrowedAmount: borrowedAmount ?? this.borrowedAmount,
      interestRate: interestRate ?? this.interestRate,
      tenureMonths: tenureMonths ?? this.tenureMonths,
      monthlyEmi: monthlyEmi ?? this.monthlyEmi,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      emiDate: emiDate ?? this.emiDate,
      paidAmount: paidAmount ?? this.paidAmount,
      createdAt: createdAt ?? this.createdAt,
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
      accountId: accountId ?? this.accountId,
      lastPaymentDate: lastPaymentDate == _unset
          ? this.lastPaymentDate
          : lastPaymentDate as DateTime?,
      interestPaidAmount: interestPaidAmount ?? this.interestPaidAmount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lender': lender,
      'borrowedAmount': borrowedAmount,
      'interestRate': interestRate,
      'tenureMonths': tenureMonths,
      'monthlyEmi': monthlyEmi,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'emiDate': emiDate,
      'paidAmount': paidAmount,
      'createdAt': createdAt.toIso8601String(),
      'currency': currency,
      'notes': notes,
      'accountId': accountId,
      'lastPaymentDate': lastPaymentDate?.toIso8601String(),
      'interestPaidAmount': interestPaidAmount,
    };
  }

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'],
      lender: json['lender'],
      borrowedAmount: json['borrowedAmount'],
      interestRate: json['interestRate'],
      tenureMonths: json['tenureMonths'],
      monthlyEmi: json['monthlyEmi'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      emiDate: json['emiDate'],
      paidAmount: json['paidAmount'] ?? 0.0,
      createdAt: DateTime.parse(json['createdAt']),
      currency: json['currency'] ?? 'USD',
      notes: json['notes'],
      accountId: json['accountId'],
      lastPaymentDate: json['lastPaymentDate'] != null
          ? DateTime.parse(json['lastPaymentDate'])
          : null,
      interestPaidAmount: json['interestPaidAmount'] ?? 0.0,
    );
  }
}
