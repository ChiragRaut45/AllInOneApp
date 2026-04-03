import 'transaction_model.dart';

class CashbookModel {
  String name;
  List<TransactionModel> transactions;

  CashbookModel({required this.name, required this.transactions});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'transactions': transactions.map((e) => e.toJson()).toList(),
    };
  }

  factory CashbookModel.fromJson(Map<String, dynamic> json) {
    return CashbookModel(
      name: json['name'],
      transactions: (json['transactions'] as List)
          .map((e) => TransactionModel.fromJson(e))
          .toList(),
    );
  }
}
