import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../../features/expense/data/models/expense_model.dart';
import '../../features/expense/data/models/expense_category_model.dart';
import '../../features/budget/data/models/budget_model.dart';
import '../../features/subscription/data/models/subscription_model.dart';
import '../../features/bill/data/models/bill_model.dart';
import '../../features/debt/data/models/debt_model.dart';
import '../../features/investment/data/models/investment_model.dart';
import '../../features/investment/data/models/investment_type_model.dart';
import '../../features/goals/data/models/financial_goal_model.dart';
import '../../features/accounts/data/models/payment_account_model.dart';
import '../../features/accounts/data/models/account_type_model.dart';
import '../../features/loan/data/models/loan_model.dart';

class HiveService {
  static const String _encryptionKey =
      'smartfinance_plus_encryption_key_2024_secure_key_min_32_char';

  static late Box<Expense> _expenseBox;
  static late Box<ExpenseCategory> _categoryBox;
  static late Box<Budget> _budgetBox;
  static late Box<Subscription> _subscriptionBox;
  static late Box<Bill> _billBox;
  static late Box<Debt> _debtBox;
  static late Box<Investment> _investmentBox;
  static late Box<InvestmentType> _investmentTypeBox;
  static late Box<FinancialGoal> _goalBox;
  static late Box<PaymentAccount> _paymentAccountBox;
  static late Box<AccountTypeModel> _accountTypeBox;
  static late Box<Loan> _loanBox;
  static late Box<dynamic> _appSettingsBox;

  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(ExpenseAdapter());
    Hive.registerAdapter(ExpenseCategoryAdapter());
    Hive.registerAdapter(BudgetAdapter());
    Hive.registerAdapter(SubscriptionAdapter());
    Hive.registerAdapter(BillAdapter());
    Hive.registerAdapter(DebtAdapter());
    Hive.registerAdapter(EMIPaymentAdapter());
    Hive.registerAdapter(InvestmentAdapter());
    Hive.registerAdapter(InvestmentTypeAdapter());
    Hive.registerAdapter(FinancialGoalAdapter());
    Hive.registerAdapter(AccountTypeModelAdapter());
    Hive.registerAdapter(PaymentAccountAdapter());
    Hive.registerAdapter(LoanAdapter());

    // Open boxes
    _expenseBox = await Hive.openBox<Expense>('expenses');
    _categoryBox = await Hive.openBox<ExpenseCategory>('categories');
    _budgetBox = await Hive.openBox<Budget>('budget');
    _subscriptionBox = await Hive.openBox<Subscription>('subscriptions');
    _billBox = await Hive.openBox<Bill>('bills');
    _debtBox = await Hive.openBox<Debt>('debts');
    _investmentBox = await Hive.openBox<Investment>('investments');
    _investmentTypeBox = await Hive.openBox<InvestmentType>('investment_types');
    _goalBox = await Hive.openBox<FinancialGoal>('goals');
    _accountTypeBox = await Hive.openBox<AccountTypeModel>('account_types');

    // Open loan box with error handling for potential schema issues
    try {
      _loanBox = await Hive.openBox<Loan>('loans');
    } catch (e) {
      print('Error opening loans box, recreating: $e');
      await Hive.deleteBoxFromDisk('loans');
      _loanBox = await Hive.openBox<Loan>('loans');
    }

    // Migration: Handle old PaymentAccount data with AccountType enum
    try {
      _paymentAccountBox =
          await Hive.openBox<PaymentAccount>('payment_accounts');
    } catch (e) {
      // If there's an error reading old data (typeId 42 for old AccountType enum),
      // delete the box and recreate it
      print(
          'Migration: Deleting old payment_accounts box due to schema change');
      await Hive.deleteBoxFromDisk('payment_accounts');
      _paymentAccountBox =
          await Hive.openBox<PaymentAccount>('payment_accounts');
    }

    _appSettingsBox = await Hive.openBox('app_settings');

    _isInitialized = true;

    // Migration: Backfill transactionType for older expenses
    await _migrateExpenseTransactionType();

    // Initialize default categories if not already present
    if (_categoryBox.isEmpty) {
      final defaultCategories = ExpenseCategory.getDefaultCategories();
      for (var category in defaultCategories) {
        await _categoryBox.put(category.id, category);
      }
    }
  }

  // Expense operations
  static Future<void> addExpense(Expense expense) async {
    await _expenseBox.put(expense.id, expense);
  }

  static Future<void> updateExpense(Expense expense) async {
    await _expenseBox.put(expense.id, expense);
  }

  static Future<void> deleteExpense(String id) async {
    await _expenseBox.delete(id);
  }

  static List<Expense> getAllExpenses() {
    return _expenseBox.values.toList();
  }

  static Future<void> _migrateExpenseTransactionType() async {
    if (_expenseBox.isEmpty) return;

    final updates = <String, Expense>{};
    for (final expense in _expenseBox.values) {
      if (expense.transactionType == null || expense.transactionType!.isEmpty) {
        updates[expense.id] = expense.copyWith(
          transactionType: 'expense',
          destinationAccountId: expense.destinationAccountId,
        );
      }
    }

    if (updates.isNotEmpty) {
      await _expenseBox.putAll(updates);
    }
  }

  static List<Expense> getExpensesInDateRange(DateTime start, DateTime end) {
    return _expenseBox.values
        .where((e) => e.date.isAfter(start) && e.date.isBefore(end))
        .toList();
  }

  static List<Expense> getExpensesByCategory(String category) {
    return _expenseBox.values.where((e) => e.category == category).toList();
  }

  // Category operations
  static Future<void> addCategory(ExpenseCategory category) async {
    await _categoryBox.put(category.id, category);
  }

  static Future<void> updateCategory(ExpenseCategory category) async {
    await _categoryBox.put(category.id, category);
  }

  static Future<void> deleteCategory(String id) async {
    await _categoryBox.delete(id);
  }

  static List<ExpenseCategory> getAllCategories() {
    return _categoryBox.values.toList();
  }

  static ExpenseCategory? getCategoryById(String id) {
    return _categoryBox.get(id);
  }

  // Budget operations
  static Future<void> updateBudget(Budget budget) async {
    await _budgetBox.put(budget.id, budget);
  }

  static Budget? getBudget() {
    final now = DateTime.now();
    return getBudgetForMonth(now.month, now.year);
  }

  static Budget? getBudgetForMonth(int month, int year) {
    for (final budget in _budgetBox.values) {
      if (budget.month == month && budget.year == year) {
        return budget;
      }
    }
    return null;
  }

  static List<Budget> getAllBudgets() {
    return _budgetBox.values.toList();
  }

  // Subscription operations
  static Future<void> addSubscription(Subscription subscription) async {
    await _subscriptionBox.put(subscription.id, subscription);
  }

  static Future<void> updateSubscription(Subscription subscription) async {
    await _subscriptionBox.put(subscription.id, subscription);
  }

  static Future<void> deleteSubscription(String id) async {
    await _subscriptionBox.delete(id);
  }

  static List<Subscription> getAllSubscriptions() {
    return _subscriptionBox.values.toList();
  }

  // Bill operations
  static Future<void> addBill(Bill bill) async {
    await _billBox.put(bill.id, bill);
  }

  static Future<void> updateBill(Bill bill) async {
    await _billBox.put(bill.id, bill);
  }

  static Future<void> deleteBill(String id) async {
    await _billBox.delete(id);
  }

  static List<Bill> getAllBills() {
    return _billBox.values.toList();
  }

  static List<Bill> getUpcomingBills() {
    final now = DateTime.now();
    return _billBox.values
        .where((b) => !b.isPaid && b.dueDate.isAfter(now))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  static List<Bill> getOverdueBills() {
    return _billBox.values.where((b) => b.isOverdue()).toList();
  }

  // Debt operations
  static Future<void> addDebt(Debt debt) async {
    await _debtBox.put(debt.id, debt);
  }

  static Future<void> updateDebt(Debt debt) async {
    await _debtBox.put(debt.id, debt);
  }

  static Future<void> deleteDebt(String id) async {
    await _debtBox.delete(id);
  }

  static List<Debt> getAllDebts() {
    return _debtBox.values.toList();
  }

  static Debt? getDebtById(String id) {
    return _debtBox.get(id);
  }

  // Investment operations
  static Future<void> addInvestment(Investment investment) async {
    await _investmentBox.put(investment.id, investment);
  }

  static Future<void> updateInvestment(Investment investment) async {
    await _investmentBox.put(investment.id, investment);
  }

  static Future<void> deleteInvestment(String id) async {
    await _investmentBox.delete(id);
  }

  static List<Investment> getAllInvestments() {
    return _investmentBox.values.toList();
  }

  static double getTotalPortfolioValue() {
    return _investmentBox.values.fold<double>(
      0,
      (sum, inv) => sum + inv.getCurrentValue(),
    );
  }

  static double getTotalInvestmentCost() {
    return _investmentBox.values.fold<double>(
      0,
      (sum, inv) => sum + inv.getTotalInvestmentValue(),
    );
  }

  // Financial Goal operations
  static Future<void> addGoal(FinancialGoal goal) async {
    await _goalBox.put(goal.id, goal);
  }

  static Future<void> updateGoal(FinancialGoal goal) async {
    await _goalBox.put(goal.id, goal);
  }

  static Future<void> deleteGoal(String id) async {
    await _goalBox.delete(id);
  }

  static List<FinancialGoal> getAllGoals() {
    return _goalBox.values.toList();
  }

  static List<FinancialGoal> getActiveGoals() {
    return _goalBox.values.where((g) => !g.isCompleted).toList();
  }

  // Payment Account operations
  static Future<void> addPaymentAccount(PaymentAccount account) async {
    await _paymentAccountBox.put(account.id, account);
  }

  static Future<void> updatePaymentAccount(PaymentAccount account) async {
    await _paymentAccountBox.put(account.id, account);
  }

  static Future<void> deletePaymentAccount(String id) async {
    await _paymentAccountBox.delete(id);
  }

  static List<PaymentAccount> getAllPaymentAccounts() {
    return _paymentAccountBox.values.toList();
  }

  static List<PaymentAccount> getActivePaymentAccounts() {
    return _paymentAccountBox.values.where((a) => a.isActive).toList();
  }

  static PaymentAccount? getDefaultPaymentAccount() {
    try {
      return _paymentAccountBox.values.firstWhere((a) => a.isDefault);
    } catch (e) {
      final accounts = _paymentAccountBox.values.toList();
      return accounts.isNotEmpty ? accounts.first : null;
    }
  }

  // Investment Type operations
  static Future<void> addInvestmentType(InvestmentType type) async {
    await _investmentTypeBox.put(type.id, type);
  }

  static Future<void> updateInvestmentType(InvestmentType type) async {
    await _investmentTypeBox.put(type.id, type);
  }

  static Future<void> deleteInvestmentType(String id) async {
    await _investmentTypeBox.delete(id);
  }

  static Future<List<InvestmentType>> getAllInvestmentTypes() async {
    return _investmentTypeBox.values.toList();
  }

  // Payment Type operations
  static Future<void> addAccountType(AccountTypeModel type) async {
    await _accountTypeBox.put(type.id, type);
  }

  static Future<void> updateAccountType(AccountTypeModel type) async {
    await _accountTypeBox.put(type.id, type);
  }

  static Future<void> deleteAccountType(String id) async {
    await _accountTypeBox.delete(id);
  }

  static Future<List<AccountTypeModel>> getAllAccountTypes() async {
    return _accountTypeBox.values.toList();
  }

  // Loan operations
  static Future<void> addLoan(Loan loan) async {
    await _loanBox.put(loan.id, loan);
  }

  static Future<void> updateLoan(Loan loan) async {
    await _loanBox.put(loan.id, loan);
  }

  static Future<void> deleteLoan(String id) async {
    await _loanBox.delete(id);
  }

  static List<Loan> getAllLoans() {
    return _loanBox.values.toList();
  }

  static List<Loan> getActiveLoans() {
    return _loanBox.values.where((loan) => !loan.isCompleted).toList();
  }

  static Loan? getLoanById(String id) {
    return _loanBox.get(id);
  }

  // App Settings
  static Future<void> saveSetting(String key, dynamic value) async {
    await _appSettingsBox.put(key, value);
  }

  static dynamic getSetting(String key, {dynamic defaultValue}) {
    return _appSettingsBox.get(key, defaultValue: defaultValue);
  }

  static Future<void> clearAllData() async {
    await Future.wait([
      _expenseBox.clear(),
      _categoryBox.clear(),
      _budgetBox.clear(),
      _subscriptionBox.clear(),
      _billBox.clear(),
      _debtBox.clear(),
      _investmentBox.clear(),
      _investmentTypeBox.clear(),
      _goalBox.clear(),
      _paymentAccountBox.clear(),
      _accountTypeBox.clear(),
      _loanBox.clear(),
      _appSettingsBox.clear(),
    ]);
  }

  static Map<String, dynamic> getAllSettings() {
    return Map<String, dynamic>.from(_appSettingsBox.toMap());
  }

  // Export database to JSON
  static Future<String> exportToJSON() async {
    final data = {
      'expenses': _expenseBox.values.map((e) => e.toJson()).toList(),
      'categories': _categoryBox.values.map((c) => c.toJson()).toList(),
      'budgets': _budgetBox.values.map((b) => b.toJson()).toList(),
      'subscriptions': _subscriptionBox.values.map((s) => s.toJson()).toList(),
      'bills': _billBox.values.map((b) => b.toJson()).toList(),
      'debts': _debtBox.values.map((d) => d.toJson()).toList(),
      'investments': _investmentBox.values.map((i) => i.toJson()).toList(),
      'investmentTypes':
          _investmentTypeBox.values.map((t) => t.toJson()).toList(),
      'goals': _goalBox.values.map((g) => g.toJson()).toList(),
      'paymentAccounts':
          _paymentAccountBox.values.map((a) => a.toJson()).toList(),
      'accountTypes': _accountTypeBox.values.map((t) => t.toJson()).toList(),
      'loans': _loanBox.values.map((l) => l.toJson()).toList(),
      'appSettings': getAllSettings(),
      'exportDate': DateTime.now().toIso8601String(),
    };

    final jsonString = jsonEncode(data);
    return _encryptData(jsonString);
  }

  // Import database from JSON
  static Future<void> importFromJSON(String encryptedJson) async {
    try {
      final jsonString = _decryptData(encryptedJson);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      await clearAllData();

      // Import expenses
      final expenses =
          (data['expenses'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (var expenseData in expenses) {
        final expense = Expense.fromJson(expenseData);
        await addExpense(expense);
      }

      final categories =
          (data['categories'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (var categoryData in categories) {
        final category = ExpenseCategory.fromJson(categoryData);
        await addCategory(category);
      }

      final budgets =
          (data['budgets'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (var budgetData in budgets) {
        final budget = Budget.fromJson(budgetData);
        await updateBudget(budget);
      }

      if (budgets.isEmpty && data['budget'] != null) {
        final legacyBudget =
            Budget.fromJson(Map<String, dynamic>.from(data['budget'] as Map));
        await updateBudget(legacyBudget);
      }

      final subscriptions =
          (data['subscriptions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (var subscriptionData in subscriptions) {
        final subscription = Subscription.fromJson(subscriptionData);
        await addSubscription(subscription);
      }

      final bills =
          (data['bills'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (var billData in bills) {
        final bill = Bill.fromJson(billData);
        await addBill(bill);
      }

      final debts =
          (data['debts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (var debtData in debts) {
        final debt = Debt.fromJson(debtData);
        await addDebt(debt);
      }

      final investments =
          (data['investments'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (var investmentData in investments) {
        final investment = Investment.fromJson(investmentData);
        await addInvestment(investment);
      }

      final investmentTypes =
          (data['investmentTypes'] as List?)?.cast<Map<String, dynamic>>() ??
              [];
      for (var typeData in investmentTypes) {
        final type = InvestmentType.fromJson(typeData);
        await addInvestmentType(type);
      }

      final goals =
          (data['goals'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (var goalData in goals) {
        final goal = FinancialGoal.fromJson(goalData);
        await addGoal(goal);
      }

      final paymentAccounts =
          (data['paymentAccounts'] as List?)?.cast<Map<String, dynamic>>() ??
              [];
      for (var accountData in paymentAccounts) {
        final account = PaymentAccount(
          id: accountData['id'],
          name: accountData['name'],
          accountType: accountData['accountType'],
          accountNumber: accountData['accountNumber'],
          bankName: accountData['bankName'],
          balance: (accountData['balance'] as num?)?.toDouble() ?? 0.0,
          currency: accountData['currency'] ?? 'USD',
          color: accountData['color'],
          icon: accountData['icon'],
          isDefault: accountData['isDefault'] ?? false,
          isActive: accountData['isActive'] ?? true,
          createdAt: DateTime.parse(accountData['createdAt']),
          lastUpdated: accountData['lastUpdated'] != null
              ? DateTime.parse(accountData['lastUpdated'])
              : null,
          notes: accountData['notes'],
          creditLimit: accountData['creditLimit'] != null
              ? (accountData['creditLimit'] as num).toDouble()
              : null,
          expiryDate: accountData['expiryDate'] != null
              ? DateTime.parse(accountData['expiryDate'])
              : null,
          cardNetwork: accountData['cardNetwork'],
          linkedAccountId: accountData['linkedAccountId'],
        );
        await addPaymentAccount(account);
      }

      final accountTypes =
          (data['accountTypes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (var typeData in accountTypes) {
        final type = AccountTypeModel.fromJson(typeData);
        await addAccountType(type);
      }

      final loans =
          (data['loans'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (var loanData in loans) {
        final loan = Loan.fromJson(loanData);
        await addLoan(loan);
      }

      final appSettings =
          (data['appSettings'] as Map?)?.cast<String, dynamic>() ?? {};
      for (final entry in appSettings.entries) {
        await saveSetting(entry.key, entry.value);
      }
    } catch (e) {
      rethrow;
    }
  }

  static String _encryptData(String data) {
    final key =
        encrypt.Key.fromUtf8(_encryptionKey.padRight(32).substring(0, 32));
    final iv = encrypt.IV.fromSecureRandom(16);
    final cipher = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = cipher.encrypt(data, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  static String _decryptData(String encryptedData) {
    try {
      final parts = encryptedData.split(':');
      final iv = encrypt.IV.fromBase64(parts[0]);
      final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
      final key =
          encrypt.Key.fromUtf8(_encryptionKey.padRight(32).substring(0, 32));
      final cipher = encrypt.Encrypter(encrypt.AES(key));
      return cipher.decrypt(encrypted, iv: iv);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> close() async {
    await Hive.close();
  }
}

// Extension methods for JSON serialization
extension ExpenseJSON on Expense {
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'paymentMethod': paymentMethod,
        'date': date.toIso8601String(),
        'notes': notes,
        'tags': tags,
        'receiptImagePath': receiptImagePath,
        'isRecurring': isRecurring,
        'recurringFrequency': recurringFrequency,
        'currency': currency,
      };

  static Expense fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String,
        paymentMethod: json['paymentMethod'] as String,
        date: DateTime.parse(json['date'] as String),
        notes: json['notes'] as String?,
        tags: List<String>.from(json['tags'] as List? ?? []),
        receiptImagePath: json['receiptImagePath'] as String?,
        isRecurring: json['isRecurring'] as bool? ?? false,
        recurringFrequency: json['recurringFrequency'] as String?,
        currency: json['currency'] as String? ?? 'USD',
      );
}
