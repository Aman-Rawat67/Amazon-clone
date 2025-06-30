import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Provider for authentication service
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Provider for Firebase Auth stream
final authStreamProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Provider for current user model
final userProvider = StateNotifierProvider<UserNotifier, AsyncValue<UserModel?>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return UserNotifier(authService);
});

/// State notifier for user management
class UserNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _authService;

  UserNotifier(this._authService) : super(const AsyncValue.loading()) {
    _init();
  }

  /// Initialize and listen to auth state changes
  void _init() {
    _authService.authStateChanges.listen((User? user) async {
      if (user != null) {
        try {
          final userModel = await _authService.getUserData(user.uid);
          state = AsyncValue.data(userModel);
        } catch (e) {
          state = AsyncValue.error(e, StackTrace.current);
        }
      } else {
        state = const AsyncValue.data(null);
      }
    });
  }

  /// Sign up with email and password
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
    UserRole role = UserRole.customer,
  }) async {
    try {
      state = const AsyncValue.loading();
      final userModel = await _authService.signUpWithEmail(
        email: email,
        password: password,
        name: name,
        phoneNumber: phoneNumber,
        role: role,
      );
      state = AsyncValue.data(userModel);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      state = const AsyncValue.loading();
      final userModel = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      state = AsyncValue.data(userModel);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      state = const AsyncValue.loading();
      final userModel = await _authService.signInWithGoogle();
      state = AsyncValue.data(userModel);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await _authService.sendEmailVerification();
    } catch (e) {
      rethrow;
    }
  }

  /// Reload user to check verification status
  Future<void> reloadUser() async {
    try {
      await _authService.reloadUser();
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final userModel = await _authService.getUserData(currentUser.uid);
        state = AsyncValue.data(userModel);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      await _authService.updateProfile(
        displayName: displayName,
        photoURL: photoURL,
      );
      
      // Update user data in Firestore
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final updateData = <String, dynamic>{};
        if (displayName != null) updateData['name'] = displayName;
        if (photoURL != null) updateData['profileImageUrl'] = photoURL;
        
        if (updateData.isNotEmpty) {
          await _authService.updateUserData(currentUser.uid, updateData);
          final userModel = await _authService.getUserData(currentUser.uid);
          state = AsyncValue.data(userModel);
        }
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Update user password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _authService.updatePassword(newPassword);
    } catch (e) {
      rethrow;
    }
  }

  /// Update user data
  Future<void> updateUserData(Map<String, dynamic> data) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        await _authService.updateUserData(currentUser.uid, data);
        final userModel = await _authService.getUserData(currentUser.uid);
        state = AsyncValue.data(userModel);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Delete account
  Future<void> deleteAccount() async {
    try {
      await _authService.deleteAccount();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Re-authenticate with password
  Future<void> reauthenticateWithPassword(String password) async {
    try {
      await _authService.reauthenticateWithPassword(password);
    } catch (e) {
      rethrow;
    }
  }

  /// Check if email is already registered
  Future<bool> isEmailRegistered(String email) async {
    try {
      return await _authService.isEmailRegistered(email);
    } catch (e) {
      return false;
    }
  }

  /// Get current user model
  UserModel? get currentUser {
    return state.asData?.value;
  }

  /// Check if user is authenticated
  bool get isAuthenticated {
    return currentUser != null;
  }

  /// Check if user is admin
  bool get isAdmin {
    return currentUser?.role == UserRole.admin;
  }

  /// Check if user is vendor
  bool get isVendor {
    return currentUser?.role == UserRole.vendor;
  }

  /// Check if user is customer
  bool get isCustomer {
    return currentUser?.role == UserRole.customer;
  }

  /// Check if user is verified
  bool get isVerified {
    return currentUser?.isVerified ?? false;
  }
}

/// Provider for checking authentication status
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(userProvider);
  return user.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider for checking admin status
final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(userProvider);
  return user.when(
    data: (user) => user?.role == UserRole.admin,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider for checking vendor status
final isVendorProvider = Provider<bool>((ref) {
  final user = ref.watch(userProvider);
  return user.when(
    data: (user) => user?.role == UserRole.vendor,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider for checking customer status
final isCustomerProvider = Provider<bool>((ref) {
  final user = ref.watch(userProvider);
  return user.when(
    data: (user) => user?.role == UserRole.customer,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider for current user ID
final userIdProvider = Provider<String?>((ref) {
  final user = ref.watch(userProvider);
  return user.when(
    data: (user) => user?.id,
    loading: () => null,
    error: (_, __) => null,
  );
});