import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

/// Provider for cart management
final cartProvider = StateNotifierProvider<CartNotifier, AsyncValue<CartModel?>>((ref) {
  final firestoreService = FirestoreService();
  final userId = ref.watch(userIdProvider);
  return CartNotifier(firestoreService, userId);
});

/// State notifier for cart management
class CartNotifier extends StateNotifier<AsyncValue<CartModel?>> {
  final FirestoreService _firestoreService;
  final String? _userId;
  final Uuid _uuid = const Uuid();

  CartNotifier(this._firestoreService, this._userId) : super(const AsyncValue.loading()) {
    if (_userId != null) {
      loadCart();
    } else {
      state = const AsyncValue.data(null);
    }
  }

  /// Load user's cart from Firestore
  Future<void> loadCart() async {
    if (_userId == null) {
      state = const AsyncValue.data(null);
      return;
    }

    try {
      final cart = await _firestoreService.getCart(_userId!);
      state = AsyncValue.data(cart);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Add item to cart
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
      final cartItem = CartItem(
        id: _uuid.v4(),
        productId: product.id,
        product: product,
        quantity: quantity,
        selectedColor: selectedColor,
        selectedSize: selectedSize,
        addedAt: DateTime.now(),
      );

      await _firestoreService.addToCart(_userId!, cartItem);
      await loadCart();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
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
      await loadCart();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Remove item from cart
  Future<void> removeFromCart(String itemId) async {
    if (_userId == null) return;

    try {
      await _firestoreService.removeFromCart(_userId!, itemId);
      await loadCart();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Clear entire cart
  Future<void> clearCart() async {
    if (_userId == null) return;

    try {
      await _firestoreService.clearCart(_userId!);
      await loadCart();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Get total items count
  int getTotalItemsCount() {
    return state.when(
      data: (cart) => cart?.totalItems ?? 0,
      loading: () => 0,
      error: (_, __) => 0,
    );
  }

  /// Get cart subtotal
  double getSubtotal() {
    return state.when(
      data: (cart) => cart?.totalPrice ?? 0.0,
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );
  }
}

/// Provider for cart item count
final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.when(
    data: (cart) => cart?.totalItems ?? 0,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for cart subtotal
final cartSubtotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.when(
    data: (cart) => cart?.totalPrice ?? 0.0,
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
}); 