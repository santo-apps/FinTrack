import 'package:hive/hive.dart';

part 'financial_goal_model.g.dart';

@HiveType(typeId: 8)
class FinancialGoal extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String goalName;

  @HiveField(2)
  double targetAmount;

  @HiveField(3)
  double currentAmount;

  @HiveField(4)
  DateTime targetDate;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  String category;

  @HiveField(7)
  String currency;

  @HiveField(8)
  String? description;

  @HiveField(9)
  bool isCompleted;

  @HiveField(10)
  DateTime? completedDate;

  FinancialGoal({
    required this.id,
    required this.goalName,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.createdAt,
    this.category = 'Savings',
    this.currency = 'USD',
    this.description,
    this.isCompleted = false,
    this.completedDate,
  });

  double getProgressPercentage() {
    if (targetAmount == 0) return 0;
    return ((currentAmount / targetAmount) * 100).clamp(0, 100);
  }

  double getRemainingAmount() =>
      (targetAmount - currentAmount).clamp(0, double.infinity);

  int getDaysRemaining() => targetDate.difference(DateTime.now()).inDays;

  double getMonthlyRequiredAmount() {
    final monthsRemaining = (getDaysRemaining() / 30).ceil();
    if (monthsRemaining <= 0) return getRemainingAmount();
    return getRemainingAmount() / monthsRemaining;
  }

  FinancialGoal copyWith({
    String? id,
    String? goalName,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    DateTime? createdAt,
    String? category,
    String? currency,
    String? description,
    bool? isCompleted,
    DateTime? completedDate,
  }) {
    return FinancialGoal(
      id: id ?? this.id,
      goalName: goalName ?? this.goalName,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: completedDate ?? this.completedDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'goalName': goalName,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'targetDate': targetDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'category': category,
        'currency': currency,
        'description': description,
        'isCompleted': isCompleted,
        'completedDate': completedDate?.toIso8601String(),
      };

  static FinancialGoal fromJson(Map<String, dynamic> json) {
    return FinancialGoal(
      id: json['id'] as String,
      goalName: json['goalName'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num).toDouble(),
      targetDate: DateTime.parse(json['targetDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      category: json['category'] as String? ?? 'Savings',
      currency: json['currency'] as String? ?? 'USD',
      description: json['description'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'] as String)
          : null,
    );
  }
}
