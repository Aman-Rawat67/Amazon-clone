import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

/// Provider for cart management with real-time updates
final cartProvider = StreamNotifierProvider<CartNotifier, CartModel?>(() {
  return CartNotifier();
});

/// Stream notifier for cart management with real-time Firestore sync
class CartNotifier extends StreamNotifier<CartModel?> {
  final FirestoreService _firestoreService = FirestoreService();
  final Uuid _uuid = const Uuid();
  String? _userId;

  @override
  Stream<CartModel?> build() {
    // Watch userId changes
    _userId = ref.watch(userIdProvider);
    
    if (_userId == null) {
      // Return empty stream for non-logged in users
      return Stream.value(null);
    }

    try {
      // Return real-time cart stream
      return _firestoreService.streamCart(_userId!).handleError((error) {
        print('🔥 Error streaming cart: $error');
        return null;
      });
    } catch (e) {
      print('🔥 Error building cart stream: $e');
      return Stream.value(null);
    }
  }

  /// Add item to cart with improved duplicate handling
  Future<void> addToCart({
    required ProductModel product,
    int quantity = 1,
    String? selectedColor,
    String? selectedSize,
  }) async {
    if (_userId == null) {
      throw Exception('User must be logged in to add items to cart');
    }

    try {
      // Create unique ID for cart item
      final itemId = _createCartItemId(product.id, selectedColor, selectedSize);
      
      final cartItem = CartItem(
        id: itemId,
        productId: product.id,
        product: product,
        quantity: quantity,
        selectedColor: selectedColor,
        selectedSize: selectedSize,
        addedAt: DateTime.now(),
      );

      await _firestoreService.addToCart(_userId!, cartItem);
      // No need to manually update state - stream will handle it automatically
    } catch (e) {
      rethrow;
    }
  }

  /// Create unique ID for cart item (prevents duplicates)
  String _createCartItemId(String productId, String? selectedColor, String? selectedSize) {
    final colorKey = selectedColor ?? 'default';
    final sizeKey = selectedSize ?? 'default';
    return '${productId}_${colorKey}_$sizeKey';
  }

  /// Update cart item quantity
  Future<void> updateQuantity(String itemId, int quantity) async {
    if (_userId == null) return;

    try {
      if (quantity <= 0) {
        await removeFromCart(itemId);
        return;
      }

      await _firestoreService.updateCartItemQuantity(_userId!, itemId, quantity);
      // No need to manually update state - stream will handle it automatically
    } catch (e) {
      rethrow;
    }
  }

  /// Remove item from cart
  Future<void> removeFromCart(String itemId) async {
    if (_userId == null) return;

    try {
      await _firestoreService.removeFromCart(_userId!, itemId);
      // No need to manually update state - stream will handle it automatically
    } catch (e) {
      rethrow;
    }
  }

  /// Clear entire cart
  Future<void> clearCart() async {
    if (_userId == null) return;

    try {
      await _firestoreService.clearCart(_userId!);
      // No need to manually update state - stream will handle it automatically
    } catch (e) {
      rethrow;
    }
  }

  /// Get total items count from current state
  int getTotalItemsCount() {
    final cart = state.value;
    return cart?.totalItems ?? 0;
  }

  /// Get cart subtotal from current state
  double getSubtotal() {
    final cart = state.value;
    return cart?.totalPrice ?? 0.0;
  }

  /// Get cart total including shipping
  double getTotal() {
    final cart = state.value;
    return cart?.total ?? 0.0;
  }

  /// Calculate cart total with central function
  static double calculateCartTotal(List<CartItem> items) {
    return items.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
  }

  /// Calculate shipping fee
  static double calculateShipping(double subtotal) {
    return subtotal >= 100.0 ? 0.0 : 10.0;
  }
}

/// Provider for cart item count with real-time updates
final cartItemCountProvider = Provider<int>((ref) {
  final cartAsync = ref.watch(cartProvider);
  return cartAsync.when(
    data: (cart) => cart?.totalItems ?? 0,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for cart subtotal with real-time updates
final cartSubtotalProvider = Provider<double>((ref) {
  final cartAsync = ref.watch(cartProvider);
  return cartAsync.when(
    data: (cart) => cart?.totalPrice ?? 0.0,
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

/// Provider for cart recommendations
final cartRecommendationsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return [];
  
  final firestoreService = FirestoreService();
  return firestoreService.getCartRecommendations(userId, limit: 6);
});

/// Provider for popular products (fallback)
final popularProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final firestoreService = FirestoreService();
  return firestoreService.getPopularProducts(limit: 6);
});

/// Provider for recently viewed products
final recentlyViewedProvider = FutureProvider.family<List<ProductModel>, String>((ref, userId) async {
  final firestoreService = FirestoreService();
  return firestoreService.getRecentlyViewedProducts(userId, limit: 4);
}); 