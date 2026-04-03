import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../providers/transaction_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);

    final income = provider.income;
    final expense = provider.expense;

    final savingsRate = income == 0 ? 0 : ((income - expense) / income) * 100;

    final topCategory = _getTopCategory(provider);

    return Scaffold(
      appBar: AppBar(title: const Text("Analytics")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// DASHBOARD CARDS
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 680;
                final cardWidth = isWide
                    ? (constraints.maxWidth - 16) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _dashboardCard(
                        "Savings Rate",
                        "${savingsRate.toStringAsFixed(1)}%",
                        Icons.savings,
                        Colors.green,
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _dashboardCard(
                        "Top Category",
                        topCategory,
                        Icons.category,
                        const Color(0xFF5A4FD1),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // Quick analytics summary
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _tinyStat(
                    context,
                    'Transactions',
                    provider.transactions.length.toString(),
                  ),
                  _tinyStat(context, 'Income', '₹${income.toStringAsFixed(2)}'),
                  _tinyStat(
                    context,
                    'Expense',
                    '₹${expense.toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// INCOME VS EXPENSE DONUT
            const Text(
              "Income vs Expense",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 250,

              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 70,

                  sections: [
                    PieChartSectionData(
                      color: Colors.green,
                      value: income,
                      title: "Income",
                      radius: 60,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    PieChartSectionData(
                      color: Colors.red,
                      value: expense,
                      title: "Expense",
                      radius: 60,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                swapAnimationDuration: const Duration(milliseconds: 800),
              ),
            ),

            const SizedBox(height: 40),

            /// CATEGORY DONUT CHART
            const Text(
              "Category Spending",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 260,

              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 70,

                  sections: _buildCategoryDonut(provider),
                ),

                swapAnimationDuration: const Duration(milliseconds: 800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// DASHBOARD CARD
  Widget _dashboardCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),

          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),

            const SizedBox(height: 8),

            Text(title, style: const TextStyle(color: Colors.grey)),

            const SizedBox(height: 6),

            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tinyStat(BuildContext context, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// CATEGORY DONUT
  List<PieChartSectionData> _buildCategoryDonut(provider) {
    final Map<String, double> categoryTotals = {};

    for (var t in provider.transactions) {
      if (!t.isIncome) {
        categoryTotals[t.category] =
            (categoryTotals[t.category] ?? 0) + t.amount;
      }
    }

    final colors = [
      const Color(0xFF5A4FD1),
      Colors.orange,
      Colors.red,
      Colors.green,
      Colors.blue,
    ];

    int i = 0;

    return categoryTotals.entries.map((entry) {
      final color = colors[i % colors.length];
      i++;

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: entry.key,
        radius: 60,

        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    }).toList();
  }

  /// TOP CATEGORY
  String _getTopCategory(provider) {
    final Map<String, double> categoryTotals = {};

    for (var t in provider.transactions) {
      if (!t.isIncome) {
        categoryTotals[t.category] =
            (categoryTotals[t.category] ?? 0) + t.amount;
      }
    }

    if (categoryTotals.isEmpty) return "None";

    final top = categoryTotals.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    return top.key;
  }
}
