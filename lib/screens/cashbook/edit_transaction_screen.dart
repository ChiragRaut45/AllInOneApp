import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';

class EditTransactionScreen extends StatefulWidget {
  final TransactionModel transaction;
  final int index;

  const EditTransactionScreen({
    super.key,
    required this.transaction,
    required this.index,
  });

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  late TextEditingController titleController;
  late TextEditingController amountController;

  bool isIncome = false;

  String category = "Food";

  final categories = ["Food", "Travel", "Bills", "Shopping"];

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.transaction.title);

    amountController = TextEditingController(
      text: widget.transaction.amount.toString(),
    );

    isIncome = widget.transaction.isIncome;

    /// Only assign category if transaction is expense
    if (!isIncome && categories.contains(widget.transaction.category)) {
      category = widget.transaction.category;
    }
  }

  void updateTransaction() {
    final title = titleController.text;
    final amount = double.tryParse(amountController.text);

    if (title.isEmpty || amount == null) return;

    final updated = TransactionModel(
      title: title,
      amount: amount,
      category: isIncome ? "Income" : category,
      isIncome: isIncome,
      date: widget.transaction.date,
    );

    Provider.of<TransactionProvider>(
      context,
      listen: false,
    ).update(widget.index, updated, context);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Transaction")),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TITLE
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),

            const SizedBox(height: 20),

            /// AMOUNT
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Amount"),
            ),

            const SizedBox(height: 20),

            /// TRANSACTION TYPE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Income", style: TextStyle(fontSize: 16)),

                Switch(
                  value: isIncome,
                  onChanged: (value) {
                    setState(() {
                      isIncome = value;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// CATEGORY (ONLY IF EXPENSE)
            if (!isIncome)
              DropdownButtonFormField<String>(
                value: category,

                decoration: const InputDecoration(labelText: "Category"),

                items: categories.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),

                onChanged: (value) {
                  setState(() {
                    category = value!;
                  });
                },
              ),

            const SizedBox(height: 40),

            /// UPDATE BUTTON
            Center(
              child: ElevatedButton(
                onPressed: updateTransaction,
                child: const Text("Update Transaction"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
