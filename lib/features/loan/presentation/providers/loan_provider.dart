import 'package:flutter/foundation.dart';
import 'package:fintrack/database/hive_service.dart';
import 'package:fintrack/features/loan/data/models/loan_model.dart';

class LoanProvider extends ChangeNotifier {
  List<Loan> _loans = [];

  List<Loan> get loans => _loans;

  List<Loan> get activeLoans =>
      _loans.where((loan) => !loan.isCompleted).toList();

  List<Loan> get completedLoans =>
      _loans.where((loan) => loan.isCompleted).toList();

  LoanProvider() {
    try {
      _loadLoans();
    } catch (e) {
      // HiveService might not be initialized yet during hot restart
      _loans = [];
    }
  }

  Future<void> initLoans() async {
    _loadLoans();
    notifyListeners();
  }

  void _loadLoans() {
    try {
      _loans = HiveService.getAllLoans();
    } catch (e) {
      _loans = [];
    }
  }

  Future<void> addLoan(Loan loan) async {
    try {
      await HiveService.addLoan(loan);
      _loans.add(loan);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateLoan(Loan loan) async {
    try {
      await HiveService.updateLoan(loan);
      final index = _loans.indexWhere((l) => l.id == loan.id);
      if (index != -1) {
        _loans[index] = loan;
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteLoan(String id) async {
    try {
      await HiveService.deleteLoan(id);
      _loans.removeWhere((l) => l.id == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> makePayment(String loanId, double amount) async {
    try {
      final loan = _loans.firstWhere((l) => l.id == loanId);
      final now = DateTime.now();
      final updatedLoan = loan.copyWith(
        paidAmount: loan.paidAmount + amount,
        lastPaymentDate: now, // Track when payment was made
      );

      if (kDebugMode) {
        print('💰 Making payment for loan: ${loan.lender} (${loan.id})');
        print('  Amount: $amount');
        print('  Previous paid amount: ${loan.paidAmount}');
        print('  New paid amount: ${updatedLoan.paidAmount}');
        print('  Last payment date: $now');
        print('  Next EMI date: ${loan.nextEmiDate}');
      }

      await updateLoan(updatedLoan);
    } catch (e) {
      rethrow;
    }
  }

  double getTotalOutstandingAmount() {
    return _loans.fold<double>(
      0,
      (sum, loan) => sum + (loan.isCompleted ? 0 : loan.pendingAmount),
    );
  }

  double getTotalMonthlyEmi() {
    return activeLoans.fold<double>(
      0,
      (sum, loan) => sum + loan.monthlyEmi,
    );
  }

  double getTotalBorrowedAmount() {
    return _loans.fold<double>(
      0,
      (sum, loan) => sum + loan.borrowedAmount,
    );
  }

  double getTotalPaidAmount() {
    return _loans.fold<double>(
      0,
      (sum, loan) => sum + loan.paidAmount,
    );
  }

  double getTotalInterestAmount() {
    return _loans.fold<double>(
      0,
      (sum, loan) => sum + loan.totalInterest,
    );
  }

  List<Loan> getUpcomingEmiLoans() {
    final now = DateTime.now();
    final upcomingLoans = activeLoans.where((loan) {
      final nextEmi = loan.nextEmiDate;
      if (nextEmi == null) return false;

      final daysUntilEmi = nextEmi.difference(now).inDays;
      return daysUntilEmi >= 0 && daysUntilEmi <= 7;
    }).toList();

    upcomingLoans.sort((a, b) {
      final aNextEmi = a.nextEmiDate;
      final bNextEmi = b.nextEmiDate;
      if (aNextEmi == null) return 1;
      if (bNextEmi == null) return -1;
      return aNextEmi.compareTo(bNextEmi);
    });

    return upcomingLoans;
  }

  Future<void> refreshData() async {
    _loadLoans();
    notifyListeners();
  }
}
