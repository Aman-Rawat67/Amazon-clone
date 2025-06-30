import 'package:amazon_clone/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../models/order_model.dart';
import 'auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/customer/dynamic_home_screen.dart';
import '../screens/test_dynamic_homepage.dart';
import '../screens/debug_firestore_screen.dart';
import '../screens/admin/admin_product_approval_screen.dart';
import '../screens/customer/product_detail_screen.dart';
import '../screens/customer/cart_screen.dart';
import '../screens/customer/checkout_screen.dart';
import '../screens/customer/orders_screen.dart';
import '../screens/customer/order_success_screen.dart';
import '../screens/customer/profile_screen.dart';
import '../screens/customer/category_products_screen.dart';
import '../screens/vendor/vendor_dashboard_screen.dart';
import '../screens/vendor/vendor_products_screen.dart';
import '../screens/vendor/add_product_screen.dart';
import '../screens/vendor/vendor_orders_screen.dart';
import '../screens/customer/search_results_screen.dart';
import '../screens/customer/address_screen.dart';
import '../screens/customer/home_screen.dart';

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  String? _previousLocation;

  RouterNotifier(this._ref) {
    _ref.listen(userProvider, (previous, next) {
      // Trigger router refresh when auth state changes
      notifyListeners();
    });
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final user = _ref.read(userProvider).asData?.value;
    final isAuthenticated = user != null;

    final isSplash = state.matchedLocation == '/splash';
    final isLoggingIn = state.matchedLocation == '/login';
    final isRegistering = state.matchedLocation == '/register';
    final isPublic = ['/splash', '/login', '/register'].contains(state.matchedLocation);

    // Store previous location for redirecting back after login
    if (!isPublic && !isAuthenticated) {
      _previousLocation = state.matchedLocation;
    }

    // Handle product detail routes specially
    if (state.matchedLocation.startsWith('/product/')) {
      if (!isAuthenticated) {
        // Store the product detail URL to redirect back after login
        _previousLocation = state.matchedLocation;
        return '/login';
      }
      return null;
    }

    // Splash screen logic
    if (isSplash) {
      if (_ref.read(userProvider).isLoading) return null;
      if (!isAuthenticated) return '/login';
      return _getHomeRouteForRole(user.role);
    }

    // Auth screen logic
    if (isLoggingIn || isRegistering) {
      if (isAuthenticated) {
        // If there was a previous location, redirect there
        if (_previousLocation != null) {
          final location = _previousLocation;
          _previousLocation = null;
          return location;
        }
        return _getHomeRouteForRole(user.role);
      }
      return null;
    }

    // Protected route logic
    if (!isAuthenticated && !isPublic) {
      return '/login';
    }

    // Role-based route protection
    if (isAuthenticated) {
      if (user.role == UserRole.vendor && !state.matchedLocation.startsWith('/vendor')) {
        return '/vendor';
      }
      if (user.role == UserRole.admin && !state.matchedLocation.startsWith('/admin')) {
        return '/admin';
      }
    }

    return null;
  }

  String _getHomeRouteForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return '/admin';
      case UserRole.vendor:
        return '/vendor';
      case UserRole.customer:
        return '/home';
    }
  }
}

/// Router provider for app navigation
final routerProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  final isVendor = ref.watch(isVendorProvider);

  return GoRouter(
    initialLocation: '/',
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Customer routes
      GoRoute(
        path: '/',
        builder: (context, state) => const DynamicHomeScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const DynamicHomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/addresses',
        builder: (context, state) => const AddressScreen(),
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/order-success',
        builder: (context, state) {
          final order = state.extra as OrderModel?;
          if (order == null) {
            // Create a dummy order if none provided
            return OrderSuccessScreen(
              order: OrderModel(
                id: '',
                userId: '',
                orderNumber: '',
                items: [],
                subtotal: 0,
                totalAmount: 0,
                paymentMethod: '',
                shippingAddress: ShippingAddress(
                  id: '',
                  name: '',
                  phone: '',
                  address: '',
                  city: '',
                  state: '',
                  zipCode: '',
                  country: '',
                ),
                createdAt: DateTime.now(),
              ),
            );
          }
          return OrderSuccessScreen(order: order);
        },
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) => ProductDetailScreen(
          productId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/category/:category',
        builder: (context, state) => CategoryProductsScreen(
          category: state.pathParameters['category']!,
        ),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => SearchResultsScreen(
          query: state.uri.queryParameters['q'] ?? '',
          category: state.uri.queryParameters['category'] ?? 'All',
        ),
      ),

      // Vendor routes
      GoRoute(
        path: '/vendor/dashboard',
        builder: (context, state) => const VendorDashboardScreen(),
        redirect: (context, state) {
          if (!isAuthenticated || !isVendor) {
            return '/login?redirect=${state.uri.path}';
          }
          return null;
        },
      ),
      GoRoute(
        path: '/vendor/products',
        builder: (context, state) => const VendorProductsScreen(),
        redirect: (context, state) {
          if (!isAuthenticated || !isVendor) {
            return '/login?redirect=${state.uri.path}';
          }
          return null;
        },
      ),
      GoRoute(
        path: '/vendor/add-product',
        builder: (context, state) => const AddProductScreen(),
        redirect: (context, state) {
          if (!isAuthenticated || !isVendor) {
            return '/login?redirect=${state.uri.path}';
          }
          return null;
        },
      ),
      GoRoute(
        path: '/vendor/orders',
        builder: (context, state) => const VendorOrdersScreen(),
        redirect: (context, state) {
          if (!isAuthenticated || !isVendor) {
            return '/login?redirect=${state.uri.path}';
          }
          return null;
        },
      ),

      // Test Routes
      GoRoute(
        path: '/test-dynamic',
        builder: (context, state) => const TestDynamicHomepage(),
      ),
      GoRoute(
        path: '/debug-firestore',
        builder: (context, state) => const DebugFirestoreScreen(),
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
      appBar: AppBar(
        title: const Text('Error'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: BackButton(
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.matchedLocation}',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    ),
  );
}); 