import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../constants/app_constants.dart';

/// Service class for handling authentication operations
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email and password
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
    UserRole role = UserRole.customer,
  }) async {
    try {
      // Create user with email and password
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user != null) {
        // Update display name
        await user.updateDisplayName(name);

        // Create user model
        final UserModel userModel = UserModel(
          id: user.uid,
          email: email,
          name: name,
          phoneNumber: phoneNumber,
          role: role,
          createdAt: DateTime.now(),
          isVerified: false,
        );

        // Save user data to Firestore
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .set(userModel.toJson());

        // Send email verification
        await user.sendEmailVerification();

        return userModel;
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
    return null;
  }

  /// Sign in with email and password
  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user != null) {
        // Update last login time
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .update({
          'lastLoginAt': Timestamp.fromDate(DateTime.now()),
        });

        // Get user data from Firestore
        return await getUserData(user.uid);
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
    return null;
  }

  /// Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User cancelled the sign-in
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential result = await _auth.signInWithCredential(credential);
      final User? user = result.user;

      if (user != null) {
        // Check if user exists in Firestore
        final userDoc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .get();

        UserModel userModel;

        if (userDoc.exists) {
          // Update last login time
          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(user.uid)
              .update({
            'lastLoginAt': Timestamp.fromDate(DateTime.now()),
          });

          userModel = UserModel.fromJson(userDoc.data()!);
        } else {
          // Create new user record
          userModel = UserModel(
            id: user.uid,
            email: user.email!,
            name: user.displayName ?? 'User',
            profileImageUrl: user.photoURL,
            role: UserRole.customer,
            createdAt: DateTime.now(),
            isVerified: user.emailVerified,
          );

          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(user.uid)
              .set(userModel.toJson());
        }

        return userModel;
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Google sign-in failed: ${e.toString()}');
    }
    return null;
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to send password reset email: ${e.toString()}');
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to send email verification: ${e.toString()}');
    }
  }

  /// Reload user to check verification status
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      throw Exception('Failed to reload user: ${e.toString()}');
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.updatePhotoURL(photoURL);
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  /// Update user password
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to update password: ${e.toString()}');
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user data from Firestore
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .delete();

        // Delete user account
        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }

  /// Get user data from Firestore
  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
    } catch (e) {
      throw Exception('Failed to get user data: ${e.toString()}');
    }
    return null;
  }

  /// Update user data in Firestore
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update(data);
    } catch (e) {
      throw Exception('Failed to update user data: ${e.toString()}');
    }
  }

  /// Check if email is already registered
  Future<bool> isEmailRegistered(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Re-authenticate user with password
  Future<void> reauthenticateWithPassword(String password) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Re-authentication failed: ${e.toString()}');
    }
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'user-disabled':
        return 'This user has been disabled.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-credential':
        return 'The provided credentials are invalid.';
      case 'account-exists-with-different-credential':
        return 'Account exists with different credentials.';
      case 'invalid-verification-code':
        return 'The verification code is invalid.';
      case 'invalid-verification-id':
        return 'The verification ID is invalid.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }
} 