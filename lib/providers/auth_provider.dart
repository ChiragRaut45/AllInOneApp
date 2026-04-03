import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initializeUser();
    _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _initializeUser() {
    _user = _firebaseAuth.currentUser;
  }

  void _onAuthStateChanged(User? user) {
    _user = user;
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _isLoading = false;
        _errorMessage = 'Google sign-in cancelled';
        notifyListeners();
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);

      _user = userCredential.user;

      if (_user != null) {
        await FirestoreService.verifyWriteAccess();
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          await FirestoreService.initializeUserData();
        }

        await FirestoreService.updateUserProfile({
          'email': _user!.email,
          'displayName': _user!.displayName,
          'photoURL': _user!.photoURL,
        });
      }

      _isLoading = false;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = e.message ?? 'Authentication failed';
      notifyListeners();
    } on FirebaseException catch (e) {
      _isLoading = false;
      _errorMessage =
          'Firestore write failed (${e.code}). Check Firestore Rules for authenticated users.';
      notifyListeners();
    } catch (_) {
      _isLoading = false;
      _errorMessage = 'Unexpected sign-in error';
      notifyListeners();
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      _user = userCredential.user;

      if (_user != null) {
        await FirestoreService.verifyWriteAccess();
        // No need to initialize for existing users

        await FirestoreService.updateUserProfile({
          'email': _user!.email,
          'displayName': _user!.displayName ?? _user!.email?.split('@')[0],
          'photoURL': _user!.photoURL,
        });
      }

      _isLoading = false;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      switch (e.code) {
        case 'user-not-found':
          _errorMessage = 'No user found with this email address.';
          break;
        case 'wrong-password':
          _errorMessage = 'Incorrect password.';
          break;
        case 'invalid-email':
          _errorMessage = 'Invalid email address.';
          break;
        case 'user-disabled':
          _errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          _errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        default:
          _errorMessage = e.message ?? 'Email sign-in failed';
      }
      notifyListeners();
    } on FirebaseException catch (e) {
      _isLoading = false;
      _errorMessage =
          'Firestore write failed (${e.code}). Check Firestore Rules for authenticated users.';
      notifyListeners();
    } catch (_) {
      _isLoading = false;
      _errorMessage = 'Unexpected sign-in error';
      notifyListeners();
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      _user = userCredential.user;

      if (_user != null) {
        await FirestoreService.verifyWriteAccess();
        await FirestoreService.initializeUserData();

        await FirestoreService.updateUserProfile({
          'email': _user!.email,
          'displayName': _user!.displayName ?? _user!.email?.split('@')[0],
          'photoURL': _user!.photoURL,
        });
      }

      _isLoading = false;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      switch (e.code) {
        case 'weak-password':
          _errorMessage =
              'Password is too weak. Please choose a stronger password.';
          break;
        case 'email-already-in-use':
          _errorMessage = 'An account already exists with this email address.';
          break;
        case 'invalid-email':
          _errorMessage = 'Invalid email address.';
          break;
        case 'operation-not-allowed':
          _errorMessage = 'Email/password accounts are not enabled.';
          break;
        default:
          _errorMessage = e.message ?? 'Account creation failed';
      }
      notifyListeners();
    } on FirebaseException catch (e) {
      _isLoading = false;
      _errorMessage =
          'Firestore write failed (${e.code}). Check Firestore Rules for authenticated users.';
      notifyListeners();
    } catch (_) {
      _isLoading = false;
      _errorMessage = 'Unexpected sign-up error';
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firebaseAuth.sendPasswordResetEmail(email: email);

      _isLoading = false;
      _errorMessage = 'Password reset email sent. Check your inbox.';
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      switch (e.code) {
        case 'user-not-found':
          _errorMessage = 'No user found with this email address.';
          break;
        case 'invalid-email':
          _errorMessage = 'Invalid email address.';
          break;
        case 'too-many-requests':
          _errorMessage = 'Too many requests. Please try again later.';
          break;
        default:
          _errorMessage = e.message ?? 'Password reset failed';
      }
      notifyListeners();
    } catch (_) {
      _isLoading = false;
      _errorMessage = 'Unexpected error occurred';
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();

      _user = null;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _isLoading = false;
      _errorMessage = 'Error signing out';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
