import 'package:flutter/foundation.dart';
import 'package:fintrack/database/hive_service.dart';
import 'package:fintrack/features/bill/data/models/bill_model.dart';

class BillProvider extends ChangeNotifier {
  List<Bill> _bills = [];

  List<Bill> get bills => _bills;
  List<Bill> get upcomingBills => HiveService.getUpcomingBills();
  List<Bill> get overdueBills => HiveService.getOverdueBills();

  BillProvider() {
    _loadBills();
  }

  Future<void> initBills() async {
    _loadBills();
    notifyListeners();
  }

  void _loadBills() {
    _bills = HiveService.getAllBills();
  }

  Future<void> addBill(Bill bill) async {
    try {
      await HiveService.addBill(bill);
      _bills.add(bill);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateBill(Bill bill) async {
    try {
      await HiveService.updateBill(bill);
      final index = _bills.indexWhere((b) => b.id == bill.id);
      if (index != -1) {
        _bills[index] = bill;
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBill(String id) async {
    try {
      await HiveService.deleteBill(id);
      _bills.removeWhere((b) => b.id == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAsPaid(String billId) async {
    try {
      final bill = _bills.firstWhere((b) => b.id == billId);
      final updatedBill = bill.copyWith(
        isPaid: true,
        paidDate: DateTime.now(),
      );
      await updateBill(updatedBill);
    } catch (e) {
      rethrow;
    }
  }

  double getTotalOverdueBillsAmount() {
    return overdueBills.fold<double>(0, (sum, b) => sum + b.amount);
  }

  double getTotalUnpaidBillsAmount() {
    return _bills
        .where((b) => !b.isPaid)
        .fold<double>(0, (sum, b) => sum + b.amount);
  }

  int getOverdueBillsCount() {
    return overdueBills.length;
  }

  int getUpcomingBillsCount() {
    return upcomingBills.length;
  }

  Future<void> refreshData() async {
    _loadBills();
    notifyListeners();
  }
}
