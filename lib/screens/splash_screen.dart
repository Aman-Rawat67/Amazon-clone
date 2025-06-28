import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../constants/app_constants.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Splash screen displayed while app initializes
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Wait a bit to show splash screen
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      final userAsync = ref.read(userProvider);
      userAsync.when(
        data: (user) {
          if (user != null) {
            // User is logged in, router will handle navigation
          } else {
            // User is not logged in, go to login
            context.go('/login');
          }
        },
        loading: () {
          // Still loading, wait
        },
        error: (error, stack) {
          // Error occurred, go to login
          context.go('/login');
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shopping_bag,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            
            const SizedBox(height: AppDimensions.paddingLarge),
            
            // App Name
            const Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            
            const SizedBox(height: AppDimensions.paddingSmall),
            
            // Tagline
            const Text(
              'Everything you need, delivered',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w300,
              ),
            ),
            
            const SizedBox(height: AppDimensions.paddingXLarge),
            
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            
            const SizedBox(height: AppDimensions.paddingLarge),
            
            // Demo Setup Button (for development)
            if (const bool.fromEnvironment('dart.vm.product') == false)
              Column(
                children: [
                  const Text(
                    'Development Mode',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppDimensions.fontSmall,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingSmall),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _setupDemoAccounts,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          )
                        : const Text('Setup Demo Accounts'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _setupDemoAccounts() async {
    setState(() => _isLoading = true);
    
    try {
      // First create demo user documents in Firestore
      await FirestoreService().createDemoAccounts();
      
      // Then try to create actual Firebase Auth accounts
      await _createFirebaseAuthAccounts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demo accounts created successfully! You can now login with:\nVendor: vendor@demo.com / password123'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createFirebaseAuthAccounts() async {
    try {
      final auth = FirebaseAuth.instance;
      
      // Create vendor account
      try {
        await auth.createUserWithEmailAndPassword(
          email: 'vendor@gmail.com',
          password: '12345678',
        );
        print('Vendor account created successfully');
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          print('Vendor account already exists');
        } else {
          print('Error creating vendor account: $e');
        }
      }
      
      // Create customer account
      try {
        await auth.createUserWithEmailAndPassword(
          email: 'customer@demo.com',
          password: 'password123',
        );
        print('Customer account created successfully');
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          print('Customer account already exists');
        } else {
          print('Error creating customer account: $e');
        }
      }
      
      // Create admin account
      try {
        await auth.createUserWithEmailAndPassword(
          email: 'admin@demo.com',
          password: 'password123',
        );
        print('Admin account created successfully');
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          print('Admin account already exists');
        } else {
          print('Error creating admin account: $e');
        }
      }
    } catch (e) {
      print('Error in _createFirebaseAuthAccounts: $e');
    }
  }
} 