import 'package:hive/hive.dart';

part 'expense_category_model.g.dart';

@HiveType(typeId: 1)
class ExpenseCategory extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String icon;

  @HiveField(3)
  String color;

  @HiveField(4)
  bool isDefault;

  @HiveField(5)
  DateTime createdAt;

  ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isDefault = false,
    required this.createdAt,
  });

  static List<ExpenseCategory> getDefaultCategories() {
    return [
      ExpenseCategory(
        id: 'food_dining',
        name: 'Food & Dining',
        icon: '🍽️',
        color: '#FF6B6B',
        isDefault: true,
        createdAt: DateTime.now(),
      ),
      ExpenseCategory(
        id: 'shopping',
        name: 'Shopping',
        icon: '🛍️',
        color: '#A29BFE',
        isDefault: true,
        createdAt: DateTime.now(),
      ),
      ExpenseCategory(
        id: 'health',
        name: 'Health',
        icon: '⚕️',
        color: '#FF7675',
        isDefault: true,
        createdAt: DateTime.now(),
      ),
      ExpenseCategory(
        id: 'travel',
        name: 'Travel',
        icon: '✈️',
        color: '#74B9FF',
        isDefault: true,
        createdAt: DateTime.now(),
      ),
      ExpenseCategory(
        id: 'hotel',
        name: 'Hotel',
        icon: '🏨',
        color: '#FDCB6E',
        isDefault: true,
        createdAt: DateTime.now(),
      ),
      ExpenseCategory(
        id: 'grocery',
        name: 'Grocery',
        icon: '🛒',
        color: '#55EFC4',
        isDefault: true,
        createdAt: DateTime.now(),
      ),
      ExpenseCategory(
        id: 'fuel',
        name: 'Fuel',
        icon: '⛽',
        color: '#FD79A8',
        isDefault: true,
        createdAt: DateTime.now(),
      ),
      ExpenseCategory(
        id: 'subscriptions',
        name: 'Subscriptions',
        icon: '📱',
        color: '#6C5CE7',
        isDefault: true,
        createdAt: DateTime.now(),
      ),
      ExpenseCategory(
        id: 'entertainment',
        name: 'Entertainment',
        icon: '🎬',
        color: '#E17055',
        isDefault: true,
        createdAt: DateTime.now(),
      ),
      ExpenseCategory(
        id: 'education',
        name: 'Education',
        icon: '📚',
        color: '#0984E3',
        isDefault: true,
        createdAt: DateTime.now(),
      ),
      ExpenseCategory(
        id: 'others',
        name: 'Others',
        icon: '📌',
        color: '#95A5A6',
        isDefault: true,
        createdAt: DateTime.now(),
      ),
    ];
  }

  ExpenseCategory copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return ExpenseCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'color': color,
        'isDefault': isDefault,
        'createdAt': createdAt.toIso8601String(),
      };

  static ExpenseCategory fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
