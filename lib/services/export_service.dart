import 'package:csv/csv.dart';
import '../database/hive_service.dart';

class ExportService {
  static Future<String> exportToCSV() async {
    final expenses = HiveService.getAllExpenses();

    final List<List<dynamic>> csvData = [
      [
        'Date',
        'Title',
        'Category',
        'Amount',
        'Payment Method',
        'Tags',
        'Notes'
      ],
    ];

    for (var expense in expenses) {
      csvData.add([
        expense.date.toIso8601String().split('T')[0],
        expense.title,
        expense.category,
        expense.amount,
        expense.paymentMethod,
        expense.tags.join(';'),
        expense.notes ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(csvData);
  }

  static Future<String> exportBudgetToCSV() async {
    final budgets = HiveService.getAllBudgets();
    if (budgets.isEmpty) return '';

    final List<List<dynamic>> csvData = [
      ['Month', 'Year', 'Category', 'Budget Limit', 'Currency'],
    ];

    for (final budget in budgets) {
      budget.categoryLimits.forEach((category, limit) {
        csvData
            .add([budget.month, budget.year, category, limit, budget.currency]);
      });
    }

    return const ListToCsvConverter().convert(csvData);
  }

  static Future<String> exportSubscriptionsToCSV() async {
    final subscriptions = HiveService.getAllSubscriptions();

    final List<List<dynamic>> csvData = [
      ['Name', 'Cost', 'Billing Cycle', 'Renewal Date', 'Currency', 'Notes'],
    ];

    for (var sub in subscriptions) {
      csvData.add([
        sub.name,
        sub.cost,
        sub.billingCycle,
        sub.renewalDate.toIso8601String().split('T')[0],
        sub.currency,
        sub.notes ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(csvData);
  }

  static Future<String> exportInvestmentsToCSV() async {
    final investments = HiveService.getAllInvestments();

    final List<List<dynamic>> csvData = [
      [
        'Name',
        'Type',
        'Quantity',
        'Buy Price',
        'Current Price',
        'Total Investment',
        'Current Value',
        'Gain/Loss',
        'Gain/Loss %'
      ],
    ];

    for (var inv in investments) {
      csvData.add([
        inv.name,
        inv.type,
        inv.quantity,
        inv.buyPrice,
        inv.currentPrice,
        inv.getTotalInvestmentValue(),
        inv.getCurrentValue(),
        inv.getGainLoss(),
        inv.getGainLossPercentage().toStringAsFixed(2),
      ]);
    }

    return const ListToCsvConverter().convert(csvData);
  }
}
