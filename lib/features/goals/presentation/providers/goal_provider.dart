import 'package:flutter/foundation.dart';
import 'package:fintrack/database/hive_service.dart';
import 'package:fintrack/features/goals/data/models/financial_goal_model.dart';

class GoalProvider extends ChangeNotifier {
  List<FinancialGoal> _goals = [];

  List<FinancialGoal> get goals => _goals;
  List<FinancialGoal> get activeGoals =>
      _goals.where((g) => !g.isCompleted).toList();

  GoalProvider() {
    _loadGoals();
  }

  Future<void> initGoals() async {
    _loadGoals();
    notifyListeners();
  }

  void _loadGoals() {
    _goals = HiveService.getAllGoals();
  }

  Future<void> addGoal(FinancialGoal goal) async {
    try {
      await HiveService.addGoal(goal);
      _goals.add(goal);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateGoal(FinancialGoal goal) async {
    try {
      await HiveService.updateGoal(goal);
      final index = _goals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        _goals[index] = goal;
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      await HiveService.deleteGoal(id);
      _goals.removeWhere((g) => g.id == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> completeGoal(String goalId) async {
    try {
      final goal = _goals.firstWhere((g) => g.id == goalId);
      final updatedGoal = goal.copyWith(
        isCompleted: true,
        completedDate: DateTime.now(),
      );
      await updateGoal(updatedGoal);
    } catch (e) {
      rethrow;
    }
  }

  double getTotalGoalAmount() {
    return activeGoals.fold<double>(0, (sum, g) => sum + g.targetAmount);
  }

  double getTotalSavedAmount() {
    return activeGoals.fold<double>(0, (sum, g) => sum + g.currentAmount);
  }

  double getOverallProgressPercentage() {
    final total = getTotalGoalAmount();
    if (total == 0) return 0;
    return ((getTotalSavedAmount() / total) * 100).clamp(0, 100);
  }

  Future<void> refreshData() async {
    _loadGoals();
    notifyListeners();
  }
}
