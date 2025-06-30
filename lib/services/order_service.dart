import '../models/order_model.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service class for handling order operations and Buy Now functionality
class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create order from single product (Buy Now from Product Detail)
  Future<OrderModel> createOrderFromProduct({
    required ProductModel product,
    required int quantity,
    String? selectedColor,
    String? selectedSize,
    required ShippingAddress deliveryAddress,
    String paymentMode = 'Cash on Delivery',
  }) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('User must be logged in');

    // Create cart item for this product
    final cartItem = CartItem(
      id: '${product.id}_${selectedColor ?? 'default'}_${selectedSize ?? 'default'}',
      productId: product.id,
      product: product,
      quantity: quantity,
      selectedColor: selectedColor,
      selectedSize: selectedSize,
      addedAt: DateTime.now(),
    );

    return _createOrder(
      userId: user.uid,
      items: [cartItem],
      deliveryAddress: deliveryAddress,
      paymentMode: paymentMode,
    );
  }

  /// Create order from cart items (Buy Now from Cart)
  Future<OrderModel> createOrderFromCart({
    required List<CartItem> cartItems,
    required ShippingAddress deliveryAddress,
    String paymentMode = 'Cash on Delivery',
  }) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('User must be logged in');

    if (cartItems.isEmpty) {
      throw Exception('No items to order');
    }

    return _createOrder(
      userId: user.uid,
      items: cartItems,
      deliveryAddress: deliveryAddress,
      paymentMode: paymentMode,
    );
  }

  /// Internal method to create order
  Future<OrderModel> _createOrder({
    required String userId,
    required List<CartItem> items,
    required ShippingAddress deliveryAddress,
    required String paymentMode,
  }) async {
    // Calculate totals
    final subtotal = items.fold<double>(
      0.0, (sum, item) => sum + (item.product.price * item.quantity)
    );
    
    final shippingCost = subtotal >= 100.0 ? 0.0 : 10.0;
    final tax = subtotal * 0.05; // 5% tax
    final totalAmount = subtotal + shippingCost + tax;

    // Generate unique order ID and number
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final orderNumber = 'AMZ${timestamp}${userId.substring(0, 4).toUpperCase()}';

    // Create order model
    final order = OrderModel(
      id: '', // Will be set by Firestore
      userId: userId,
      orderNumber: orderNumber,
      items: items,
      subtotal: subtotal,
      shippingCost: shippingCost,
      tax: tax,
      totalAmount: totalAmount,
      status: OrderStatus.pending,
      paymentStatus: PaymentStatus.pending,
      paymentMethod: paymentMode,
      shippingAddress: deliveryAddress,
      tracking: [
        OrderTracking(
          status: 'Order Placed',
          description: 'Your order has been placed successfully',
          timestamp: DateTime.now(),
        ),
      ],
      createdAt: DateTime.now(),
    );

    // Save order to Firestore
    final orderId = await _firestoreService.createOrder(order);
    
    // Return order with ID
    return order.copyWith(id: orderId);
  }

  /// Clear cart after successful order placement
  Future<void> clearCartAfterOrder(String userId) async {
    try {
      await _firestoreService.clearCart(userId);
    } catch (e) {
      // Don't throw error for cart clearing - order was already successful
      print('Warning: Failed to clear cart after order: $e');
    }
  }

  /// Generate order confirmation message
  String generateOrderConfirmationMessage(OrderModel order) {
    final itemCount = order.items.fold(0, (sum, item) => sum + item.quantity);
    final itemText = itemCount == 1 ? 'item' : 'items';
    
    return 'Your order has been placed successfully!\n\n'
           'Order ID: ${order.orderNumber}\n'
           'Items: $itemCount $itemText\n'
           'Total: ₹${order.totalAmount.toStringAsFixed(2)}\n\n'
           'Expected delivery: ${_getExpectedDeliveryDate()}\n'
           'You will receive order updates via email and SMS.';
  }

  /// Get expected delivery date (3-5 business days)
  String _getExpectedDeliveryDate() {
    final deliveryDate = DateTime.now().add(const Duration(days: 4));
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${deliveryDate.day} ${months[deliveryDate.month - 1]}, ${deliveryDate.year}';
  }

  /// Create default shipping address for demo purposes
  ShippingAddress createDefaultAddress() {
    return const ShippingAddress(
      id: 'default_address',
      name: 'John Doe',
      phone: '+91 9876543210',
      address: '123 Main Street, Apartment 4B',
      city: 'Mumbai',
      state: 'Maharashtra',
      zipCode: '400001',
      country: 'India',
      isDefault: true,
    );
  }

  /// Validate order before placement
  bool validateOrder(List<CartItem> items, ShippingAddress address) {
    // Check if items are valid
    if (items.isEmpty) return false;
    
    // Check if all items have valid products
    for (final item in items) {
      if (item.quantity <= 0) return false;
      if (item.product.stockQuantity < item.quantity) return false;
    }
    
    // Check if address is valid
    if (address.name.isEmpty || 
        address.phone.isEmpty || 
        address.address.isEmpty ||
        address.city.isEmpty || 
        address.state.isEmpty ||
        address.zipCode.isEmpty) {
      return false;
    }
    
    return true;
  }

  /// Creates a new order in Firestore and returns the order ID
  Future<String> createOrder(OrderModel order) async {
    try {
      // Create a new document reference
      final orderRef = _firestore.collection('orders').doc();
      
      // Set the order ID
      final orderWithId = order.copyWith(id: orderRef.id);
      
      // Save the order to Firestore
      await orderRef.set(orderWithId.toJson());
      
      return orderRef.id;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }
} 