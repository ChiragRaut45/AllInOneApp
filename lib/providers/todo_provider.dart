import 'package:flutter/material.dart';

import '../models/todo_model.dart';
import '../services/firestore_service.dart';

class TodoProvider extends ChangeNotifier {
  List<TodoModel> todos = [];
  bool isLoading = false;
  String filter = "All";
  String searchQuery = "";
  String sortBy = "Date";
  bool _isClearingData = false; // Flag to prevent auto-save during logout

  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    try {
      todos = await FirestoreService.loadTodos();
    } catch (e) {
      print('Error loading todos: $e');
      todos = [];
    }

    isLoading = false;
    notifyListeners();
  }

  void add(TodoModel todo, BuildContext context) {
    todos.add(todo);
    save(context);
  }

  void delete(int index, BuildContext context) {
    todos.removeAt(index);
    save(context);
  }

  void toggle(int index, BuildContext context) {
    todos[index].isCompleted = !todos[index].isCompleted;
    save(context);
  }

  void update(int index, TodoModel updated, BuildContext context) {
    todos[index] = updated;
    save(context);
  }

  void setFilter(String value) {
    filter = value;
    notifyListeners();
  }

  void setSearch(String value) {
    searchQuery = value;
    notifyListeners();
  }

  void setSort(String value) {
    sortBy = value;
    notifyListeners();
  }

  void save(BuildContext context) {
    // Don't save to Firestore if we're clearing data on logout
    if (_isClearingData) return;

    // Save ONLY to Firestore
    FirestoreService.saveTodos(todos).catchError((e) {
      debugPrint('Error saving todos: $e');
    });

    notifyListeners();
  }

  void reset() {
    _isClearingData = true; // Prevent auto-save
    todos = [];
    isLoading = false;
    filter = "All";
    searchQuery = "";
    sortBy = "Date";
    notifyListeners();
    _isClearingData = false; // Re-enable auto-save
  }

  List<TodoModel> get filteredTodos {
    List<TodoModel> list = todos;

    if (searchQuery.isNotEmpty) {
      list = list
          .where(
            (t) => t.title.toLowerCase().contains(searchQuery.toLowerCase()),
          )
          .toList();
    }

    if (filter == "Completed") {
      list = list.where((t) => t.isCompleted).toList();
    } else if (filter == "Pending") {
      list = list.where((t) => !t.isCompleted).toList();
    }

    if (sortBy == "Priority") {
      list.sort((a, b) => a.priority.compareTo(b.priority));
    } else {
      list.sort(
        (a, b) => (a.dueDate ?? DateTime.now()).compareTo(
          b.dueDate ?? DateTime.now(),
        ),
      );
    }

    return list;
  }
}
