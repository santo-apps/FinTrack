import 'package:flutter/foundation.dart';
import 'package:fintrack/features/investment/data/models/investment_type_model.dart';
import 'package:fintrack/database/hive_service.dart';

class InvestmentTypeProvider with ChangeNotifier {
  List<InvestmentType> _investmentTypes = [];

  InvestmentTypeProvider() {
    _loadInvestmentTypes();
    // Remove any duplicate entries first
    removeDuplicateTypes();
    // Initialize default types on first use
    initializeDefaultTypes();
  }

  List<InvestmentType> get investmentTypes =>
      List.unmodifiable(_investmentTypes);

  Future<void> _loadInvestmentTypes() async {
    _investmentTypes = await HiveService.getAllInvestmentTypes();
    _investmentTypes.sort((a, b) => a.order.compareTo(b.order));
    notifyListeners();
  }

  Future<void> addInvestmentType(InvestmentType type) async {
    await HiveService.addInvestmentType(type);
    await _loadInvestmentTypes();
  }

  Future<void> updateInvestmentType(InvestmentType type) async {
    await HiveService.updateInvestmentType(type);
    await _loadInvestmentTypes();
  }

  Future<void> deleteInvestmentType(String id) async {
    await HiveService.deleteInvestmentType(id);
    await _loadInvestmentTypes();
  }

  Future<void> reorderInvestmentTypes(
      List<InvestmentType> reorderedTypes) async {
    for (int i = 0; i < reorderedTypes.length; i++) {
      final updatedType = reorderedTypes[i].copyWith(order: i);
      await HiveService.updateInvestmentType(updatedType);
    }
    await _loadInvestmentTypes();
  }

  Future<void> removeDuplicateTypes() async {
    final allTypes = await HiveService.getAllInvestmentTypes();

    // Group types by name
    final Map<String, List<InvestmentType>> typesByName = {};
    for (var type in allTypes) {
      if (!typesByName.containsKey(type.name)) {
        typesByName[type.name] = [];
      }
      typesByName[type.name]!.add(type);
    }

    // Remove duplicates, keeping only the first occurrence
    for (var entry in typesByName.entries) {
      if (entry.value.length > 1) {
        // Sort by creation date to keep the oldest one
        entry.value.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        // Delete all but the first one
        for (int i = 1; i < entry.value.length; i++) {
          await HiveService.deleteInvestmentType(entry.value[i].id);
        }
      }
    }

    // Reload types after cleanup
    if (typesByName.values.any((list) => list.length > 1)) {
      await _loadInvestmentTypes();
    }
  }

  Future<void> initializeDefaultTypes() async {
    // Check database directly, not just the in-memory list
    final existingTypes = await HiveService.getAllInvestmentTypes();
    if (existingTypes.isEmpty) {
      final defaultTypes = [
        'Stocks',
        'Mutual Fund',
        'Smallcase',
        'Crypto',
        'Gold',
        'Silver',
        'ULIP',
        'PPF',
        'Bonds',
        'FD',
        'RD',
        'Savings',
        'Real Estate',
        'EPF',
        'Gratuity',
        'Cash',
        'Other',
      ];

      for (int i = 0; i < defaultTypes.length; i++) {
        final type = InvestmentType(
          id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
          name: defaultTypes[i],
          order: i,
          createdAt: DateTime.now(),
        );
        await addInvestmentType(type);
      }
    }
  }
}
