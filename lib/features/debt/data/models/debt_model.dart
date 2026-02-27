import 'package:hive/hive.dart';

part 'debt_model.g.dart';

@HiveType(typeId: 5)
class Debt extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String loanName;

  @HiveField(2)
  double principalAmount;

  @HiveField(3)
  double interestRate;

  @HiveField(4)
  int tenureMonths;

  @HiveField(5)
  double monthlyEmi;

  @HiveField(6)
  double remainingBalance;

  @HiveField(7)
  DateTime startDate;

  @HiveField(8)
  DateTime? endDate;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  List<EMIPayment> payments;

  @HiveField(11)
  String currency;

  Debt({
    required this.id,
    required this.loanName,
    required this.principalAmount,
    required this.interestRate,
    required this.tenureMonths,
    required this.monthlyEmi,
    required this.remainingBalance,
    required this.startDate,
    this.endDate,
    required this.createdAt,
    this.payments = const [],
    this.currency = 'USD',
  });

  double calculateTotalInterest() {
    return (monthlyEmi * tenureMonths) - principalAmount;
  }

  int getMonthsRemaining() {
    return ((remainingBalance / monthlyEmi).ceil());
  }

  Debt copyWith({
    String? id,
    String? loanName,
    double? principalAmount,
    double? interestRate,
    int? tenureMonths,
    double? monthlyEmi,
    double? remainingBalance,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    List<EMIPayment>? payments,
    String? currency,
  }) {
    return Debt(
      id: id ?? this.id,
      loanName: loanName ?? this.loanName,
      principalAmount: principalAmount ?? this.principalAmount,
      interestRate: interestRate ?? this.interestRate,
      tenureMonths: tenureMonths ?? this.tenureMonths,
      monthlyEmi: monthlyEmi ?? this.monthlyEmi,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      payments: payments ?? this.payments,
      currency: currency ?? this.currency,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'loanName': loanName,
        'principalAmount': principalAmount,
        'interestRate': interestRate,
        'tenureMonths': tenureMonths,
        'monthlyEmi': monthlyEmi,
        'remainingBalance': remainingBalance,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'payments': payments.map((p) => p.toJson()).toList(),
        'currency': currency,
      };

  static Debt fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['id'] as String,
      loanName: json['loanName'] as String,
      principalAmount: (json['principalAmount'] as num).toDouble(),
      interestRate: (json['interestRate'] as num).toDouble(),
      tenureMonths: json['tenureMonths'] as int,
      monthlyEmi: (json['monthlyEmi'] as num).toDouble(),
      remainingBalance: (json['remainingBalance'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      payments: (json['payments'] as List? ?? [])
          .map((p) => EMIPayment.fromJson(p as Map<String, dynamic>))
          .toList(),
      currency: json['currency'] as String? ?? 'USD',
    );
  }
}

@HiveType(typeId: 6)
class EMIPayment extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int monthNumber;

  @HiveField(2)
  double principalAmount;

  @HiveField(3)
  double interestAmount;

  @HiveField(4)
  double totalAmount;

  @HiveField(5)
  double remainingBalance;

  @HiveField(6)
  DateTime dueDate;

  @HiveField(7)
  bool isPaid;

  @HiveField(8)
  DateTime? paidDate;

  EMIPayment({
    required this.id,
    required this.monthNumber,
    required this.principalAmount,
    required this.interestAmount,
    required this.totalAmount,
    required this.remainingBalance,
    required this.dueDate,
    this.isPaid = false,
    this.paidDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'monthNumber': monthNumber,
        'principalAmount': principalAmount,
        'interestAmount': interestAmount,
        'totalAmount': totalAmount,
        'remainingBalance': remainingBalance,
        'dueDate': dueDate.toIso8601String(),
        'isPaid': isPaid,
        'paidDate': paidDate?.toIso8601String(),
      };

  static EMIPayment fromJson(Map<String, dynamic> json) {
    return EMIPayment(
      id: json['id'] as String,
      monthNumber: json['monthNumber'] as int,
      principalAmount: (json['principalAmount'] as num).toDouble(),
      interestAmount: (json['interestAmount'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      remainingBalance: (json['remainingBalance'] as num).toDouble(),
      dueDate: DateTime.parse(json['dueDate'] as String),
      isPaid: json['isPaid'] as bool? ?? false,
      paidDate: json['paidDate'] != null
          ? DateTime.parse(json['paidDate'] as String)
          : null,
    );
  }
}
