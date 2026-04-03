import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/todo_model.dart';
import '../../providers/todo_provider.dart';
import '../../services/notification_service.dart';

class EditTodoScreen extends StatefulWidget {
  final TodoModel todo;
  final int index;

  const EditTodoScreen({super.key, required this.todo, required this.index});

  @override
  State<EditTodoScreen> createState() => _EditTodoScreenState();
}

class _EditTodoScreenState extends State<EditTodoScreen> {
  late TextEditingController titleController;
  late TextEditingController descController;

  late String priority;
  DateTime? dueDate;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.todo.title);

    descController = TextEditingController(text: widget.todo.description);

    priority = widget.todo.priority;
    dueDate = widget.todo.dueDate;
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        dueDate = picked;
      });
    }
  }

  Future<void> updateTodo() async {
    final updated = TodoModel(
      title: titleController.text,
      description: descController.text,
      priority: priority,
      dueDate: dueDate,
      isCompleted: widget.todo.isCompleted,
    );

    Provider.of<TodoProvider>(
      context,
      listen: false,
    ).update(widget.index, updated, context);

    if (mounted) Navigator.pop(context);

    if (dueDate != null) {
      var scheduled = dueDate!;
      if (scheduled.isBefore(DateTime.now())) {
        scheduled = DateTime.now().add(const Duration(seconds: 20));
      }

      Future<void>(() async {
        final success = await NotificationService.scheduleNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: 'Task Reminder',
          body: updated.title,
          scheduledDate: scheduled,
        );

        if (!success) {
          print('Reminder fallback used or failed to schedule.');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Task")),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Description"),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField(
              value: priority,
              items: const [
                DropdownMenuItem(value: "High", child: Text("High")),
                DropdownMenuItem(value: "Medium", child: Text("Medium")),
                DropdownMenuItem(value: "Low", child: Text("Low")),
              ],
              onChanged: (value) {
                setState(() {
                  priority = value!;
                });
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: pickDate,
              child: Text(
                dueDate == null
                    ? "Select Due Date"
                    : dueDate.toString().split(' ')[0],
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: updateTodo,
              child: const Text("Update Task"),
            ),
          ],
        ),
      ),
    );
  }
}
