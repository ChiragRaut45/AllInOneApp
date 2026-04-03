import 'package:flutter/material.dart';
import '../models/todo_model.dart';

class TodoTile extends StatelessWidget {
  final TodoModel todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TodoTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
  });

  Color getPriorityColor() {
    switch (todo.priority) {
      case "High":
        return Colors.red;
      case "Medium":
        return Colors.orange;
      case "Low":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color getDateColor() {
    if (todo.dueDate == null) return Colors.grey;

    final today = DateTime.now();

    if (todo.dueDate!.isBefore(today)) {
      return Colors.red;
    } else if (todo.dueDate!.day == today.day) {
      return Colors.orange;
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(todo.title + todo.hashCode.toString()),

      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.check, color: Colors.white),
      ),

      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),

      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          onToggle();
        } else {
          onDelete();
        }
      },

      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),

        child: ListTile(
          leading: Checkbox(
            value: todo.isCompleted,
            onChanged: (_) => onToggle(),
          ),

          title: Text(
            todo.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),

          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (todo.description.isNotEmpty) Text(todo.description),

              const SizedBox(height: 5),

              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: getPriorityColor(),
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(width: 6),

                  Text(todo.priority),

                  const SizedBox(width: 10),

                  if (todo.dueDate != null)
                    Text(
                      todo.dueDate.toString().split(' ')[0],
                      style: TextStyle(color: getDateColor()),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
