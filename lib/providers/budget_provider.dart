import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class BudgetProvider extends ChangeNotifier {
  double budget = 0;
  bool isLoading = false;
  bool _isClearingData = false; // Flag to prevent auto-save during logout

  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    try {
      budget = await FirestoreService.loadBudget();
    } catch (e) {
      print('Error loading budget: $e');
      budget = 0;
    }

    isLoading = false;
    notifyListeners();
  }

  void setBudget(double value) {
    budget = value;
    // Don't save to Firestore if we're clearing data on logout
    if (!_isClearingData) {
      FirestoreService.saveBudget(value).catchError((e) {
        debugPrint('Error saving budget: $e');
      });
    }
    notifyListeners();
  }

  void reset() {
    _isClearingData = true; // Prevent auto-save
    budget = 0;
    isLoading = false;
    notifyListeners();
    _isClearingData = false; // Re-enable auto-save
  }
}
