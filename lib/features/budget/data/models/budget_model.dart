import 'package:hive/hive.dart';

part 'budget_model.g.dart';

enum BudgetRecurrenceType { oneTime, monthly }

@HiveType(typeId: 2)
class Budget extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double monthlyIncome; // Deprecated, kept for backward compatibility

  @HiveField(2)
  Map<String, double> categoryLimits; // Category name -> budget amount

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  @HiveField(5)
  String currency;

  @HiveField(6)
  bool enableAlerts;

  @HiveField(7)
  int month; // 1-12

  @HiveField(8)
  int year;

  @HiveField(9)
  String? recurrenceType; // 'oneTime' or 'monthly'

  @HiveField(10)
  DateTime? endDate; // Optional end date for recurring budgets

  @HiveField(11)
  String? baselineId; // ID of parent budget if this is a recurring instance

  Budget({
    required this.id,
    this.monthlyIncome = 0, // Deprecated
    required this.categoryLimits,
    required this.createdAt,
    required this.updatedAt,
    this.currency = 'USD',
    this.enableAlerts = true,
    required this.month,
    required this.year,
    this.recurrenceType = 'oneTime',
    this.endDate,
    this.baselineId,
  });

  Budget copyWith({
    String? id,
    double? monthlyIncome,
    Map<String, double>? categoryLimits,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? currency,
    bool? enableAlerts,
    int? month,
    int? year,
    String? recurrenceType,
    DateTime? endDate,
    String? baselineId,
  }) {
    return Budget(
      id: id ?? this.id,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      categoryLimits: categoryLimits ?? this.categoryLimits,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currency: currency ?? this.currency,
      enableAlerts: enableAlerts ?? this.enableAlerts,
      month: month ?? this.month,
      year: year ?? this.year,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      endDate: endDate ?? this.endDate,
      baselineId: baselineId ?? this.baselineId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'monthlyIncome': monthlyIncome,
        'categoryLimits': categoryLimits,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'currency': currency,
        'enableAlerts': enableAlerts,
        'month': month,
        'year': year,
        'recurrenceType': recurrenceType,
        'endDate': endDate?.toIso8601String(),
        'baselineId': baselineId,
      };

  static Budget fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      monthlyIncome: (json['monthlyIncome'] as num?)?.toDouble() ?? 0,
      categoryLimits:
          Map<String, double>.from(json['categoryLimits'] as Map? ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      currency: json['currency'] ?? 'USD',
      enableAlerts: json['enableAlerts'] ?? true,
      month: json['month'],
      year: json['year'],
      recurrenceType: json['recurrenceType'] ?? 'oneTime',
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      baselineId: json['baselineId'],
    );
  }
}
