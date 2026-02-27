import 'package:flutter/foundation.dart';
import 'package:fintrack/database/hive_service.dart';
import 'package:fintrack/features/investment/data/models/investment_model.dart';

class InvestmentProvider extends ChangeNotifier {
  List<Investment> _investments = [];

  List<Investment> get investments => _investments;

  InvestmentProvider() {
    _loadInvestments();
  }

  Future<void> initInvestments() async {
    _loadInvestments();
    notifyListeners();
  }

  void _loadInvestments() {
    _investments = HiveService.getAllInvestments();
  }

  Future<void> addInvestment(Investment investment) async {
    try {
      await HiveService.addInvestment(investment);
      _investments.add(investment);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateInvestment(Investment investment) async {
    try {
      await HiveService.updateInvestment(investment);
      final index = _investments.indexWhere((i) => i.id == investment.id);
      if (index != -1) {
        _investments[index] = investment;
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteInvestment(String id) async {
    try {
      await HiveService.deleteInvestment(id);
      _investments.removeWhere((i) => i.id == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  double getTotalPortfolioValue() {
    return HiveService.getTotalPortfolioValue();
  }

  double getTotalInvestmentCost() {
    return HiveService.getTotalInvestmentCost();
  }

  double getTotalGainLoss() {
    return getTotalPortfolioValue() - getTotalInvestmentCost();
  }

  double getTotalGainLossPercentage() {
    final cost = getTotalInvestmentCost();
    if (cost == 0) return 0;
    return ((getTotalGainLoss() / cost) * 100);
  }

  bool isPortfolioInProfit() {
    return getTotalGainLoss() >= 0;
  }

  Map<String, double> getAssetAllocation() {
    final allocation = <String, double>{};
    final total = getTotalPortfolioValue();

    if (total == 0) return allocation;

    for (var investment in _investments) {
      final value = investment.getCurrentValue();
      final percentage = (value / total) * 100;
      allocation[investment.type] =
          (allocation[investment.type] ?? 0) + percentage;
    }

    return allocation;
  }

  Future<void> refreshData() async {
    _loadInvestments();
    notifyListeners();
  }
}
