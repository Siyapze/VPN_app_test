import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/models/user_model.dart';
import '../constants/app_constants.dart';

/// Authentication service for STRESSLESS VPN
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current user data from Firestore
  Future<UserModel?> getCurrentUserData() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        // Create user document if it doesn't exist
        await _createUserDocument(user);
        final newDoc = await _firestore.collection('users').doc(user.uid).get();
        return UserModel.fromFirestore(newDoc, user.uid, user.email ?? '');
      }
      return UserModel.fromFirestore(doc, user.uid, user.email ?? '');
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  /// Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (displayName != null && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
      }

      // Create user document in Firestore
      if (credential.user != null) {
        await _createUserDocument(credential.user!, displayName: displayName);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      print('Sign up error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected sign up error: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login time
      if (credential.user != null) {
        await _updateLastLogin(credential.user!.uid);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      print('Sign in error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected sign in error: $e');
      rethrow;
    }
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Create or update user document
      if (userCredential.user != null) {
        await _createUserDocument(userCredential.user!);
        await _updateLastLogin(userCredential.user!.uid);
      }

      return userCredential;
    } catch (e) {
      print('Google sign in error: $e');
      rethrow;
    }
  }

  /// Sign in anonymously (for trial users)
  Future<UserCredential?> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();

      // Create user document for anonymous user
      if (credential.user != null) {
        await _createUserDocument(credential.user!);
      }

      return credential;
    } catch (e) {
      print('Anonymous sign in error: $e');
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print('Password reset error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected password reset error: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Password reset error: $e');
      rethrow;
    }
  }

  /// Start free trial for user
  Future<void> startFreeTrial(String uid) async {
    try {
      final now = DateTime.now();
      final trialEnd = now.add(Duration(days: AppConstants.freeTrialDays));

      await _firestore.collection('users').doc(uid).update({
        'hasUsedTrial': true,
        'trialStartedAt': Timestamp.fromDate(now),
        'trialExpiresAt': Timestamp.fromDate(trialEnd),
      });
    } catch (e) {
      print('Error starting trial: $e');
      rethrow;
    }
  }

  /// Upgrade user to premium
  Future<void> upgradeToPremium(String uid, {int durationDays = 30}) async {
    try {
      final now = DateTime.now();
      final premiumEnd = now.add(Duration(days: durationDays));

      await _firestore.collection('users').doc(uid).update({
        'isPremium': true,
        'premiumExpiresAt': Timestamp.fromDate(premiumEnd),
      });
    } catch (e) {
      print('Error upgrading to premium: $e');
      rethrow;
    }
  }

  /// Create user document in Firestore
  Future<void> _createUserDocument(User user, {String? displayName}) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        final userData = {
          'displayName': displayName ?? user.displayName,
          'photoURL': user.photoURL,
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'lastLoginAt': Timestamp.fromDate(DateTime.now()),
          'isPremium': false,
          'hasUsedTrial': false,
          'connectionCount': 0,
        };

        await userDoc.set(userData);
      }
    } catch (e) {
      print('Error creating user document: $e');
      rethrow;
    }
  }

  /// Update last login time
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error updating last login: $e');
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) return;

      // Delete user document from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete Firebase Auth account
      await user.delete();
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }
}
