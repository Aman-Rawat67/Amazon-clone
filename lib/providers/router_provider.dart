import 'package:amazon_clone/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../models/order_model.dart';
import 'auth_provider.dart';
import 'cart_provider.dart';
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
      notifyListeners();
    });
  }

  bool get _isAuthenticated => _ref.read(userProvider).asData?.value != null;
  bool get _isVendor => _ref.read(userProvider).asData?.value?.role == UserRole.vendor;
  bool get _isAdmin => _ref.read(userProvider).asData?.value?.role == UserRole.admin;

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
      if (_isVendor && !state.matchedLocation.startsWith('/vendor')) {
        return '/vendor';
      }
      if (_isAdmin && !state.matchedLocation.startsWith('/admin')) {
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
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    refreshListenable: notifier,
    redirect: notifier.redirect,
    initialLocation: '/splash',
    routes: [
      // Auth & System Routes
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final redirectAfter = state.uri.queryParameters['redirect'];
          return LoginScreen(redirectAfter: redirectAfter);
        },
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Customer Routes
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
            return const OrdersScreen();
          }
          return OrderSuccessScreen(order: order);
        },
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) {
          final cartAsync = ref.read(cartProvider);
          return cartAsync.when(
            data: (cart) {
              if (cart == null || cart.items.isEmpty) {
                return const CartScreen();
              }
              return const CheckoutScreen();
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const CartScreen(),
          );
        },
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final productId = state.pathParameters['id']!;
          return ProductDetailScreen(productId: productId);
        },
      ),
      GoRoute(
        path: '/category/:category',
        builder: (context, state) {
          final category = state.pathParameters['category'] ?? '';
          return CategoryProductsScreen(
            category: category,
            subcategory: null,
          );
        },
      ),
      GoRoute(
        path: '/category/:category/subcategory/:subcategory',
        builder: (context, state) {
          final category = state.pathParameters['category'] ?? '';
          final subcategory = state.pathParameters['subcategory'] ?? '';
          
          if (category.isEmpty) {
            return const DynamicHomeScreen();
          }
          
          return CategoryProductsScreen(
            category: category,
            subcategory: subcategory,
          );
        },
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) {
          final query = state.uri.queryParameters['q'] ?? '';
          return SearchResultsScreen(query: query);
        },
      ),

      // Vendor Routes
      GoRoute(
        path: '/vendor',
        builder: (context, state) {
          if (!notifier._isAuthenticated || !notifier._isVendor) {
            final destination = state.uri.toString();
            return LoginScreen(redirectAfter: destination);
          }
          return const VendorDashboardScreen();
        },
      ),
      GoRoute(
        path: '/vendor/products',
        builder: (context, state) {
          if (!notifier._isAuthenticated || !notifier._isVendor) {
            final destination = state.uri.toString();
            return LoginScreen(redirectAfter: destination);
          }
          return const VendorProductsScreen();
        },
      ),
      GoRoute(
        path: '/vendor/add-product',
        builder: (context, state) {
          if (!notifier._isAuthenticated || !notifier._isVendor) {
            final destination = state.uri.toString();
            return LoginScreen(redirectAfter: destination);
          }
          return const AddProductScreen();
        },
      ),
      GoRoute(
        path: '/vendor/orders',
        builder: (context, state) {
          if (!notifier._isAuthenticated || !notifier._isVendor) {
            final destination = state.uri.toString();
            return LoginScreen(redirectAfter: destination);
          }
          return const VendorOrdersScreen();
        },
      ),

      // Admin Routes
      GoRoute(
        path: '/admin',
        builder: (context, state) {
          if (!notifier._isAuthenticated || !notifier._isAdmin) {
            final destination = state.uri.toString();
            return LoginScreen(redirectAfter: destination);
          }
          return const AdminProductApprovalScreen();
        },
      ),

      // Debug Routes
      GoRoute(
        path: '/debug/firestore',
        builder: (context, state) => const DebugFirestoreScreen(),
      ),
      GoRoute(
        path: '/debug/dynamic-home',
        builder: (context, state) => const TestDynamicHomepage(),
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