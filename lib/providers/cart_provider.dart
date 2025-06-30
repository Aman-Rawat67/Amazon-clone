import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

/// Provider for FirestoreService instance
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

/// Provider for managing cart state and operations
final cartProvider = AsyncNotifierProvider<CartNotifier, CartModel?>(() {
  return CartNotifier();
});

/// Stream notifier for cart management with real-time Firestore sync
class CartNotifier extends AsyncNotifier<CartModel?> {
  late final FirestoreService _firestoreService;
  final Uuid _uuid = const Uuid();
  String? _userId;

  @override
  Future<CartModel?> build() async {
    _firestoreService = ref.read(firestoreServiceProvider);
    _userId = ref.read(userIdProvider);
    
    if (_userId == null) return null;
    
    try {
      return await _firestoreService.streamCart(_userId!).first;
    } catch (e) {
      throw Exception('Failed to load cart: $e');
    }
  }

  /// Add item to cart
  Future<void> addToCart({
    required ProductModel product,
    required int quantity,
    String? selectedColor,
    String? selectedSize,
  }) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final cart = await _firestoreService.streamCart(_userId!).first;
      
      // Create a unique ID for the cart item based on product and selections
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

      final updatedCart = cart?.copyWith(
        items: [...(cart.items), cartItem],
        updatedAt: DateTime.now(),
      ) ?? CartModel(
        id: _uuid.v4(),
        userId: _userId!,
        items: [cartItem],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _firestoreService.updateCart(updatedCart);
      return updatedCart;
    });
  }

  /// Create unique ID for cart item (prevents duplicates)
  String _createCartItemId(String productId, String? selectedColor, String? selectedSize) {
    final colorKey = selectedColor ?? 'default';
    final sizeKey = selectedSize ?? 'default';
    return '${productId}_${colorKey}_${sizeKey}';
  }

  /// Remove item from cart
  Future<void> removeFromCart(String productId) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final cart = await _firestoreService.streamCart(_userId!).first;
      if (cart == null) return null;

      final updatedCart = cart.removeItem(productId);
      await _firestoreService.updateCart(updatedCart);
      return updatedCart;
    });
  }

  /// Update item quantity in cart
  Future<void> updateQuantity(String productId, int quantity) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final cart = await _firestoreService.streamCart(_userId!).first;
      if (cart == null) return null;

      final updatedCart = cart.updateQuantity(productId, quantity);
      await _firestoreService.updateCart(updatedCart);
      return updatedCart;
    });
  }

  /// Clear the cart
  Future<void> clearCart() async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final cart = await _firestoreService.streamCart(_userId!).first;
      if (cart == null) return null;

      await _firestoreService.deleteCart(cart.id);
      return null;
    });
  }

  /// Get total items count from current state
  int getTotalItemsCount() {
    final cart = state.value;
    if (cart == null) return 0;
    return cart.items.fold(0, (sum, item) => sum + item.quantity);
  }

  /// Get cart subtotal from current state
  double getSubtotal() {
    final cart = state.value;
    if (cart == null) return 0.0;
    return cart.items.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
  }

  /// Get cart total including shipping and tax
  double getTotal() {
    final subtotal = getSubtotal();
    final shipping = calculateShipping(subtotal);
    final tax = subtotal * 0.05; // 5% tax
    return subtotal + shipping + tax;
  }

  /// Check if cart has items
  bool hasItems() {
    return state.value?.items.isNotEmpty ?? false;
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