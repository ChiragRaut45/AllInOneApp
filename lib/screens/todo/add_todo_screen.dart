import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/todo_model.dart';
import '../../providers/todo_provider.dart';
import '../../services/notification_service.dart';

class AddTodoScreen extends StatefulWidget {
  const AddTodoScreen({super.key});

  @override
  State<AddTodoScreen> createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends State<AddTodoScreen> {
  final titleController = TextEditingController();
  final descController = TextEditingController();

  String priority = "Medium";

  DateTime? dueDate;
  TimeOfDay? dueTime;

  /// DATE PICKER
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

  /// TIME PICKER
  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        dueTime = picked;
      });
    }
  }

  /// SAVE TODO
  Future<void> saveTodo() async {
    if (titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a task title')),
      );
      return;
    }

    DateTime? finalDateTime;

    if (dueDate != null) {
      finalDateTime = DateTime(
        dueDate!.year,
        dueDate!.month,
        dueDate!.day,
        dueTime?.hour ?? 9,
        dueTime?.minute ?? 0,
      );
    }

    final todo = TodoModel(
      title: titleController.text,
      description: descController.text,
      priority: priority,
      dueDate: finalDateTime,
    );

    Provider.of<TodoProvider>(context, listen: false).add(todo, context);

    // Close quickly so user sees the updated todo list immediately.
    if (mounted) Navigator.pop(context);

    // Schedule notification in background so UX is non-blocking.
    if (finalDateTime != null) {
      final scheduled = finalDateTime.isBefore(DateTime.now())
          ? DateTime.now().add(const Duration(seconds: 20))
          : finalDateTime;

      Future<void>(() async {
        final success = await NotificationService.scheduleNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: 'Task Reminder',
          body: titleController.text,
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
      backgroundColor: const Color(0xFFF4F5F7),

      appBar: AppBar(title: const Text("Add Task"), elevation: 0),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            /// MAIN CARD
            Container(
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),

              child: Column(
                children: [
                  /// TITLE
                  _inputField(
                    controller: titleController,
                    hint: "Title",
                    icon: Icons.title,
                  ),

                  const SizedBox(height: 12),

                  /// DESCRIPTION
                  _inputField(
                    controller: descController,
                    hint: "Description",
                    icon: Icons.notes,
                    maxLines: 2,
                  ),

                  const SizedBox(height: 16),

                  /// PRIORITY CHIPS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ["High", "Medium", "Low"].map((p) {
                      final selected = priority == p;

                      return ChoiceChip(
                        label: Text(p),

                        selected: selected,

                        selectedColor: const Color(0xFF5A4FD1),

                        labelStyle: TextStyle(
                          color: selected ? Colors.white : Colors.black,
                        ),

                        onSelected: (_) {
                          setState(() {
                            priority = p;
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  /// DATE + TIME
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: pickDate,
                          icon: const Icon(Icons.calendar_today),

                          label: Text(
                            dueDate == null
                                ? "Date"
                                : "${dueDate!.day}/${dueDate!.month}",
                          ),

                          style: _smallButton(),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: pickTime,
                          icon: const Icon(Icons.access_time),

                          label: Text(
                            dueTime == null ? "Time" : dueTime!.format(context),
                          ),

                          style: _smallButton(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// SAVE BUTTON
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF5A4FD1), const Color(0xFF6B5CE6)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5A4FD1).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: saveTodo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_task, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text(
                      "Add Task",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// INPUT FIELD
  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,

      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),

        filled: true,
        fillColor: const Color(0xFFF4F5F7),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  /// SMALL BUTTON
  ButtonStyle _smallButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFF4F5F7),
      foregroundColor: Colors.black,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
