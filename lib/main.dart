import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/customer/dynamic_home_screen.dart';
import 'screens/test_dynamic_homepage.dart';
import 'screens/debug_firestore_screen.dart';
import 'screens/admin/admin_product_approval_screen.dart';
import 'screens/customer/product_detail_screen.dart';
import 'screens/customer/dynamic_home_screen.dart';
import 'screens/customer/cart_screen.dart';
import 'screens/customer/checkout_screen.dart';
import 'screens/customer/orders_screen.dart';
import 'screens/customer/order_success_screen.dart';
import 'screens/customer/profile_screen.dart';
import 'screens/customer/category_products_screen.dart';
import 'screens/vendor/vendor_dashboard_screen.dart';
import 'screens/vendor/vendor_products_screen.dart';
import 'screens/vendor/add_product_screen.dart';
import 'screens/vendor/vendor_orders_screen.dart';
import 'firebase_options.dart';
// TODO: Implement missing screens
// import 'screens/admin/admin_dashboard_screen.dart';
// import 'screens/admin/manage_products_screen.dart';
// import 'screens/admin/manage_users_screen.dart';
// import 'screens/admin/admin_orders_screen.dart';
import 'constants/app_constants.dart';
import 'models/user_model.dart';
import 'models/order_model.dart';

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
      darkTheme: _buildTheme(), // Use light theme for dark mode too
      themeMode: ThemeMode.light, // Force light theme always
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
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: Colors.white,
        background: const Color(0xFFF5F5F5),
        onSurface: Colors.black87,
        onBackground: Colors.black87,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      cardColor: Colors.white,
      fontFamily: 'AmazonEmber',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'AmazonEmber',
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'AmazonEmber',
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'AmazonEmber',
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingMedium,
        ),
        labelStyle: const TextStyle(color: Colors.black87),
        hintStyle: TextStyle(color: Colors.grey.shade600),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: AppDimensions.elevationLow,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Colors.black87, fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: Colors.black87, fontSize: 28, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.normal),
        bodyMedium: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.normal),
        bodySmall: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.normal),
        labelLarge: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w500),
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
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        background: const Color(0xFF1A1A1A), // darker background
        surface: const Color(0xFF2D2D2D), // lighter card/field
        onBackground: Colors.white,
        onSurface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      cardColor: const Color(0xFF2D2D2D),
      fontFamily: 'AmazonEmber',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF232F3E),
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'AmazonEmber',
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'AmazonEmber',
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.amber,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'AmazonEmber',
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2D2D2D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: const BorderSide(color: Colors.white38),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: const BorderSide(color: Colors.white38),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: const BorderSide(color: Colors.amber, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingMedium,
        ),
        labelStyle: const TextStyle(color: Colors.white),
        hintStyle: const TextStyle(color: Colors.white60),
        helperStyle: const TextStyle(color: Colors.white54),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF2D2D2D),
        elevation: AppDimensions.elevationLow,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.normal),
        bodyMedium: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.normal),
        bodySmall: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.normal),
        labelLarge: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
      ),
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
      
      // If authenticated and vendor, allow any /vendor/* route
      if (isAuthenticated && user?.role == UserRole.vendor) {
        if (state.matchedLocation.startsWith('/vendor')) {
          return null; // Allow vendor to access any vendor route
        }
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
        builder: (context, state) => const DynamicHomeScreen(),
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
        path: '/order-success',
        builder: (context, state) => OrderSuccessScreen(
          order: state.extra as OrderModel,
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      
      // Category Products Route
      GoRoute(
        path: '/category/:categoryName',
        builder: (context, state) => CategoryProductsScreen(
          category: state.pathParameters['categoryName']!,
        ),
      ),
      
      // Test Route (temporary for testing dynamic homepage)
      GoRoute(
        path: '/test-dynamic',
        builder: (context, state) => const TestDynamicHomepage(),
      ),
      
      // Debug Route (temporary for debugging Firestore data)
      GoRoute(
        path: '/debug-firestore',
        builder: (context, state) => const DebugFirestoreScreen(),
      ),
      
      // Vendor Routes
      GoRoute(
        path: '/vendor',
        builder: (context, state) => const VendorDashboardScreen(),
      ),
      GoRoute(
        path: '/vendor/products',
        builder: (context, state) => const VendorProductsScreen(),
      ),
      GoRoute(
        path: '/vendor/add-product',
        builder: (context, state) => const AddProductScreen(),
      ),
      GoRoute(
        path: '/vendor/orders',
        builder: (context, state) => const VendorOrdersScreen(),
      ),
      
      // Admin Routes
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminProductApprovalScreen(),
      ),
      GoRoute(
        path: '/admin/products',
        builder: (context, state) => const AdminProductApprovalScreen(),
      ),
      GoRoute(
        path: '/admin/approvals',
        builder: (context, state) => const AdminProductApprovalScreen(),
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
