import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/transaction_provider.dart';
import '../../widgets/transaction_tile.dart';

class TransactionSearchScreen extends StatefulWidget {
  const TransactionSearchScreen({super.key});

  @override
  State<TransactionSearchScreen> createState() =>
      _TransactionSearchScreenState();
}

class _TransactionSearchScreenState extends State<TransactionSearchScreen> {
  String query = "";
  String selectedCategory = "All";
  String typeFilter = "All";

  DateTime? startDate;
  DateTime? endDate;

  final categories = ["All", "Food", "Travel", "Bills", "Shopping"];

  Future<void> pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (range != null) {
      setState(() {
        startDate = range.start;
        endDate = range.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);

    final filtered = provider.transactions.where((t) {
      final search = query.toLowerCase();

      final matchesText =
          t.title.toLowerCase().contains(search) ||
          t.category.toLowerCase().contains(search);

      final matchesCategory =
          selectedCategory == "All" || t.category == selectedCategory;

      final matchesType =
          typeFilter == "All" ||
          (typeFilter == "Income" && t.isIncome) ||
          (typeFilter == "Expense" && !t.isIncome);

      final matchesDate =
          startDate == null ||
          (t.date.isAfter(startDate!) &&
              t.date.isBefore(endDate!.add(const Duration(days: 1))));

      return matchesText && matchesCategory && matchesType && matchesDate;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Search Transactions")),

      body: Column(
        children: [
          /// SEARCH FIELD
          Padding(
            padding: const EdgeInsets.all(12),

            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search title or category",
                prefixIcon: Icon(Icons.search),
              ),

              onChanged: (value) {
                setState(() {
                  query = value;
                });
              },
            ),
          ),

          /// CATEGORY FILTER
          SizedBox(
            height: 50,

            child: ListView.builder(
              scrollDirection: Axis.horizontal,

              itemCount: categories.length,

              itemBuilder: (context, index) {
                final category = categories[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),

                  child: ChoiceChip(
                    label: Text(category),

                    selected: selectedCategory == category,

                    onSelected: (_) {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          /// INCOME / EXPENSE FILTER
          SizedBox(
            height: 50,

            child: ListView(
              scrollDirection: Axis.horizontal,

              children: [
                const SizedBox(width: 8),

                ChoiceChip(
                  label: const Text("All"),
                  selected: typeFilter == "All",
                  onSelected: (_) {
                    setState(() {
                      typeFilter = "All";
                    });
                  },
                ),

                const SizedBox(width: 10),

                ChoiceChip(
                  label: const Text("Income"),
                  selected: typeFilter == "Income",
                  onSelected: (_) {
                    setState(() {
                      typeFilter = "Income";
                    });
                  },
                ),

                const SizedBox(width: 10),

                ChoiceChip(
                  label: const Text("Expense"),
                  selected: typeFilter == "Expense",
                  onSelected: (_) {
                    setState(() {
                      typeFilter = "Expense";
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// DATE FILTER
          ElevatedButton.icon(
            icon: const Icon(Icons.date_range),

            label: Text(
              startDate == null
                  ? "Select Date Range"
                  : "${startDate!.day}/${startDate!.month} - ${endDate!.day}/${endDate!.month}",
            ),

            onPressed: pickDateRange,
          ),

          const SizedBox(height: 10),

          /// RESULTS
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text("No transactions found"))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final tx = filtered[index];

                      return TransactionTile(
                        transaction: tx,
                        onDelete: () async {
                          final shouldDelete = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Delete Transaction'),
                              content: const Text(
                                'Delete this transaction from cashbook?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (shouldDelete == true) {
                            final globalIndex = provider.transactions.indexOf(
                              tx,
                            );
                            if (globalIndex != -1) {
                              provider.delete(globalIndex, context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Transaction deleted'),
                                ),
                              );
                              setState(() {});
                            }
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
