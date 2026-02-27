import 'package:hive/hive.dart';

part 'investment_model.g.dart';

@HiveType(typeId: 7)
class Investment extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String type;

  @HiveField(3)
  double? quantity;

  @HiveField(4)
  double? buyPrice;

  @HiveField(5)
  double? currentPrice;

  @HiveField(6)
  DateTime? purchaseDate;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  String currency;

  @HiveField(9)
  String? notes;

  @HiveField(10)
  double? investedAmount;

  @HiveField(11)
  double? currentValue;

  Investment({
    required this.id,
    required this.name,
    required this.type,
    this.investedAmount,
    this.quantity,
    this.buyPrice,
    this.currentPrice,
    this.currentValue,
    this.purchaseDate,
    required this.createdAt,
    this.currency = 'USD',
    this.notes,
  });

  double getTotalInvestmentValue() {
    if (investedAmount != null) return investedAmount!;
    if (quantity != null && buyPrice != null) {
      return quantity! * buyPrice!;
    }
    return 0.0;
  }

  double getCurrentValue() {
    if (currentValue != null) return currentValue!;
    if (quantity != null && currentPrice != null) {
      return quantity! * currentPrice!;
    }
    return getTotalInvestmentValue(); // Default to invested amount
  }

  double getGainLoss() => getCurrentValue() - getTotalInvestmentValue();

  double getGainLossPercentage() {
    final investmentValue = getTotalInvestmentValue();
    if (investmentValue == 0) return 0;
    return ((getGainLoss() / investmentValue) * 100);
  }

  bool isProfit() => getGainLoss() >= 0;

  Investment copyWith({
    String? id,
    String? name,
    String? type,
    double? investedAmount,
    double? quantity,
    double? buyPrice,
    double? currentPrice,
    double? currentValue,
    DateTime? purchaseDate,
    DateTime? createdAt,
    String? currency,
    String? notes,
  }) {
    return Investment(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      investedAmount: investedAmount ?? this.investedAmount,
      quantity: quantity ?? this.quantity,
      buyPrice: buyPrice ?? this.buyPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      currentValue: currentValue ?? this.currentValue,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      createdAt: createdAt ?? this.createdAt,
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'investedAmount': investedAmount,
        'quantity': quantity,
        'buyPrice': buyPrice,
        'currentPrice': currentPrice,
        'currentValue': currentValue,
        'purchaseDate': purchaseDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'currency': currency,
        'notes': notes,
      };

  static Investment fromJson(Map<String, dynamic> json) {
    return Investment(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      investedAmount: json['investedAmount'] != null
          ? (json['investedAmount'] as num).toDouble()
          : null,
      quantity: json['quantity'] != null
          ? (json['quantity'] as num).toDouble()
          : null,
      buyPrice: json['buyPrice'] != null
          ? (json['buyPrice'] as num).toDouble()
          : null,
      currentPrice: json['currentPrice'] != null
          ? (json['currentPrice'] as num).toDouble()
          : null,
      currentValue: json['currentValue'] != null
          ? (json['currentValue'] as num).toDouble()
          : null,
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.parse(json['purchaseDate'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      currency: json['currency'] as String? ?? 'USD',
      notes: json['notes'] as String?,
    );
  }
}
