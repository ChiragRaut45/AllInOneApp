import 'package:flutter/material.dart';

import '../models/cashbook_model.dart';
import '../services/firestore_service.dart';

class CashbookProvider extends ChangeNotifier {
  List<CashbookModel> cashbooks = [
    CashbookModel(name: "Personal", transactions: []),
  ];

  int selectedIndex = 0;
  bool isLoading = false;
  bool _isClearingData = false; // Flag to prevent auto-save during logout

  CashbookModel get current => cashbooks.isNotEmpty
      ? cashbooks[selectedIndex]
      : CashbookModel(name: "Personal", transactions: []);

  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    try {
      // Load from Firestore (user must be authenticated)
      final data = await FirestoreService.loadCashbooks();

      if (data.isEmpty) {
        cashbooks = [CashbookModel(name: "Personal", transactions: [])];
        selectedIndex = 0;
      } else {
        cashbooks = data;
        // Load the last selected index, default to 0 if not found
        selectedIndex = await _loadSelectedIndex();
        // Ensure selectedIndex is valid
        if (selectedIndex >= cashbooks.length) {
          selectedIndex = 0;
        }
      }
    } catch (e) {
      print('Error loading cashbooks: $e');
      cashbooks = [CashbookModel(name: "Personal", transactions: [])];
      selectedIndex = 0;
    }

    isLoading = false;
    notifyListeners();
  }

  Future<int> _loadSelectedIndex() async {
    try {
      return await FirestoreService.loadSelectedCashbookIndex();
    } catch (e) {
      debugPrint('Error loading selected index: $e');
      return 0;
    }
  }

  Future<void> _saveSelectedIndex() async {
    if (_isClearingData) return;

    try {
      await FirestoreService.saveSelectedCashbookIndex(selectedIndex);
    } catch (e) {
      debugPrint('Error saving selected index: $e');
    }
  }

  void save() {
    // Don't save to Firestore if we're clearing data on logout
    if (_isClearingData) return;

    // Save ONLY to Firestore (no local storage)
    FirestoreService.saveCashbooks(cashbooks).catchError((e) {
      debugPrint('Error saving cashbooks: $e');
    });
  }

  void addCashbook(String name, BuildContext context) {
    cashbooks.add(CashbookModel(name: name, transactions: []));

    save();

    notifyListeners();
  }

  void switchCashbook(int index) {
    selectedIndex = index;
    _saveSelectedIndex(); // Save the selected index to Firestore
    notifyListeners();
  }

  void renameCashbook(int index, String newName, BuildContext context) {
    cashbooks[index].name = newName;

    save();

    notifyListeners();
  }

  void deleteCashbook(int index, BuildContext context) {
    if (cashbooks.length == 1) return;

    cashbooks.removeAt(index);

    if (selectedIndex >= cashbooks.length) {
      selectedIndex = cashbooks.length - 1;
    }

    save();

    notifyListeners();
  }

  void reset() {
    _isClearingData = true; // Prevent auto-save
    cashbooks = [CashbookModel(name: "Personal", transactions: [])];
    selectedIndex = 0;
    isLoading = false;
    notifyListeners();
    _isClearingData = false; // Re-enable auto-save
  }
}
