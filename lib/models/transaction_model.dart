class TransactionModel {
  String title;
  double amount;
  String category;
  bool isIncome;
  DateTime date;

  TransactionModel({
    required this.title,
    required this.amount,
    required this.category,
    required this.isIncome,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
      'isIncome': isIncome,
      'date': date.toIso8601String(),
    };
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      title: json['title'],
      amount: json['amount'],
      category: json['category'],
      isIncome: json['isIncome'],
      date: DateTime.parse(json['date']),
    );
  }
}
