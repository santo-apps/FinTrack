import 'package:fintrack/features/accounts/presentation/pages/account_transaction_screen.dart';
import 'package:fintrack/features/expense/data/models/expense_model.dart';
import 'package:flutter_test/flutter_test.dart';

Expense _expense({
  required String id,
  required String transactionType,
  String? accountId,
  String? destinationAccountId,
}) {
  return Expense(
    id: id,
    title: 'Txn $id',
    amount: 100,
    category: 'Test',
    paymentMethod: 'Account',
    date: DateTime(2026, 1, 1),
    accountId: accountId,
    transactionType: transactionType,
    destinationAccountId: destinationAccountId,
  );
}

void main() {
  group('Account transaction visibility', () {
    test('shows transaction for source account', () {
      final expense = _expense(
        id: 'e1',
        transactionType: 'expense',
        accountId: 'bank-1',
      );

      expect(shouldShowTransactionForAccount(expense, 'bank-1'), isTrue);
    });

    test('shows transfer for destination account', () {
      final transfer = _expense(
        id: 't1',
        transactionType: 'transfer',
        accountId: 'bank-1',
        destinationAccountId: 'bank-2',
      );

      expect(shouldShowTransactionForAccount(transfer, 'bank-2'), isTrue);
    });

    test('shows payment for destination account', () {
      final payment = _expense(
        id: 'p1',
        transactionType: 'payment',
        accountId: 'bank-1',
        destinationAccountId: 'card-1',
      );

      expect(shouldShowTransactionForAccount(payment, 'card-1'), isTrue);
    });

    test('does not show plain expense for unrelated destination account', () {
      final expense = _expense(
        id: 'e2',
        transactionType: 'expense',
        accountId: 'bank-1',
        destinationAccountId: 'bank-2',
      );

      expect(shouldShowTransactionForAccount(expense, 'bank-2'), isFalse);
    });
  });

  group('Account-side debit direction', () {
    test('transfer is debit for source account', () {
      final transfer = _expense(
        id: 't2',
        transactionType: 'transfer',
        accountId: 'bank-1',
        destinationAccountId: 'bank-2',
      );

      expect(isDebitTransactionForAccount(transfer, 'bank-1'), isTrue);
    });

    test('transfer is credit for destination account', () {
      final transfer = _expense(
        id: 't3',
        transactionType: 'transfer',
        accountId: 'bank-1',
        destinationAccountId: 'bank-2',
      );

      expect(isDebitTransactionForAccount(transfer, 'bank-2'), isFalse);
    });

    test('payment remains debit for source and destination accounts', () {
      final payment = _expense(
        id: 'p2',
        transactionType: 'payment',
        accountId: 'bank-1',
        destinationAccountId: 'card-1',
      );

      expect(isDebitTransactionForAccount(payment, 'bank-1'), isTrue);
      expect(isDebitTransactionForAccount(payment, 'card-1'), isTrue);
    });
  });
}
