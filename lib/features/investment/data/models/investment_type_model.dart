import 'package:hive/hive.dart';

part 'investment_type_model.g.dart';

@HiveType(typeId: 12)
class InvestmentType extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int order;

  @HiveField(3)
  DateTime createdAt;

  InvestmentType({
    required this.id,
    required this.name,
    required this.order,
    required this.createdAt,
  });

  InvestmentType copyWith({
    String? id,
    String? name,
    int? order,
    DateTime? createdAt,
  }) {
    return InvestmentType(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'order': order,
        'createdAt': createdAt.toIso8601String(),
      };

  static InvestmentType fromJson(Map<String, dynamic> json) {
    return InvestmentType(
      id: json['id'] as String,
      name: json['name'] as String,
      order: json['order'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
