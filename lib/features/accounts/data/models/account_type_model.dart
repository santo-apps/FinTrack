import 'package:hive/hive.dart';

part 'account_type_model.g.dart';

@HiveType(typeId: 13)
class AccountTypeModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? icon; // Emoji or icon code

  @HiveField(3)
  String? color; // Hex color

  @HiveField(4)
  bool isDefault; // Pre-defined types like UPI, Debit Card, etc.

  @HiveField(5)
  int order; // Display order

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  bool isActive;

  AccountTypeModel({
    required this.id,
    required this.name,
    this.icon,
    this.color,
    this.isDefault = false,
    required this.order,
    required this.createdAt,
    this.isActive = true,
  });

  AccountTypeModel copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    bool? isDefault,
    int? order,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return AccountTypeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'isDefault': isDefault,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory AccountTypeModel.fromJson(Map<String, dynamic> json) {
    return AccountTypeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      order: json['order'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
