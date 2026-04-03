import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/cashbook_model.dart';
import '../models/note_model.dart';
import '../models/todo_model.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'not-authenticated',
        message: 'No authenticated Firebase user.',
      );
    }
    return uid;
  }

  static Future<void> verifyWriteAccess() async {
    final uid = _uid;
    await _db.collection('users').doc(uid).collection('meta').doc('health').set(
      {'lastWriteCheckAt': FieldValue.serverTimestamp(), 'platform': 'flutter'},
      SetOptions(merge: true),
    );
  }

  static Future<void> initializeUserData() async {
    final uid = _uid;

    final cashbooksRef = _db
        .collection('users')
        .doc(uid)
        .collection('cashbooks')
        .doc('data');
    final todosRef = _db
        .collection('users')
        .doc(uid)
        .collection('todos')
        .doc('data');
    final notesRef = _db
        .collection('users')
        .doc(uid)
        .collection('notes')
        .doc('data');
    final budgetRef = _db
        .collection('users')
        .doc(uid)
        .collection('budget')
        .doc('data');

    final cashbooksDoc = await cashbooksRef.get();
    final todosDoc = await todosRef.get();
    final notesDoc = await notesRef.get();
    final budgetDoc = await budgetRef.get();

    final batch = _db.batch();
    bool needsCommit = false;

    if (!cashbooksDoc.exists) {
      batch.set(cashbooksRef, {
        'cashbooks': [
          CashbookModel(name: 'Personal', transactions: []).toJson(),
        ],
        'updatedAt': FieldValue.serverTimestamp(),
      });
      needsCommit = true;
    }

    if (!todosDoc.exists) {
      batch.set(todosRef, {
        'todos': <Map<String, dynamic>>[],
        'updatedAt': FieldValue.serverTimestamp(),
      });
      needsCommit = true;
    }

    if (!notesDoc.exists) {
      batch.set(notesRef, {
        'notes': <Map<String, dynamic>>[],
        'updatedAt': FieldValue.serverTimestamp(),
      });
      needsCommit = true;
    }

    if (!budgetDoc.exists) {
      batch.set(budgetRef, {
        'amount': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      needsCommit = true;
    }

    if (needsCommit) {
      await batch.commit();
    }
  }

  static Future<void> saveCashbooks(List<CashbookModel> cashbooks) async {
    final uid = _uid;
    await _db
        .collection('users')
        .doc(uid)
        .collection('cashbooks')
        .doc('data')
        .set({
          'cashbooks': cashbooks.map((e) => e.toJson()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  static Future<List<CashbookModel>> loadCashbooks() async {
    final uid = _uid;

    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('cashbooks')
          .doc('data')
          .get();

      if (!doc.exists || doc.data() == null) {
        return [CashbookModel(name: 'Personal', transactions: [])];
      }

      final cashbooks =
          (doc.data()!['cashbooks'] as List?)
              ?.map((e) => CashbookModel.fromJson(e))
              .toList() ??
          [];

      return cashbooks.isEmpty
          ? [CashbookModel(name: 'Personal', transactions: [])]
          : cashbooks;
    } catch (_) {
      return [CashbookModel(name: 'Personal', transactions: [])];
    }
  }

  static Future<void> saveTodos(List<TodoModel> todos) async {
    final uid = _uid;
    await _db.collection('users').doc(uid).collection('todos').doc('data').set({
      'todos': todos.map((e) => e.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<List<TodoModel>> loadTodos() async {
    final uid = _uid;

    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('todos')
          .doc('data')
          .get();

      if (!doc.exists || doc.data() == null) {
        return [];
      }

      return (doc.data()!['todos'] as List?)
              ?.map((e) => TodoModel.fromJson(e))
              .toList() ??
          [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveNotes(List<NoteModel> notes) async {
    final uid = _uid;
    await _db.collection('users').doc(uid).collection('notes').doc('data').set({
      'notes': notes.map((e) => e.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<List<NoteModel>> loadNotes() async {
    final uid = _uid;

    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('notes')
          .doc('data')
          .get();

      if (!doc.exists || doc.data() == null) {
        return [];
      }

      return (doc.data()!['notes'] as List?)
              ?.map((e) => NoteModel.fromJson(e))
              .toList() ??
          [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveBudget(double budget) async {
    final uid = _uid;
    await _db.collection('users').doc(uid).collection('budget').doc('data').set(
      {'amount': budget, 'updatedAt': FieldValue.serverTimestamp()},
    );
  }

  static Future<double> loadBudget() async {
    final uid = _uid;

    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('budget')
          .doc('data')
          .get();

      if (!doc.exists || doc.data() == null) {
        return 0;
      }

      return (doc.data()!['amount'] as num?)?.toDouble() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final uid = _uid;
    await _db
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc('data')
        .set({
          'email': data['email'],
          'displayName': data['displayName'],
          'photoURL': data['photoURL'],
          'uid': uid,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  static Future<void> saveSelectedCashbookIndex(int index) async {
    final uid = _uid;
    await _db
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('cashbook')
        .set({
          'selectedIndex': index,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  static Future<int> loadSelectedCashbookIndex() async {
    final uid = _uid;

    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('cashbook')
          .get();

      if (!doc.exists || doc.data() == null) {
        return 0;
      }

      return (doc.data()!['selectedIndex'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
