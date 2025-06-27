import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/customer/home_screen.dart';
import 'screens/customer/product_detail_screen.dart';
import 'screens/customer/cart_screen.dart';
import 'screens/customer/checkout_screen.dart';
import 'screens/customer/orders_screen.dart';
import 'screens/customer/profile_screen.dart';
import 'screens/vendor/vendor_dashboard_screen.dart';
   import 'firebase_options.dart';
// TODO: Implement missing screens
// import 'screens/vendor/add_product_screen.dart';
// import 'screens/vendor/vendor_products_screen.dart';
// import 'screens/vendor/vendor_orders_screen.dart';
// import 'screens/admin/admin_dashboard_screen.dart';
// import 'screens/admin/manage_products_screen.dart';
// import 'screens/admin/manage_users_screen.dart';
// import 'screens/admin/admin_orders_screen.dart';
import 'constants/app_constants.dart';
import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
       options: DefaultFirebaseOptions.currentPlatform,
     );
  
  runApp(
    const ProviderScope(
      child: AmazonCloneApp(),
    ),
  );
}

class AmazonCloneApp extends ConsumerWidget {
  const AmazonCloneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }

  /// Build light theme
  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      fontFamily: 'AmazonEmber',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingMedium,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: AppDimensions.elevationLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
      ),
    );
  }

  /// Build dark theme
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      fontFamily: 'AmazonEmber',
    );
  }
}

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(userProvider);
  
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.asData?.value != null;
      final user = authState.asData?.value;
      
      // If on splash screen, stay there until auth state is determined
      if (state.matchedLocation == '/splash') {
        return authState.when(
          data: (user) {
            if (user != null) {
              // Redirect based on user role
              switch (user.role) {
                case UserRole.admin:
                  return '/admin';
                case UserRole.vendor:
                  return '/vendor';
                case UserRole.customer:
                  return '/home';
              }
            }
            return '/login';
          },
          loading: () => null, // Stay on splash
          error: (_, __) => '/login',
        );
      }
      
      // If not authenticated and trying to access protected routes
      if (!isAuthenticated && !_isPublicRoute(state.matchedLocation)) {
        return '/login';
      }
      
      // If authenticated and trying to access auth screens
      if (isAuthenticated && _isAuthRoute(state.matchedLocation)) {
        // Redirect based on user role
        switch (user?.role) {
          case UserRole.admin:
            return '/admin';
          case UserRole.vendor:
            return '/vendor';
          case UserRole.customer:
            return '/home';
          default:
            return '/login';
        }
      }
      
      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Authentication Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      
      // Customer Routes
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) => ProductDetailScreen(
          productId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      
      // Vendor Routes
      GoRoute(
        path: '/vendor',
        builder: (context, state) => const VendorDashboardScreen(),
      ),
      GoRoute(
        path: '/vendor/products',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Vendor Products - Coming Soon')),
        ),
      ),
      GoRoute(
        path: '/vendor/add-product',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Add Product - Coming Soon')),
        ),
      ),
      GoRoute(
        path: '/vendor/orders',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Vendor Orders - Coming Soon')),
        ),
      ),
      
      // Admin Routes
      GoRoute(
        path: '/admin',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Admin Dashboard - Coming Soon')),
        ),
      ),
      GoRoute(
        path: '/admin/products',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Manage Products - Coming Soon')),
        ),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Manage Users - Coming Soon')),
        ),
      ),
      GoRoute(
        path: '/admin/orders',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Admin Orders - Coming Soon')),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.matchedLocation}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Check if route is public (doesn't require authentication)
bool _isPublicRoute(String route) {
  return ['/login', '/register', '/splash'].contains(route);
}

/// Check if route is an authentication route
bool _isAuthRoute(String route) {
  return ['/login', '/register'].contains(route);
}
