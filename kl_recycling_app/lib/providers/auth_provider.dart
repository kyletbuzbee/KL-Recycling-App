import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user.dart' as app_user;

enum AuthState {
  uninitialized,
  authenticated,
  unauthenticated,
  loading,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthState _authState = AuthState.uninitialized;
  app_user.User? _currentUser;
  String? _errorMessage;

  // Getters
  AuthState get authState => _authState;
  app_user.User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _authState == AuthState.loading;
  bool get isAuthenticated => _authState == AuthState.authenticated;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  // Constructor
  AuthProvider(this._authService) {
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    _authState = AuthState.loading;
    notifyListeners();

    // Listen to Firebase auth state changes
    _authService.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser == null) {
        _authState = AuthState.unauthenticated;
        _currentUser = null;
        _errorMessage = null;
      } else {
        try {
          _authState = AuthState.loading;
          notifyListeners();

          // Get user profile from Firestore
          final user = await _authService.signInWithEmail(
            email: firebaseUser.email!,
            password: '', // We'll handle this differently
          );

          _currentUser = user;
          _authState = AuthState.authenticated;
          _errorMessage = null;
        } catch (e) {
          debugPrint('Error fetching user profile: $e');
          // If we can't get the user profile, but Firebase auth says authenticated,
          // show authenticated state without profile
          _currentUser = null;
          _authState = AuthState.authenticated;
        }
      }
      notifyListeners();
    });
  }

  // Sign In Methods
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _authState = AuthState.loading;
      _errorMessage = null;
      notifyListeners();

      final user = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      _currentUser = user;
      _authState = AuthState.authenticated;
      notifyListeners();
      return true;

    } on FirebaseAuthException catch (e) {
      _authState = AuthState.unauthenticated;
      switch (e.code) {
        case 'user-not-found':
          _errorMessage = 'No user found with this email address.';
          break;
        case 'wrong-password':
          _errorMessage = ' Incorrect password provided.';
          break;
        case 'invalid-email':
          _errorMessage = 'Invalid email address.';
          break;
        case 'user-disabled':
          _errorMessage = 'This user account has been disabled.';
          break;
        case 'too-many-requests':
          _errorMessage = 'Too many failed attempts. Try again later.';
          break;
        default:
          _errorMessage = 'Sign in failed: ${e.message}';
      }
      notifyListeners();
      return false;

    } catch (e) {
      _authState = AuthState.unauthenticated;
      _errorMessage = 'An unexpected error occurred.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _authState = AuthState.loading;
      _errorMessage = null;
      notifyListeners();

      final user = await _authService.signInWithGoogle();
      _currentUser = user;
      _authState = AuthState.authenticated;
      notifyListeners();
      return true;

    } catch (e) {
      _authState = AuthState.unauthenticated;
      _errorMessage = 'Google sign in failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithApple() async {
    try {
      _authState = AuthState.loading;
      _errorMessage = null;
      notifyListeners();

      final user = await _authService.signInWithApple();
      _currentUser = user;
      _authState = AuthState.authenticated;
      notifyListeners();
      return true;

    } catch (e) {
      _authState = AuthState.unauthenticated;
      _errorMessage = 'Apple sign in failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Sign Up Method
  Future<bool> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      _authState = AuthState.loading;
      _errorMessage = null;
      notifyListeners();

      final user = await _authService.signUpWithEmail(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );

      _currentUser = user;
      _authState = AuthState.authenticated;
      notifyListeners();
      return true;

    } on FirebaseAuthException catch (e) {
      _authState = AuthState.unauthenticated;
      switch (e.code) {
        case 'email-already-in-use':
          _errorMessage = 'An account already exists with this email address.';
          break;
        case 'invalid-email':
          _errorMessage = 'Invalid email address.';
          break;
        case 'weak-password':
          _errorMessage = 'Password is too weak. Use at least 6 characters.';
          break;
        case 'operation-not-allowed':
          _errorMessage = 'Email/password accounts are not enabled.';
          break;
        default:
          _errorMessage = 'Sign up failed: ${e.message}';
      }
      notifyListeners();
      return false;

    } catch (e) {
      _authState = AuthState.unauthenticated;
      _errorMessage = 'An unexpected error occurred.';
      notifyListeners();
      return false;
    }
  }

  // Password Reset
  Future<bool> resetPassword(String email) async {
    try {
      _errorMessage = null;
      notifyListeners();

      await _authService.resetPassword(email);

      // Show success message
      _errorMessage = 'Password reset email sent successfully.';
      notifyListeners();
      return true;

    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          _errorMessage = 'Invalid email address.';
          break;
        case 'user-not-found':
          _errorMessage = 'No user found with this email address.';
          break;
        default:
          _errorMessage = 'Password reset failed: ${e.message}';
      }
      notifyListeners();
      return false;

    } catch (e) {
      _errorMessage = 'An unexpected error occurred.';
      notifyListeners();
      return false;
    }
  }

  // Profile Update
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImageUrl,
  }) async {
    if (_currentUser == null) return false;

    try {
      await _authService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );

      // Update local user with new info
      _currentUser = _currentUser!.copyWith(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        profileImageUrl: profileImageUrl,
      );

      notifyListeners();
      return true;

    } catch (e) {
      _errorMessage = 'Profile update failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _currentUser = null;
      _authState = AuthState.unauthenticated;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Sign out failed: ${e.toString()}';
      notifyListeners();
    }
  }

  // Account Deletion
  Future<bool> deleteAccount() async {
    try {
      await _authService.deleteAccount();
      _currentUser = null;
      _authState = AuthState.unauthenticated;
      _errorMessage = null;
      notifyListeners();
      return true;

    } catch (e) {
      _errorMessage = 'Account deletion failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Clear Error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Refresh User Data
  Future<bool> refreshUser() async {
    if (_authService.currentUser == null) return false;

    try {
      // Re-fetch user data from Firestore
      final user = await _authService.signInWithEmail(
        email: _authService.currentUser!.email!,
        password: '',
      );

      _currentUser = user;
      notifyListeners();
      return true;

    } catch (e) {
      debugPrint('Failed to refresh user data: $e');
      return false;
    }
  }
}
