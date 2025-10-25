
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as app_user;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Rate limiting configuration
  static const int _maxAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);
  static const String _rateLimitCollection = 'rate_limits';

  // Stream for auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  /// Check if an email is currently rate limited
  Future<bool> _isRateLimited(String email) async {
    try {
      final doc = await _firestore.collection(_rateLimitCollection).doc(email).get();
      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null) return false;

      final attempts = data['attempts'] as int? ?? 0;
      final lastAttempt = (data['last_attempt'] as Timestamp?)?.toDate();

      if (lastAttempt == null) return false;

      final now = DateTime.now();

      // Reset counter if enough time has passed
      if (now.difference(lastAttempt) > _lockoutDuration) {
        await _resetRateLimit(email);
        return false;
      }

      return attempts >= _maxAttempts;
    } catch (e) {
      // On error, allow attempt (fail open for UX)
      return false;
    }
  }

  /// Record a failed login attempt
  Future<void> _recordFailedAttempt(String email) async {
    try {
      final docRef = _firestore.collection(_rateLimitCollection).doc(email);
      final doc = await docRef.get();

      int attempts = 1;
      if (doc.exists) {
        attempts = (doc.data()?['attempts'] as int? ?? 0) + 1;
      }

      await docRef.set({
        'attempts': attempts,
        'last_attempt': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Don't throw - rate limiting failure shouldn't block auth
      // Note: Rate limiting errors are logged but don't block authentication
    }
  }

  /// Reset rate limit counter for an email
  Future<void> _resetRateLimit(String email) async {
    try {
      await _firestore.collection(_rateLimitCollection).doc(email).delete();
    } catch (e) {
      // Don't throw - cleanup failure is non-critical
      debugPrint('Failed to reset rate limit: $e');
    }
  }

  // Sign up with email and password
  Future<app_user.User> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName('$firstName $lastName');

      // Create user profile in Firestore
      final user = app_user.User(
        id: userCredential.user!.uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        createdAt: DateTime.now(),
        isAdmin: false,
        loyaltyPoints: 0,
        serviceRequestsCount: 0,
      );

      await _createUserProfile(user);

      return user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw 'An account already exists with this email address.';
        case 'invalid-email':
          throw 'The email address is invalid.';
        case 'weak-password':
          throw 'The password is too weak. Please choose a stronger password.';
        case 'operation-not-allowed':
          throw 'Email/password accounts are not enabled.';
        default:
          throw 'Sign up failed: ${e.message}';
      }
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  // Sign in with email and password
  Future<app_user.User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Check rate limiting before attempting authentication
      if (await _isRateLimited(email.trim())) {
        await _recordFailedAttempt(email.trim()); // Record this attempt
        throw 'Too many failed login attempts. Please try again in 15 minutes.';
      }
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Get user profile from Firestore
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      if (!userDoc.exists) {
        // Create profile if it doesn't exist (legacy user)
        await _createUserProfileFromFirebase(userCredential.user!);
        final newUserDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        return app_user.User.fromFirestore(newUserDoc);
      }

      return app_user.User.fromFirestore(userDoc);
    } on FirebaseAuthException catch (e) {
      // Record failed attempt for rate limiting
      await _recordFailedAttempt(email.trim());

      switch (e.code) {
        case 'user-not-found':
          throw 'No user found with this email address.';
        case 'wrong-password':
          throw 'Wrong password provided.';
        case 'invalid-email':
          throw 'The email address is invalid.';
        case 'user-disabled':
          throw 'This user account has been disabled.';
        case 'too-many-requests':
          throw 'Too many failed login attempts. Try again later.';
        default:
          throw 'Sign in failed: ${e.message}';
      }
    } catch (e) {
      // Record failed attempt for unexpected errors too
      await _recordFailedAttempt(email.trim());
      throw 'An unexpected error occurred: $e';
    }
  }

  // Sign in with Google
  Future<app_user.User> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw 'Google sign in was cancelled.';
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Get user profile from Firestore or create if doesn't exist
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      if (!userDoc.exists) {
        await _createUserProfileFromFirebase(userCredential.user!);
        final newUserDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        return app_user.User.fromFirestore(newUserDoc);
      }

      return app_user.User.fromFirestore(userDoc);
    } catch (e) {
      throw 'Google sign in failed: $e';
    }
  }

  // Sign in with Apple (iOS)
  Future<app_user.User> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create an OAuthCredential from the credential returned by Apple
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase with the credential
      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // Get user profile or create if doesn't exist
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      if (!userDoc.exists) {
        await _createUserProfileFromFirebase(userCredential.user!);
        final newUserDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        return app_user.User.fromFirestore(newUserDoc);
      }

      return app_user.User.fromFirestore(userDoc);
    } catch (e) {
      throw 'Apple sign in failed: $e';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Password reset
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          throw 'The email address is invalid.';
        case 'user-not-found':
          throw 'No user found with this email address.';
        default:
          throw 'Password reset failed: ${e.message}';
      }
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    try {
      if (_auth.currentUser == null) throw 'No user signed in';

      if (firstName != null || lastName != null) {
        String displayName = currentUser!.displayName ?? '';
        if (firstName != null && lastName != null) {
          displayName = '$firstName $lastName';
        }
        await currentUser!.updateDisplayName(displayName);
      }

      // Update Firestore profile
      final updates = <String, dynamic>{};
      if (firstName != null) updates['firstName'] = firstName;
      if (lastName != null) updates['lastName'] = lastName;
      if (phone != null) updates['phone'] = phone;
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(currentUser!.uid).update(updates);
    } catch (e) {
      throw 'Profile update failed: $e';
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      if (_auth.currentUser == null) throw 'No user signed in';

      // Delete Firestore document
      await _firestore.collection('users').doc(currentUser!.uid).delete();

      // Delete auth account
      await currentUser!.delete();

      // Sign out locally
      await signOut();
    } catch (e) {
      throw 'Account deletion failed: $e';
    }
  }

  // Helper method to create user profile
  Future<void> _createUserProfile(app_user.User user) async {
    await _firestore.collection('users').doc(user.id).set(user.toFirestore());
  }

  // Helper method to create user profile from Firebase User
  Future<void> _createUserProfileFromFirebase(User firebaseUser) async {
    final names = firebaseUser.displayName?.split(' ') ?? ['', ''];
    final user = app_user.User(
      id: firebaseUser.uid,
      email: firebaseUser.email!,
      firstName: names.isNotEmpty ? names[0] : '',
      lastName: names.length > 1 ? names[1] : '',
      phone: firebaseUser.phoneNumber,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      isAdmin: false,
      loyaltyPoints: 0,
      serviceRequestsCount: 0,
    );

    await _createUserProfile(user);
  }
}
