import 'package:flutter/foundation.dart';
import 'package:fintrack/database/hive_service.dart';
import 'package:fintrack/features/subscription/data/models/subscription_model.dart';

class SubscriptionProvider extends ChangeNotifier {
  List<Subscription> _subscriptions = [];

  List<Subscription> get subscriptions => _subscriptions;

  SubscriptionProvider() {
    _loadSubscriptions();
  }

  Future<void> initSubscriptions() async {
    _loadSubscriptions();
    notifyListeners();
  }

  void _loadSubscriptions() {
    _subscriptions = HiveService.getAllSubscriptions();
  }

  Future<void> addSubscription(Subscription subscription) async {
    try {
      await HiveService.addSubscription(subscription);
      _subscriptions.add(subscription);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateSubscription(Subscription subscription) async {
    try {
      await HiveService.updateSubscription(subscription);
      final index = _subscriptions.indexWhere((s) => s.id == subscription.id);
      if (index != -1) {
        _subscriptions[index] = subscription;
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSubscription(String id) async {
    try {
      await HiveService.deleteSubscription(id);
      _subscriptions.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  double getMonthlySubscriptionTotal() {
    return _subscriptions.fold<double>(
      0,
      (sum, sub) => sum + sub.getMonthlyAmount(),
    );
  }

  List<Subscription> getUpcomingRenewals() {
    final now = DateTime.now();
    final upcoming = _subscriptions
        .where((s) => s.renewalDate.isAfter(now))
        .toList()
      ..sort((a, b) => a.renewalDate.compareTo(b.renewalDate));
    return upcoming;
  }

  List<Subscription> getOverdueSubscriptions() {
    final now = DateTime.now();
    return _subscriptions.where((s) => s.renewalDate.isBefore(now)).toList();
  }

  Future<void> refreshData() async {
    _loadSubscriptions();
    notifyListeners();
  }
}
