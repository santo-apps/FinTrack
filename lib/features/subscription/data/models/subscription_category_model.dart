class SubscriptionCategoryModel {
  final String id;
  final String name;
  final String icon;

  SubscriptionCategoryModel({
    required this.id,
    required this.name,
    required this.icon,
  });

  static List<SubscriptionCategoryModel> getDefaultCategories() {
    return [
      SubscriptionCategoryModel(
        id: 'entertainment',
        name: 'Entertainment',
        icon: '🎬',
      ),
      SubscriptionCategoryModel(
        id: 'music',
        name: 'Music',
        icon: '🎵',
      ),
      SubscriptionCategoryModel(
        id: 'streaming',
        name: 'Streaming',
        icon: '📺',
      ),
      SubscriptionCategoryModel(
        id: 'productivity',
        name: 'Productivity',
        icon: '💼',
      ),
      SubscriptionCategoryModel(
        id: 'cloud',
        name: 'Cloud Storage',
        icon: '☁️',
      ),
      SubscriptionCategoryModel(
        id: 'fitness',
        name: 'Fitness',
        icon: '💪',
      ),
      SubscriptionCategoryModel(
        id: 'news',
        name: 'News',
        icon: '📰',
      ),
      SubscriptionCategoryModel(
        id: 'education',
        name: 'Education',
        icon: '📚',
      ),
      SubscriptionCategoryModel(
        id: 'gaming',
        name: 'Gaming',
        icon: '🎮',
      ),
      SubscriptionCategoryModel(
        id: 'food',
        name: 'Food & Delivery',
        icon: '🍔',
      ),
      SubscriptionCategoryModel(
        id: 'shopping',
        name: 'Shopping',
        icon: '🛒',
      ),
      SubscriptionCategoryModel(
        id: 'transport',
        name: 'Transport',
        icon: '🚗',
      ),
      SubscriptionCategoryModel(
        id: 'software',
        name: 'Software',
        icon: '💻',
      ),
      SubscriptionCategoryModel(
        id: 'other',
        name: 'Other',
        icon: '📋',
      ),
    ];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
    };
  }

  factory SubscriptionCategoryModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
    );
  }

  // For backward compatibility - create from string
  factory SubscriptionCategoryModel.fromString(String categoryName) {
    final defaults = getDefaultCategories();
    final match = defaults.firstWhere(
      (c) => c.name.toLowerCase() == categoryName.toLowerCase(),
      orElse: () => SubscriptionCategoryModel(
        id: categoryName.toLowerCase().replaceAll(' ', '_'),
        name: categoryName,
        icon: '📱', // Default icon for unknown categories
      ),
    );
    return match;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionCategoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          icon == other.icon;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ icon.hashCode;
}
