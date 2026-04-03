import 'package:flutter/material.dart';

import '../models/note_model.dart';
import '../services/firestore_service.dart';

class NoteProvider extends ChangeNotifier {
  List<NoteModel> notes = [];
  bool isLoading = false;
  bool _isClearingData = false; // Flag to prevent auto-save during logout

  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    try {
      notes = await FirestoreService.loadNotes();
    } catch (e) {
      print('Error loading notes: $e');
      notes = [];
    }

    isLoading = false;
    notifyListeners();
  }

  void addOrUpdate(String date, String text, BuildContext context) {
    final index = notes.indexWhere((n) => n.date == date);

    if (index != -1) {
      notes[index].text = text;
    } else {
      notes.add(NoteModel(date: date, text: text));
    }

    // Don't save to Firestore if we're clearing data on logout
    if (!_isClearingData) {
      // Save ONLY to Firestore
      FirestoreService.saveNotes(notes).catchError((e) {
        debugPrint('Error saving notes: $e');
      });
    }

    notifyListeners();
  }

  String getNote(String date) {
    final note = notes.firstWhere(
      (n) => n.date == date,
      orElse: () => NoteModel(date: date, text: ""),
    );

    return note.text;
  }

  void reset() {
    _isClearingData = true; // Prevent auto-save
    notes = [];
    isLoading = false;
    notifyListeners();
    _isClearingData = false; // Re-enable auto-save
  }
}
