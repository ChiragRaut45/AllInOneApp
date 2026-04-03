import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/transaction_provider.dart';
import '../../providers/cashbook_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/utils/helpers.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/transaction_tile.dart';
import '../../core/constants/app_colors.dart';
import '../../services/pdf_service.dart';
import 'add_transaction_screen.dart';
import 'transaction_search_screen.dart';
import 'edit_transaction_screen.dart';

class CashbookHomeScreen extends StatelessWidget {
  const CashbookHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cashbookProvider = Provider.of<CashbookProvider>(context);

    // Show loading state while data is being fetched
    if (cashbookProvider.isLoading || cashbookProvider.cashbooks.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Cashbook")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final transactionProvider = Provider.of<TransactionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            /// CASHBOOK SELECTOR
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: cashbookProvider.selectedIndex,
                  dropdownColor: Colors.white,
                  isExpanded: true,
                  items: List.generate(
                    cashbookProvider.cashbooks.length,
                    (index) => DropdownMenuItem(
                      value: index,
                      child: Text(
                        cashbookProvider.cashbooks[index].name,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  onChanged: (i) {
                    cashbookProvider.switchCashbook(i!);
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          /// SEARCH
          IconButton(
            icon: const Icon(Icons.search, size: 28),
            tooltip: 'Search transactions',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TransactionSearchScreen(),
                ),
              );
            },
          ),

          /// PDF EXPORT
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, size: 28),
            tooltip: 'Export to PDF',
            onPressed: () async {
              final cashbook = cashbookProvider.current;
              final path = await PdfService.generateCashbookPdf(cashbook);
              await OpenFilex.open(path);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("PDF saved & opened")),
              );
            },
          ),

          /// ADD CASHBOOK
          IconButton(
            icon: const Icon(Icons.add_box, size: 28),
            tooltip: 'New Cashbook',
            onPressed: () {
              _showAddCashbookDialog(context);
            },
          ),

          /// MENU (RENAME + DELETE)
          PopupMenuButton<String>(
            tooltip: 'More options',
            icon: const Icon(Icons.more_vert, size: 28),
            onSelected: (value) {
              if (value == "rename") {
                _showRenameDialog(context);
              } else if (value == "delete") {
                _showDeleteDialog(context);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: "rename",
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 24),
                    SizedBox(width: 12),
                    Text("Rename Cashbook"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: "delete",
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 24),
                    SizedBox(width: 12),
                    Text(
                      "Delete Cashbook",
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
        },
        child: const Icon(Icons.add, size: 28),
        tooltip: 'Add Transaction',
        elevation: 6,
      ),

      body: Column(
        children: [
          /// BALANCE CARD
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.lightPurple],
              ),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Total Balance",
                  style: TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 8),

                Text(
                  Helpers.formatCurrency(transactionProvider.balance),
                  style: TextStyle(
                    color: transactionProvider.balance >= 0
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),
                Text(
                  transactionProvider.balance >= 0
                      ? 'Good progress!'
                      : 'Need caution',
                  style: TextStyle(
                    color: transactionProvider.balance >= 0
                        ? Colors.green.shade200
                        : Colors.red.shade200,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Income: ${Helpers.formatCurrency(transactionProvider.income)}",
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      "Expense: ${Helpers.formatCurrency(transactionProvider.expense)}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// SUMMARY CARDS - SIMPLE AND CLEAN
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    title: "Income",
                    amount: transactionProvider.income,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryCard(
                    title: "Expense",
                    amount: transactionProvider.expense,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryCard(
                    title: "Balance",
                    amount: transactionProvider.balance,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Recent Transactions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// TRANSACTION LIST
          Expanded(
            child: ListView.builder(
              itemCount: transactionProvider.transactions.length,

              itemBuilder: (context, index) {
                final transaction = transactionProvider.transactions[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditTransactionScreen(
                          transaction: transaction,
                          index: index,
                        ),
                      ),
                    );
                  },

                  onLongPress: () {
                    _showDeleteTransactionDialog(
                      context,
                      index,
                      transactionProvider,
                    );
                  },

                  child: TransactionTile(
                    transaction: transaction,
                    onDelete: () {
                      _showDeleteTransactionDialog(
                        context,
                        index,
                        transactionProvider,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ADD
  void _showAddCashbookDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Cashbook"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final provider = Provider.of<CashbookProvider>(
                context,
                listen: false,
              );
              provider.addCashbook(controller.text, context);
              // Automatically switch to the newly created cashbook
              provider.switchCashbook(provider.cashbooks.length - 1);

              Navigator.pop(context);
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  /// RENAME
  void _showRenameDialog(BuildContext context) {
    final provider = Provider.of<CashbookProvider>(context, listen: false);

    final controller = TextEditingController(text: provider.current.name);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Rename Cashbook"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter new name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              provider.renameCashbook(
                provider.selectedIndex,
                controller.text,
                context,
              );
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showDeleteTransactionDialog(
    BuildContext context,
    int index,
    TransactionProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Do you really want to remove this transaction? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.delete(index, context);
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transaction deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// DELETE
  void _showDeleteDialog(BuildContext context) {
    final provider = Provider.of<CashbookProvider>(context, listen: false);

    if (provider.cashbooks.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete the last remaining cashbook.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final confirmationController = TextEditingController();
    bool canDelete = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text("Delete Cashbook"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Type DELETE in the field below to confirm deleting this cashbook.",
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmationController,
                decoration: const InputDecoration(
                  labelText: 'Confirmation code',
                  hintText: 'Enter DELETE',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    canDelete = value.trim().toUpperCase() == 'DELETE';
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canDelete ? Colors.red : Colors.grey,
              ),
              onPressed: canDelete
                  ? () {
                      provider.deleteCashbook(provider.selectedIndex, context);
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cashbook deleted')),
                      );
                    }
                  : null,
              child: const Text("Delete"),
            ),
          ],
        ),
      ),
    );
  }
}
