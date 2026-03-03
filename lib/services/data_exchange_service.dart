import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../database/hive_service.dart';
import '../features/expense/data/models/expense_model.dart';
import '../features/expense/data/models/expense_category_model.dart';
import '../features/accounts/data/models/payment_account_model.dart';
import '../features/budget/data/models/budget_model.dart';
import '../features/subscription/data/models/subscription_model.dart';
import '../features/bill/data/models/bill_model.dart';
import '../features/debt/data/models/debt_model.dart';
import '../features/investment/data/models/investment_model.dart';
import '../features/investment/data/models/investment_type_model.dart';
import '../features/goals/data/models/financial_goal_model.dart';
import '../features/accounts/data/models/account_type_model.dart';
import '../features/loan/data/models/loan_model.dart';

enum ExportFormat { json, csv }

class DataExchangeService {
  /// Export all data to JSON format
  static Future<String> exportToJSON() async {
    try {
      final expenses = HiveService.getAllExpenses();
      final categories = HiveService.getAllCategories();
      final accounts = HiveService.getAllPaymentAccounts();
      final budgets = HiveService.getAllBudgets();
      final subscriptions = HiveService.getAllSubscriptions();
      final bills = HiveService.getAllBills();
      final debts = HiveService.getAllDebts();
      final investments = HiveService.getAllInvestments();
      final goals = HiveService.getAllGoals();
      final loans = HiveService.getAllLoans();
      final accountTypes = await HiveService.getAllAccountTypes();
      final investmentTypes = await HiveService.getAllInvestmentTypes();
      final appSettings = HiveService.getAllSettings();

      final data = {
        'version': '2.0',
        'exportDate': DateTime.now().toIso8601String(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'categories': categories.map((c) => c.toJson()).toList(),
        'accounts': accounts.map((a) => a.toJson()).toList(),
        'budgets': budgets.map((b) => b.toJson()).toList(),
        'subscriptions': subscriptions.map((s) => s.toJson()).toList(),
        'bills': bills.map((b) => b.toJson()).toList(),
        'debts': debts.map((d) => d.toJson()).toList(),
        'investments': investments.map((i) => i.toJson()).toList(),
        'investmentTypes':
            investmentTypes.map((type) => type.toJson()).toList(),
        'goals': goals.map((g) => g.toJson()).toList(),
        'accountTypes': accountTypes.map((t) => t.toJson()).toList(),
        'loans': loans.map((l) => l.toJson()).toList(),
        'appSettings': appSettings,
      };

      return jsonEncode(data);
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  /// Export all data to CSV format
  static Future<String> exportToCSV() async {
    try {
      final expenses = HiveService.getAllExpenses();
      final categories = HiveService.getAllCategories();
      final accounts = HiveService.getAllPaymentAccounts();
      final budgets = HiveService.getAllBudgets();
      final subscriptions = HiveService.getAllSubscriptions();
      final bills = HiveService.getAllBills();
      final debts = HiveService.getAllDebts();
      final investments = HiveService.getAllInvestments();
      final goals = HiveService.getAllGoals();
      final loans = HiveService.getAllLoans();
      final accountTypes = await HiveService.getAllAccountTypes();
      final investmentTypes = await HiveService.getAllInvestmentTypes();
      final appSettings = HiveService.getAllSettings();

      final buffer = StringBuffer();

      // Export Expenses
      buffer.writeln('=== EXPENSES ===');
      buffer.writeln(
          'ID,Title,Amount,Category,PaymentMethod,Date,Notes,Tags,Currency,AccountID,IsRecurring,RecurringFrequency,ReceiptImagePath');
      for (var expense in expenses) {
        final tags = expense.tags.join(';');
        buffer.writeln(
            '"${_escapeCsv(expense.id)}","${_escapeCsv(expense.title)}","${expense.amount}","${_escapeCsv(expense.category)}","${_escapeCsv(expense.paymentMethod)}","${expense.date.toIso8601String()}","${_escapeCsv(expense.notes ?? '')}","${_escapeCsv(tags)}","${_escapeCsv(expense.currency)}","${_escapeCsv(expense.accountId ?? '')}","${expense.isRecurring}","${_escapeCsv(expense.recurringFrequency ?? '')}","${_escapeCsv(expense.receiptImagePath ?? '')}"');
      }

      buffer.writeln('\n=== CATEGORIES ===');
      buffer.writeln('ID,Name,Icon,Color,IsDefault,CreatedAt');
      for (var category in categories) {
        buffer.writeln(
            '"${_escapeCsv(category.id)}","${_escapeCsv(category.name)}","${_escapeCsv(category.icon)}","${_escapeCsv(category.color)}","${category.isDefault}","${category.createdAt.toIso8601String()}"');
      }

      buffer.writeln('\n=== ACCOUNTS ===');
      buffer.writeln(
          'ID,Name,AccountType,AccountNumber,BankName,Balance,Currency,Color,Icon,IsDefault,IsActive,CreatedAt,LastUpdated,Notes,CreditLimit,ExpiryDate,CardNetwork,LinkedAccountId');
      for (var account in accounts) {
        buffer.writeln(
            '"${_escapeCsv(account.id)}","${_escapeCsv(account.name)}","${_escapeCsv(account.accountType)}","${_escapeCsv(account.accountNumber ?? '')}","${_escapeCsv(account.bankName ?? '')}","${account.balance}","${_escapeCsv(account.currency)}","${_escapeCsv(account.color ?? '')}","${_escapeCsv(account.icon ?? '')}","${account.isDefault}","${account.isActive}","${account.createdAt.toIso8601String()}","${account.lastUpdated?.toIso8601String() ?? ''}","${_escapeCsv(account.notes ?? '')}","${account.creditLimit ?? ''}","${account.expiryDate?.toIso8601String() ?? ''}","${_escapeCsv(account.cardNetwork ?? '')}","${_escapeCsv(account.linkedAccountId ?? '')}"');
      }

      buffer.writeln('\n=== BUDGETS ===');
      buffer.writeln(
          'ID,MonthlyIncome,CategoryLimits,CreatedAt,UpdatedAt,Currency,EnableAlerts,Month,Year');
      for (var budget in budgets) {
        buffer.writeln(
            '"${_escapeCsv(budget.id)}","${budget.monthlyIncome}","${_escapeCsv(jsonEncode(budget.categoryLimits))}","${budget.createdAt.toIso8601String()}","${budget.updatedAt.toIso8601String()}","${_escapeCsv(budget.currency)}","${budget.enableAlerts}","${budget.month}","${budget.year}"');
      }

      buffer.writeln('\n=== SUBSCRIPTIONS ===');
      buffer.writeln(
          'ID,Name,Cost,BillingCycle,RenewalDate,AutoRenewal,CreatedAt,Currency,Notes,Category');
      for (var subscription in subscriptions) {
        buffer.writeln(
            '"${_escapeCsv(subscription.id)}","${_escapeCsv(subscription.name)}","${subscription.cost}","${_escapeCsv(subscription.billingCycle)}","${subscription.renewalDate.toIso8601String()}","${subscription.autoRenewal}","${subscription.createdAt.toIso8601String()}","${_escapeCsv(subscription.currency)}","${_escapeCsv(subscription.notes ?? '')}","${_escapeCsv(subscription.category ?? '')}"');
      }

      buffer.writeln('\n=== BILLS ===');
      buffer.writeln(
          'ID,Name,Amount,DueDate,IsPaid,IsRecurring,RecurringFrequency,CreatedAt,Currency,Notes,PaidDate');
      for (var bill in bills) {
        buffer.writeln(
            '"${_escapeCsv(bill.id)}","${_escapeCsv(bill.name)}","${bill.amount}","${bill.dueDate.toIso8601String()}","${bill.isPaid}","${bill.isRecurring}","${_escapeCsv(bill.recurringFrequency ?? '')}","${bill.createdAt.toIso8601String()}","${_escapeCsv(bill.currency)}","${_escapeCsv(bill.notes ?? '')}","${bill.paidDate?.toIso8601String() ?? ''}"');
      }

      buffer.writeln('\n=== DEBTS ===');
      buffer.writeln(
          'ID,LoanName,PrincipalAmount,InterestRate,TenureMonths,MonthlyEmi,RemainingBalance,StartDate,EndDate,CreatedAt,Payments,Currency');
      for (var debt in debts) {
        final paymentsJson =
            jsonEncode(debt.payments.map((p) => p.toJson()).toList());
        buffer.writeln(
            '"${_escapeCsv(debt.id)}","${_escapeCsv(debt.loanName)}","${debt.principalAmount}","${debt.interestRate}","${debt.tenureMonths}","${debt.monthlyEmi}","${debt.remainingBalance}","${debt.startDate.toIso8601String()}","${debt.endDate?.toIso8601String() ?? ''}","${debt.createdAt.toIso8601String()}","${_escapeCsv(paymentsJson)}","${_escapeCsv(debt.currency)}"');
      }

      buffer.writeln('\n=== INVESTMENTS ===');
      buffer.writeln(
          'ID,Name,Type,Quantity,BuyPrice,CurrentPrice,InvestedAmount,CurrentValue,PurchaseDate,CreatedAt,Currency,Notes');
      for (var investment in investments) {
        buffer.writeln(
            '"${_escapeCsv(investment.id)}","${_escapeCsv(investment.name)}","${_escapeCsv(investment.type)}","${investment.quantity ?? ''}","${investment.buyPrice ?? ''}","${investment.currentPrice ?? ''}","${investment.investedAmount ?? ''}","${investment.currentValue ?? ''}","${investment.purchaseDate?.toIso8601String() ?? ''}","${investment.createdAt.toIso8601String()}","${_escapeCsv(investment.currency)}","${_escapeCsv(investment.notes ?? '')}"');
      }

      buffer.writeln('\n=== INVESTMENT TYPES ===');
      buffer.writeln('ID,Name,Order,CreatedAt');
      for (var type in investmentTypes) {
        buffer.writeln(
            '"${_escapeCsv(type.id)}","${_escapeCsv(type.name)}","${type.order}","${type.createdAt.toIso8601String()}"');
      }

      buffer.writeln('\n=== GOALS ===');
      buffer.writeln(
          'ID,GoalName,TargetAmount,CurrentAmount,TargetDate,CreatedAt,Category,Currency,Description,IsCompleted,CompletedDate');
      for (var goal in goals) {
        buffer.writeln(
            '"${_escapeCsv(goal.id)}","${_escapeCsv(goal.goalName)}","${goal.targetAmount}","${goal.currentAmount}","${goal.targetDate.toIso8601String()}","${goal.createdAt.toIso8601String()}","${_escapeCsv(goal.category)}","${_escapeCsv(goal.currency)}","${_escapeCsv(goal.description ?? '')}","${goal.isCompleted}","${goal.completedDate?.toIso8601String() ?? ''}"');
      }

      buffer.writeln('\n=== ACCOUNT TYPES ===');
      buffer.writeln('ID,Name,Icon,Color,IsDefault,Order,CreatedAt,IsActive');
      for (var type in accountTypes) {
        buffer.writeln(
            '"${_escapeCsv(type.id)}","${_escapeCsv(type.name)}","${_escapeCsv(type.icon ?? '')}","${_escapeCsv(type.color ?? '')}","${type.isDefault}","${type.order}","${type.createdAt.toIso8601String()}","${type.isActive}"');
      }

      buffer.writeln('\n=== LOANS ===');
      buffer.writeln(
          'ID,Lender,BorrowedAmount,InterestRate,TenureMonths,MonthlyEmi,StartDate,EndDate,EmiDate,PaidAmount,CreatedAt,Currency,Notes,AccountId');
      for (var loan in loans) {
        buffer.writeln(
            '"${_escapeCsv(loan.id)}","${_escapeCsv(loan.lender)}","${loan.borrowedAmount}","${loan.interestRate}","${loan.tenureMonths}","${loan.monthlyEmi}","${loan.startDate.toIso8601String()}","${loan.endDate.toIso8601String()}","${loan.emiDate}","${loan.paidAmount}","${loan.createdAt.toIso8601String()}","${_escapeCsv(loan.currency)}","${_escapeCsv(loan.notes ?? '')}","${_escapeCsv(loan.accountId ?? '')}"');
      }

      buffer.writeln('\n=== APP SETTINGS ===');
      buffer.writeln('Key,Value');
      for (final entry in appSettings.entries) {
        buffer.writeln(
            '"${_escapeCsv(entry.key)}","${_escapeCsv(jsonEncode(entry.value))}"');
      }

      return buffer.toString();
    } catch (e) {
      throw Exception('Failed to export to CSV: $e');
    }
  }

  /// Save exported data to file
  static Future<String> saveExportFile(String data, ExportFormat format) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${directory.path}/fintrack_exports');

      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = format == ExportFormat.json
          ? 'fintrack_export_$timestamp.json'
          : 'fintrack_export_$timestamp.csv';
      final file = File('${exportDir.path}/$fileName');

      await file.writeAsString(data);
      return file.path;
    } catch (e) {
      throw Exception('Failed to save export file: $e');
    }
  }

  /// Share exported file
  static Future<void> shareExportFile(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)]);
    } catch (e) {
      throw Exception('Failed to share file: $e');
    }
  }

  /// Import data from file
  static Future<Map<String, dynamic>> importFromFile({
    required bool mergeData,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Select backup file (JSON only)',
      );

      if (result == null || result.files.isEmpty) {
        return {'success': false, 'message': 'No file selected'};
      }

      final selectedPath = result.files.first.path;
      if (selectedPath == null || selectedPath.trim().isEmpty) {
        return {'success': false, 'message': 'Invalid file path'};
      }
      if (!selectedPath.toLowerCase().endsWith('.json')) {
        return {
          'success': false,
          'message': 'Only JSON backup files can be imported',
        };
      }

      final file = File(selectedPath);
      if (!await file.exists()) {
        return {'success': false, 'message': 'File not found'};
      }

      final jsonString = await file.readAsString();
      if (jsonString.isEmpty) {
        return {'success': false, 'message': 'File is empty'};
      }

      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate JSON structure
      if (!_validateJsonStructure(data)) {
        return {'success': false, 'message': 'Invalid backup file format'};
      }

      if (mergeData) {
        await _mergeData(data);
      } else {
        await _replaceData(data);
      }

      return {'success': true, 'message': 'Data imported successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Import failed: ${e.toString()}'};
    }
  }

  /// Merge imported data with existing data
  static Future<void> _mergeData(Map<String, dynamic> data) async {
    try {
      if (data['expenses'] != null) {
        for (var expenseData in data['expenses']) {
          final expense =
              Expense.fromJson(Map<String, dynamic>.from(expenseData as Map));
          await HiveService.addExpense(expense);
        }
      }

      if (data['categories'] != null) {
        for (var catData in data['categories']) {
          final category = ExpenseCategory.fromJson(
              Map<String, dynamic>.from(catData as Map));
          await HiveService.addCategory(category);
        }
      }

      final accountsData = data['accounts'] ?? data['paymentAccounts'];
      if (accountsData != null) {
        for (var accountData in accountsData) {
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
            billingCycleDay: accountData['billingCycleDay'] as int?,
          );
          await HiveService.addPaymentAccount(account);
        }
      }

      if (data['budgets'] != null) {
        for (var budgetData in data['budgets']) {
          final budget =
              Budget.fromJson(Map<String, dynamic>.from(budgetData as Map));
          await HiveService.updateBudget(budget);
        }
      }

      if (data['budgets'] == null && data['budget'] != null) {
        final budget =
            Budget.fromJson(Map<String, dynamic>.from(data['budget'] as Map));
        await HiveService.updateBudget(budget);
      }

      if (data['subscriptions'] != null) {
        for (var subscriptionData in data['subscriptions']) {
          final subscription = Subscription.fromJson(
              Map<String, dynamic>.from(subscriptionData as Map));
          await HiveService.addSubscription(subscription);
        }
      }

      if (data['bills'] != null) {
        for (var billData in data['bills']) {
          final bill =
              Bill.fromJson(Map<String, dynamic>.from(billData as Map));
          await HiveService.addBill(bill);
        }
      }

      if (data['debts'] != null) {
        for (var debtData in data['debts']) {
          final debt =
              Debt.fromJson(Map<String, dynamic>.from(debtData as Map));
          await HiveService.addDebt(debt);
        }
      }

      if (data['investments'] != null) {
        for (var investmentData in data['investments']) {
          final investment = Investment.fromJson(
              Map<String, dynamic>.from(investmentData as Map));
          await HiveService.addInvestment(investment);
        }
      }

      if (data['investmentTypes'] != null) {
        for (var typeData in data['investmentTypes']) {
          final type = InvestmentType.fromJson(
              Map<String, dynamic>.from(typeData as Map));
          await HiveService.addInvestmentType(type);
        }
      }

      if (data['goals'] != null) {
        for (var goalData in data['goals']) {
          final goal = FinancialGoal.fromJson(
              Map<String, dynamic>.from(goalData as Map));
          await HiveService.addGoal(goal);
        }
      }

      if (data['accountTypes'] != null) {
        for (var typeData in data['accountTypes']) {
          final type = AccountTypeModel.fromJson(
              Map<String, dynamic>.from(typeData as Map));
          await HiveService.addAccountType(type);
        }
      }

      if (data['loans'] != null) {
        for (var loanData in data['loans']) {
          final loan =
              Loan.fromJson(Map<String, dynamic>.from(loanData as Map));
          await HiveService.addLoan(loan);
        }
      }

      if (data['appSettings'] != null) {
        final appSettings =
            (data['appSettings'] as Map?)?.cast<String, dynamic>() ?? {};
        for (final entry in appSettings.entries) {
          await HiveService.saveSetting(entry.key, entry.value);
        }
      }
    } catch (e) {
      throw Exception('Failed to merge data: $e');
    }
  }

  /// Replace all data with imported data
  static Future<void> _replaceData(Map<String, dynamic> data) async {
    try {
      // Clear existing data
      await HiveService.clearAllData();

      // Import new data
      await _mergeData(data);
    } catch (e) {
      throw Exception('Failed to replace data: $e');
    }
  }

  /// Validate JSON structure
  static bool _validateJsonStructure(Map<String, dynamic> data) {
    final hasAnyDataKey = data.keys.any((key) => [
          'expenses',
          'categories',
          'accounts',
          'paymentAccounts',
          'budgets',
          'subscriptions',
          'bills',
          'debts',
          'investments',
          'investmentTypes',
          'goals',
          'accountTypes',
          'loans',
          'appSettings',
        ].contains(key));

    return (data.containsKey('version') || data.containsKey('exportDate')) &&
        hasAnyDataKey;
  }

  /// Escape CSV special characters
  static String _escapeCsv(String value) {
    if (value.contains('"') || value.contains(',') || value.contains('\n')) {
      return value.replaceAll('"', '""');
    }
    return value;
  }
}
