import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/todo_provider.dart';
import '../../widgets/todo_tile.dart';
import 'add_todo_screen.dart';
import 'edit_todo_screen.dart';

class TodoHomeScreen extends StatelessWidget {
  const TodoHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TodoProvider>(context);

    final todos = provider.filteredTodos;

    final pending = todos.where((t) => !t.isCompleted).toList();
    final completed = todos.where((t) => t.isCompleted).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),

      appBar: AppBar(title: const Text("Todo List"), elevation: 0),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF5A4FD1),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTodoScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Manage your tasks efficiently",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),

          /// SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),

            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),

              child: TextField(
                decoration: const InputDecoration(
                  hintText: "Search tasks...",
                  border: InputBorder.none,
                  icon: Icon(Icons.search),
                ),
                onChanged: provider.setSearch,
              ),
            ),
          ),

          const SizedBox(height: 12),

          /// FILTER CHIPS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),

            child: Row(
              children: ["All", "Pending", "Completed"].map((f) {
                final selected = provider.filter == f;

                return Padding(
                  padding: const EdgeInsets.only(right: 10),

                  child: ChoiceChip(
                    label: Text(f),

                    selected: selected,

                    selectedColor: const Color(0xFF5A4FD1),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black,
                    ),

                    onSelected: (_) => provider.setFilter(f),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          /// SUMMARY CARDS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),

            child: Row(
              children: [
                _summaryCard("Pending", pending.length, Colors.orange),

                const SizedBox(width: 10),

                _summaryCard("Completed", completed.length, Colors.green),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// SORT
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),

            child: DropdownButtonFormField(
              value: provider.sortBy,

              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),

              items: const [
                DropdownMenuItem(value: "Date", child: Text("Sort by Date")),
                DropdownMenuItem(
                  value: "Priority",
                  child: Text("Sort by Priority"),
                ),
              ],

              onChanged: (value) => provider.setSort(value!),
            ),
          ),

          const SizedBox(height: 10),

          /// TASK LIST
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),

              children: [
                if (pending.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "Pending Tasks",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                ...pending.map((todo) {
                  final index = provider.todos.indexOf(todo);

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditTodoScreen(todo: todo, index: index),
                        ),
                      );
                    },
                    child: TodoTile(
                      todo: todo,
                      onToggle: () => provider.toggle(index, context),
                      onDelete: () => provider.delete(index, context),
                    ),
                  );
                }),

                if (completed.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "Completed Tasks",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                ...completed.map((todo) {
                  final index = provider.todos.indexOf(todo);

                  return TodoTile(
                    todo: todo,
                    onToggle: () => provider.toggle(index, context),
                    onDelete: () => provider.delete(index, context),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey)),

            const SizedBox(height: 6),

            Text(
              "$count",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
