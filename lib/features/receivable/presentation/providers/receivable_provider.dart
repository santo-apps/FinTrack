import 'package:flutter/foundation.dart';
import 'package:fintrack/database/hive_service.dart';
import 'package:fintrack/features/accounts/data/models/payment_account_model.dart';
import 'package:fintrack/features/expense/data/models/expense_model.dart';
import 'package:fintrack/features/receivable/data/models/receivable_model.dart';

class ReceivableProvider extends ChangeNotifier {
  static const String _receivableIncomePrefix = 'receivable_income_';
  List<Receivable> _receivables = [];

  double _normalizeAmount(double value) {
    return (value * 100).roundToDouble() / 100;
  }

  List<Receivable> get receivables => _receivables;

  ReceivableProvider() {
    _loadData();
  }

  void _loadData() {
    _receivables = HiveService.getAllReceivables();
  }

  Future<void> addReceivable(Receivable receivable) async {
    if (receivable.isRecurring && receivable.recurringEndDate != null) {
      final series = _buildRecurringSeries(receivable);
      for (final item in series) {
        await HiveService.addReceivable(item);
      }
      _receivables.addAll(series);
    } else {
      await HiveService.addReceivable(receivable);
      _receivables.add(receivable);
    }
    notifyListeners();
  }

  Future<void> updateReceivable(Receivable receivable) async {
    await HiveService.updateReceivable(receivable);
    final index = _receivables.indexWhere((r) => r.id == receivable.id);
    if (index != -1) {
      _receivables[index] = receivable;
      notifyListeners();
    }
  }

  Future<void> saveEditedReceivable({
    required Receivable original,
    required Receivable edited,
  }) async {
    final enablingRecurring =
        edited.isRecurring && edited.recurringEndDate != null;

    if (!enablingRecurring) {
      await updateReceivable(edited.copyWith(
        recurrenceGroupId: null,
      ));
      return;
    }

    final groupId = original.recurrenceGroupId ?? original.id;

    final existingSeries = _receivables
        .where((r) => r.recurrenceGroupId == groupId || r.id == original.id)
        .toList();

    for (final item in existingSeries) {
      await HiveService.deleteReceivable(item.id);
    }
    _receivables.removeWhere(
        (r) => r.recurrenceGroupId == groupId || r.id == original.id);

    final base = edited.copyWith(
      id: groupId,
      isReceived: false,
      receivedDate: null,
      receivedAmount: 0,
      recurrenceGroupId: groupId,
    );

    final series = _buildRecurringSeries(base);
    for (final item in series) {
      await HiveService.addReceivable(item);
    }
    _receivables.addAll(series);
    notifyListeners();
  }

  Future<void> deleteReceivable(String id) async {
    await HiveService.deleteReceivable(id);
    _receivables.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  Future<void> markAsReceived(Receivable receivable) async {
    final current = _receivables.firstWhere(
      (r) => r.id == receivable.id,
      orElse: () => receivable,
    );
    if (current.isReceived) {
      return;
    }

    final receiveAmount = current.outstandingAmount;
    if (receiveAmount <= 0) {
      return;
    }

    await _applyMappedAccountDelta(
      current,
      amount: receiveAmount,
      isReceiveAction: true,
    );

    final updated = current.copyWith(
      isReceived: true,
      receivedDate: DateTime.now(),
      receivedAmount: current.amount,
    );
    await updateReceivable(updated);
    await _syncLinkedIncomeTransaction(updated);
  }

  Future<void> markAsPending(Receivable receivable) async {
    final current = _receivables.firstWhere(
      (r) => r.id == receivable.id,
      orElse: () => receivable,
    );
    if (current.receivedAmount <= 0) {
      return;
    }

    await _applyMappedAccountDelta(
      current,
      amount: current.receivedAmount,
      isReceiveAction: false,
    );

    final updated = current.copyWith(
      isReceived: false,
      receivedDate: null,
      receivedAmount: 0,
    );
    await updateReceivable(updated);
    await _deleteLinkedIncomeTransaction(current.id);
    await refreshData();
  }

  Future<void> markPartialReceived(
    Receivable receivable,
    double amount,
  ) async {
    final current = _receivables.firstWhere(
      (r) => r.id == receivable.id,
      orElse: () => receivable,
    );

    if (amount <= 0) {
      return;
    }

    final delta =
        amount > current.outstandingAmount ? current.outstandingAmount : amount;
    if (delta <= 0) {
      return;
    }

    await _applyMappedAccountDelta(
      current,
      amount: delta,
      isReceiveAction: true,
    );

    final updatedReceived = _normalizeAmount(current.receivedAmount + delta);
    final isFullyReceived = updatedReceived >= _normalizeAmount(current.amount);

    final updated = current.copyWith(
      receivedAmount:
          isFullyReceived ? _normalizeAmount(current.amount) : updatedReceived,
      isReceived: isFullyReceived,
      receivedDate: DateTime.now(),
    );

    await updateReceivable(updated);
    await _syncLinkedIncomeTransaction(updated);
  }

  List<Receivable> getPendingForMonth(DateTime month) {
    return _receivables.where((r) {
      if (r.outstandingAmount <= 0) return false;
      return r.dueDate.year == month.year && r.dueDate.month == month.month;
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  List<Receivable> getReceivedForMonth(DateTime month) {
    return _receivables.where((r) {
      if (r.receivedAmount <= 0 || r.receivedDate == null) return false;
      final date = r.receivedDate!;
      return date.year == month.year && date.month == month.month;
    }).toList()
      ..sort((a, b) => b.receivedDate!.compareTo(a.receivedDate!));
  }

  double getPendingTotalForMonth(DateTime month) {
    return getPendingForMonth(month)
        .fold<double>(0, (sum, r) => sum + r.outstandingAmount);
  }

  int getReminderWindowCount(DateTime month) {
    return getPendingForMonth(month).where((r) => r.isInReminderWindow).length;
  }

  Future<void> refreshData() async {
    _loadData();
    notifyListeners();
  }

  double getOverallPendingTotal() {
    return _receivables
        .where((r) => r.outstandingAmount > 0)
        .fold<double>(0, (sum, r) => sum + r.outstandingAmount);
  }

  double getOverallReceivedTotal() {
    return _receivables
        .where((r) => r.receivedAmount > 0)
        .fold<double>(0, (sum, r) => sum + r.receivedAmount);
  }

  int getOverallPendingCount() {
    return _receivables.where((r) => r.outstandingAmount > 0).length;
  }

  int getOverallReceivedCount() {
    return _receivables.where((r) => r.receivedAmount > 0).length;
  }

  Future<void> _applyMappedAccountDelta(
    Receivable receivable, {
    required double amount,
    required bool isReceiveAction,
  }) async {
    final accountId = receivable.accountId?.trim();
    if (accountId == null || accountId.isEmpty) {
      return;
    }

    final accounts = HiveService.getAllPaymentAccounts();
    PaymentAccount? account;
    try {
      account = accounts.firstWhere((a) => a.id == accountId);
    } catch (_) {
      return;
    }

    if (amount <= 0) {
      return;
    }

    final isCreditCard = account.accountType.toLowerCase().contains('credit');
    final receiveDelta = isCreditCard ? -amount : amount;
    final delta = isReceiveAction ? receiveDelta : -receiveDelta;

    final updatedAccount = account.copyWith(balance: account.balance + delta);
    await HiveService.updatePaymentAccount(updatedAccount);
  }

  Future<void> _syncLinkedIncomeTransaction(Receivable receivable) async {
    final accountId = receivable.accountId?.trim();
    if (accountId == null || accountId.isEmpty) {
      await _deleteLinkedIncomeTransaction(receivable.id);
      return;
    }

    if (receivable.receivedAmount <= 0) {
      await _deleteLinkedIncomeTransaction(receivable.id);
      return;
    }

    final legacyDuplicates = HiveService.getAllExpenses().where((expense) {
      final hasReceivableTag =
          expense.tags.contains('receivable:${receivable.id}');
      final hasLegacyTitle = expense.title.startsWith(
        'Receivable Received - ${receivable.title}',
      );
      return expense.transactionType == 'income' &&
          expense.accountId == accountId &&
          (hasReceivableTag || hasLegacyTitle) &&
          expense.id != '$_receivableIncomePrefix${receivable.id}';
    }).toList();

    for (final duplicate in legacyDuplicates) {
      await HiveService.deleteExpense(duplicate.id);
    }

    final linkedExpense = Expense(
      id: '$_receivableIncomePrefix${receivable.id}',
      title: 'Receivable Received - ${receivable.title}',
      amount: receivable.receivedAmount,
      category: 'Receivables',
      paymentMethod: 'Receivable Credit',
      date: DateTime.now(),
      notes: 'Received receivable: ${receivable.title}',
      tags: ['receivable', 'receivable:${receivable.id}'],
      currency: receivable.currency,
      accountId: accountId,
      transactionType: 'income',
    );

    await HiveService.addExpense(linkedExpense);
  }

  Future<void> _deleteLinkedIncomeTransaction(String receivableId) async {
    await HiveService.deleteExpense('$_receivableIncomePrefix$receivableId');
  }

  List<Receivable> _buildRecurringSeries(Receivable base) {
    final end = base.recurringEndDate;
    if (end == null) {
      return [base];
    }

    final startMonth = DateTime(base.dueDate.year, base.dueDate.month, 1);
    final endMonth = DateTime(end.year, end.month, 1);
    if (startMonth.isAfter(endMonth)) {
      return [base.copyWith(isRecurring: false, recurringEndDate: null)];
    }

    final groupId = base.recurrenceGroupId ?? base.id;
    final series = <Receivable>[];
    var cursor = startMonth;

    while (!cursor.isAfter(endMonth)) {
      final dueDate =
          _safeDayInMonth(cursor.year, cursor.month, base.dueDate.day);
      final generated = base.copyWith(
        id: '${groupId}_${cursor.year}_${cursor.month}',
        dueDate: dueDate,
        isReceived: false,
        receivedDate: null,
        receivedAmount: 0,
        recurrenceGroupId: groupId,
      );
      series.add(generated);
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }

    return series;
  }

  DateTime _safeDayInMonth(int year, int month, int day) {
    final first = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0).day;
    final safeDay = day.clamp(1, lastDay);
    return DateTime(first.year, first.month, safeDay);
  }
}
