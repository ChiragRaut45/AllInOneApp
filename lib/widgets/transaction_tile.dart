import 'package:flutter/material.dart';
import '../core/utils/helpers.dart';
import '../models/transaction_model.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(transaction.title),

        subtitle: Text(transaction.category),

        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              Helpers.formatCurrency(transaction.amount),
              style: TextStyle(
                color: transaction.isIncome ? Colors.green : Colors.red,
              ),
            ),

            IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
