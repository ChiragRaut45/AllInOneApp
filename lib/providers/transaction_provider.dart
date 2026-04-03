import 'package:flutter/material.dart';

import '../models/transaction_model.dart';

import 'cashbook_provider.dart';

class TransactionProvider extends ChangeNotifier {
  final CashbookProvider cashbookProvider;

  TransactionProvider(this.cashbookProvider);

  List<TransactionModel> get transactions =>
      cashbookProvider.current.transactions;

  void add(TransactionModel t, BuildContext context) {
    transactions.add(t);
    cashbookProvider.save();

    notifyListeners();
  }

  void delete(int index, BuildContext context) {
    transactions.removeAt(index);
    cashbookProvider.save();

    notifyListeners();
  }

  void update(
    int index,
    TransactionModel updatedTransaction,
    BuildContext context,
  ) {
    transactions[index] = updatedTransaction;
    cashbookProvider.save();

    notifyListeners();
  }

  double get income =>
      transactions.where((e) => e.isIncome).fold(0, (a, b) => a + b.amount);

  double get expense =>
      transactions.where((e) => !e.isIncome).fold(0, (a, b) => a + b.amount);

  double get balance => income - expense;
}
