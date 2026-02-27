import 'package:hive/hive.dart';

part 'payment_account_model.g.dart';

@HiveType(typeId: 11)
class PaymentAccount extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String accountType; // Name of the account type from AccountTypeModel

  @HiveField(3)
  String? accountNumber; // Last 4 digits or masked

  @HiveField(4)
  String? bankName;

  @HiveField(5)
  double balance;

  @HiveField(6)
  String currency;

  @HiveField(7)
  String? color; // Hex color for UI display

  @HiveField(8)
  String? icon; // Icon name or code

  @HiveField(9)
  bool isDefault;

  @HiveField(10)
  bool isActive;

  @HiveField(11)
  DateTime createdAt;

  @HiveField(12)
  DateTime? lastUpdated;

  @HiveField(13)
  String? notes;

  @HiveField(14)
  double? creditLimit; // For credit cards

  @HiveField(15)
  DateTime? expiryDate; // For cards

  @HiveField(16)
  String? cardNetwork; // Visa, Mastercard, etc.

  @HiveField(17)
  String?
      linkedAccountId; // ID of linked parent account (e.g., debit card linked to bank account)

  PaymentAccount({
    required this.id,
    required this.name,
    required this.accountType,
    this.accountNumber,
    this.bankName,
    this.balance = 0.0,
    this.currency = 'USD',
    this.color,
    this.icon,
    this.isDefault = false,
    this.isActive = true,
    required this.createdAt,
    this.lastUpdated,
    this.notes,
    this.creditLimit,
    this.expiryDate,
    this.cardNetwork,
    this.linkedAccountId,
  });

  PaymentAccount copyWith({
    String? id,
    String? name,
    String? accountType,
    String? accountNumber,
    String? bankName,
    double? balance,
    String? currency,
    String? color,
    String? icon,
    bool? isDefault,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastUpdated,
    String? notes,
    double? creditLimit,
    DateTime? expiryDate,
    String? cardNetwork,
    String? linkedAccountId,
  }) {
    return PaymentAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      accountType: accountType ?? this.accountType,
      accountNumber: accountNumber ?? this.accountNumber,
      bankName: bankName ?? this.bankName,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      notes: notes ?? this.notes,
      creditLimit: creditLimit ?? this.creditLimit,
      expiryDate: expiryDate ?? this.expiryDate,
      cardNetwork: cardNetwork ?? this.cardNetwork,
      linkedAccountId: linkedAccountId ?? this.linkedAccountId,
    );
  }

  String get displayName {
    if (accountNumber != null && accountNumber!.isNotEmpty) {
      return '$name (...$accountNumber)';
    }
    return name;
  }

  String get typeLabel {
    return accountType;
  }

  double get availableBalance {
    if (accountType.toLowerCase().contains('credit') && creditLimit != null) {
      return creditLimit! - balance;
    }
    return balance;
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'accountType': accountType,
      'accountNumber': accountNumber,
      'bankName': bankName,
      'balance': balance,
      'currency': currency,
      'color': color,
      'icon': icon,
      'isDefault': isDefault,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated?.toIso8601String(),
      'notes': notes,
      'creditLimit': creditLimit,
      'expiryDate': expiryDate?.toIso8601String(),
      'cardNetwork': cardNetwork,
      'linkedAccountId': linkedAccountId,
    };
  }

  static List<PaymentAccount> getDefaultAccounts() {
    final now = DateTime.now();
    return [
      PaymentAccount(
        id: 'default_cash',
        name: 'Cash',
        accountType: 'Cash',
        balance: 0.0,
        currency: 'USD',
        color: '#4CAF50',
        icon: 'attach_money',
        isDefault: true,
        isActive: true,
        createdAt: now,
      ),
      PaymentAccount(
        id: 'default_bank',
        name: 'Bank Account',
        accountType: 'Bank Account',
        balance: 0.0,
        currency: 'USD',
        color: '#2196F3',
        icon: 'account_balance',
        isDefault: false,
        isActive: true,
        createdAt: now,
      ),
    ];
  }
}
