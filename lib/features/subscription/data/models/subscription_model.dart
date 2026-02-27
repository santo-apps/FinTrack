import 'package:hive/hive.dart';

part 'subscription_model.g.dart';

@HiveType(typeId: 3)
class Subscription extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double cost;

  @HiveField(3)
  String billingCycle;

  @HiveField(4)
  DateTime renewalDate;

  @HiveField(5)
  bool autoRenewal;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  String currency;

  @HiveField(8)
  String? notes;

  @HiveField(9)
  String? category;

  Subscription({
    required this.id,
    required this.name,
    required this.cost,
    required this.billingCycle,
    required this.renewalDate,
    this.autoRenewal = true,
    required this.createdAt,
    this.currency = 'USD',
    this.notes,
    this.category,
  });

  Subscription copyWith({
    String? id,
    String? name,
    double? cost,
    String? billingCycle,
    DateTime? renewalDate,
    bool? autoRenewal,
    DateTime? createdAt,
    String? currency,
    String? notes,
    String? category,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      cost: cost ?? this.cost,
      billingCycle: billingCycle ?? this.billingCycle,
      renewalDate: renewalDate ?? this.renewalDate,
      autoRenewal: autoRenewal ?? this.autoRenewal,
      createdAt: createdAt ?? this.createdAt,
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
      category: category ?? this.category,
    );
  }

  double getMonthlyAmount() {
    switch (billingCycle.toLowerCase()) {
      case 'monthly':
        return cost;
      case 'quarterly':
        return cost / 3;
      case 'yearly':
      case 'annual':
        return cost / 12;
      case 'weekly':
        return cost * 4.33;
      default:
        return cost;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'cost': cost,
        'billingCycle': billingCycle,
        'renewalDate': renewalDate.toIso8601String(),
        'autoRenewal': autoRenewal,
        'createdAt': createdAt.toIso8601String(),
        'currency': currency,
        'notes': notes,
        'category': category,
      };

  static Subscription fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      name: json['name'] as String,
      cost: (json['cost'] as num).toDouble(),
      billingCycle: json['billingCycle'] as String,
      renewalDate: DateTime.parse(json['renewalDate'] as String),
      autoRenewal: json['autoRenewal'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      currency: json['currency'] as String? ?? 'USD',
      notes: json['notes'] as String?,
      category: json['category'] as String?,
    );
  }
}
