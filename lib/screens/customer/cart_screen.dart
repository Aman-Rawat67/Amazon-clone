import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/cart_model.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../services/order_service.dart';
import '../../widgets/common/order_confirmation_dialog.dart';
import '../../constants/app_constants.dart';
import '../../widgets/common/loading_button.dart';
import '../../services/razorpay_web_service.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _isUpdating = false;
  bool _isUpdatingQuantity = false;
  bool _isBuyingNow = false;
  
  // Razorpay integration
  Razorpay? _razorpay;
  final _orderService = OrderService();
  final _razorpayWebService = RazorpayWebService();

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
  }

  /// Initialize Razorpay instance
  void _initializeRazorpay() {
    try {
      if (kIsWeb) {
        print('🔥 Running on web - Razorpay initialization skipped');
        return;
      }
      
      _razorpay = Razorpay();
      _razorpay?.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay?.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay?.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
      print('🔥 Razorpay initialized successfully');
    } catch (e) {
      print('🔥 Error initializing Razorpay: $e');
    }
  }

  /// Navigate to order success or handle error
  void _navigateAfterOrder(OrderModel order) {
    if (!mounted) return;
    
    try {
      if (order.id.isEmpty) {
        throw Exception('Invalid order ID');
      }
      
      // Use pushReplacement to prevent going back to cart
      context.pushReplacement('/order-success', extra: order);
    } catch (e) {
      print('🔥 Navigation error: $e');
      _showErrorSnackBar('Error navigating to order success. Redirecting to orders page.');
      // Fallback navigation
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          context.go('/orders');
        }
      });
    }
  }

  /// Handle Razorpay payment success
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('🔥 Payment success: ${response.paymentId}');
    
    try {
      setState(() {
        _isBuyingNow = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final cartState = ref.read(cartProvider);
      if (cartState.hasError) {
        throw Exception('Error reading cart: ${cartState.error}');
      }
      
      final cart = cartState.value;
      if (cart == null || cart.items.isEmpty) {
        throw Exception('Cart is empty');
      }

      // Create shipping address
      final shippingAddress = _orderService.createDefaultAddress();

      // Create order with Razorpay payment details
      final order = await _createOrderWithRazorpayPayment(
        cart.items,
        shippingAddress,
        response.paymentId!,
        cart.totalPrice,
      );

      print('🔥 Order created successfully: ${order.id}');

      // Clear cart after successful order
      await _orderService.clearCartAfterOrder(user.uid);
      await ref.read(cartProvider.notifier).clearCart();

      // Navigate to success screen
      _navigateAfterOrder(order);
      
    } catch (e) {
      print('🔥 Error in payment success handler: $e');
      _showErrorSnackBar('Failed to process order: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isBuyingNow = false;
        });
      }
    }
  }

  /// Handle Razorpay payment error
  void _handlePaymentError(PaymentFailureResponse response) {
    print('🔥 Payment error: ${response.code} - ${response.message}');
    setState(() {
      _isBuyingNow = false;
    });
    _showErrorSnackBar('Payment failed: ${response.message ?? 'Unknown error'}');
  }

  /// Handle external wallet selection
  void _handleExternalWallet(ExternalWalletResponse response) {
    print('🔥 External wallet selected: ${response.walletName}');
    setState(() {
      _isBuyingNow = false;
    });
    _showErrorSnackBar('External wallet selected: ${response.walletName}');
  }

  /// Create order with Razorpay payment details
  Future<OrderModel> _createOrderWithRazorpayPayment(
    List<CartItem> cartItems,
    ShippingAddress deliveryAddress,
    String paymentId,
    double totalAmount,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User must be logged in');

    // Calculate totals
    final subtotal = cartItems.fold<double>(
      0.0, (sum, item) => sum + (item.product.price * item.quantity)
    );
    
    final shippingCost = subtotal >= 100.0 ? 0.0 : 10.0;
    final tax = subtotal * 0.05; // 5% tax
    final finalTotal = subtotal + shippingCost + tax;

    // Generate unique order ID and number
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final orderNumber = 'AMZ${timestamp}${user.uid.substring(0, 4).toUpperCase()}';

    // Create OrderModel with Razorpay payment details
    final order = OrderModel(
      id: '', // Will be set by FirestoreService
      userId: user.uid,
      orderNumber: orderNumber,
      items: cartItems,
      subtotal: subtotal,
      shippingCost: shippingCost,
      tax: tax,
      totalAmount: finalTotal,
      status: OrderStatus.confirmed,
      paymentStatus: PaymentStatus.paid,
      paymentMethod: 'razorpay',
      paymentId: paymentId,
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
    final orderId = await _orderService.createOrder(order);
    if (orderId == null || orderId.isEmpty) {
      throw Exception('Order creation failed: orderId is null or empty');
    }
    // Return order with generated ID
    return order.copyWith(id: orderId);
  }

  /// Show error snackbar with retry option if needed
  void _showErrorSnackBar(String message, {VoidCallback? onRetry}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        action: onRetry != null ? SnackBarAction(
          label: 'Retry',
          onPressed: onRetry,
        ) : null,
      ),
    );
  }

  /// Show test payment dialog (fallback for web platform)
  void _showTestPaymentDialog(CartModel cart) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.payment, color: Colors.blue[600], size: 28),
            const SizedBox(width: 12),
            const Text(
              'Web Payment Simulation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Container(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Items: ${cart.items.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total: ₹${cart.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB12704),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'On mobile devices, this would open the Razorpay payment gateway.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isBuyingNow = false;
              });
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Simulate successful payment for testing
              final fakeResponse = PaymentSuccessResponse(
                'web_test_payment_${DateTime.now().millisecondsSinceEpoch}',
                'web_test_order_${DateTime.now().millisecondsSinceEpoch}',
                'web_test_signature',
                null,
              );
              _handlePaymentSuccess(fakeResponse);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('✅ Simulate Payment Success'),
          ),
        ],
      ),
    );
  }

  /// Handle buy now action
  Future<void> _handleBuyNow(CartModel cart) async {
    if (_isBuyingNow) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackBar('Please login to continue');
        return;
      }

      if (cart.items.isEmpty) {
        _showErrorSnackBar('Your cart is empty');
        return;
      }

      setState(() {
        _isBuyingNow = true;
      });

      // Calculate final total
      final subtotal = cart.totalPrice;
      final shippingCost = subtotal >= 100.0 ? 0.0 : 10.0;
      final tax = subtotal * 0.05; // 5% tax
      final finalTotal = subtotal + shippingCost + tax;

      // Handle web platform
      if (kIsWeb) {
        final result = await _razorpayWebService.initiatePayment(
          amount: finalTotal,
          description: 'Payment for ${cart.items.length} items',
          userEmail: user.email ?? '',
          userPhone: '7618447467',
          userName: user.displayName,
        );

        if (result['success']) {
          // Create fake response for web
          final fakeResponse = PaymentSuccessResponse(
            result['paymentId'],
            result['orderId'],
            result['signature'],
            null,
          );
          _handlePaymentSuccess(fakeResponse);
        } else {
          _showErrorSnackBar('Payment failed: ${result['message']}');
          setState(() {
            _isBuyingNow = false;
          });
        }
        return;
      }

      // Mobile platform - use Razorpay Flutter SDK
      if (_razorpay == null) {
        throw Exception('Razorpay not initialized');
      }

      // Create Razorpay options
      final options = {
        'key': AppConstants.razorpayApiKey,
        'amount': (finalTotal * 100).toInt(), // Amount in paise
        'name': AppConstants.appName,
        'description': 'Payment for ${cart.items.length} items',
        'prefill': {
          'contact': '7618447467',
          'email': user.email ?? '',
        },
        'external': {
          'wallets': ['paytm']
        }
      };

      _razorpay?.open(options);
    } catch (e) {
      print('🔥 Error handling buy now: $e');
      _showErrorSnackBar('Failed to process payment: ${e.toString()}');
      setState(() {
        _isBuyingNow = false;
      });
    }
  }

  @override
  void dispose() {
    // Clear Razorpay instances
    if (!kIsWeb && _razorpay != null) {
      try {
        _razorpay!.clear();
      } catch (e) {
        print('🔥 Error clearing Razorpay: $e');
      }
    }
    if (kIsWeb) {
      _razorpayWebService.cleanup();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
    final authState = ref.watch(authStreamProvider);
    final isWeb = MediaQuery.of(context).size.width > 768;

    // Check authentication first
    return authState.when(
      data: (user) {
        if (user == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF7F7F7),
            appBar: _buildAppBar(),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_circle_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Please sign in to view your cart',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/auth/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9900),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF7F7F7),
          appBar: _buildAppBar(),
          body: cartAsync.when(
            data: (cart) {
              if (cart == null || cart.items.isEmpty) {
                return _buildEmptyCart();
              }
              
              if (isWeb) {
                return _buildWebLayout(cart);
              } else {
                return _buildMobileLayout(cart);
              }
            },
            loading: () => _buildLoadingState(),
            error: (error, stack) => _buildErrorState(error.toString()),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF9900)),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        appBar: _buildAppBar(),
        body: _buildErrorState(error.toString()),
      ),
    );
  }

  /// Build app bar with cart count
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF131921),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.go('/home'),
      ),
      title: const Text(
        'Shopping Cart',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      actions: [
        Consumer(
          builder: (context, ref, child) {
            final cartItemCount = ref.watch(cartItemCountProvider);
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart, color: Colors.white),
                  onPressed: () {},
                ),
                if (cartItemCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9900),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        cartItemCount.toString(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// Build loading state with shimmer effect
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFFF9900)),
          SizedBox(height: 16),
          Text(
            'Loading your cart...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF565959),
            ),
          ),
        ],
      ),
    );
  }

  /// Build error state with retry option
  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F1111),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Error: $errorMessage',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF565959),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Invalidate the provider to trigger a rebuild
                ref.invalidate(cartProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9900),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty cart state with call to action
  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 60,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Amazon Cart is empty',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F1111),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Browse our categories and discover\nour best deals!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF565959),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 280,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9900),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 1,
                ),
                child: const Text(
                  'Continue Shopping',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Shop today\'s deals',
                style: TextStyle(
                  color: Color(0xFF007185),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build web layout with sidebar
  Widget _buildWebLayout(CartModel cart) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cart items (left side)
        Expanded(
          flex: 3,
          child: _buildCartContent(cart),
        ),
        // Cart summary (right sidebar)
        Container(
          width: 320,
          padding: const EdgeInsets.all(16),
          child: _buildCartSummary(cart),
        ),
      ],
    );
  }

  /// Build mobile layout with summary at bottom
  Widget _buildMobileLayout(CartModel cart) {
    return Column(
      children: [
        // Cart items
        Expanded(
          child: _buildCartContent(cart),
        ),
        // Cart summary at bottom
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: _buildCartSummary(cart),
        ),
      ],
    );
  }

  /// Build main cart content with items list
  Widget _buildCartContent(CartModel cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Free delivery notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE7F7E7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 14, color: Color(0xFF0F1111)),
                      children: [
                        TextSpan(text: 'Your order qualifies for '),
                        TextSpan(
                          text: 'FREE Delivery',
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green),
                        ),
                        TextSpan(text: '. Details at checkout.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Cart header
          Text(
            'Shopping Cart (${cart.totalItems} items)',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F1111),
            ),
          ),
          const SizedBox(height: 16),
          
          // Cart items list
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cart items
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cart.items.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildCartItem(cart.items[index]);
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Recommendations section
                  _buildRecommendationsSection(),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual cart item card
  Widget _buildCartItem(CartItem item) {
    final cartNotifier = ref.read(cartProvider.notifier);
    
    return InkWell(
      onTap: () => context.go('/product/${item.productId}'),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.product.imageUrls.isNotEmpty 
                        ? item.product.imageUrls.first 
                        : 'https://via.placeholder.com/100',
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 40, color: Colors.grey),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 40, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      item.product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0F1111),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // In Stock Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'In stock',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Selected attributes
                    if (item.selectedColor != null)
                      Text(
                        'Color: ${item.selectedColor}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF565959),
                        ),
                      ),
                    if (item.selectedSize != null)
                      Text(
                        'Size: ${item.selectedSize}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF565959),
                        ),
                      ),
                    const SizedBox(height: 12),
                    
                    // Actions Row
                    Row(
                      children: [
                        // Quantity Selector
                        _buildQuantitySelector(item, cartNotifier),
                        const SizedBox(width: 16),
                        
                        // Remove Button
                        TextButton.icon(
                          onPressed: () => _showRemoveDialog(item, cartNotifier),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Remove'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFCC0C39),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Price Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (item.product.hasDiscount)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCC0C39),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${item.product.discountPercentage.toInt()}% off',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  
                  // Current Price
                  Text(
                    '₹${_formatPrice(item.product.price)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                  
                  // Original Price (if discounted)
                  if (item.product.hasDiscount)
                    Text(
                      'M.R.P: ₹${_formatPrice(item.product.originalPrice!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF565959),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  
                  const SizedBox(height: 8),
                  
                  // Item Total
                  Text(
                    'Total: ₹${_formatPrice(item.totalPrice)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build quantity selector with +/- buttons
  Widget _buildQuantitySelector(CartItem item, CartNotifier cartNotifier) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrease button
          InkWell(
            onTap: _isUpdating ? null : () => _updateQuantity(item, cartNotifier, item.quantity - 1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            ),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: Icon(
                Icons.remove,
                size: 18,
                color: _isUpdating ? Colors.grey : const Color(0xFF565959),
              ),
            ),
          ),
          
          // Quantity display
          Container(
            width: 48,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Text(
              '${item.quantity}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F1111),
              ),
            ),
          ),
          
          // Increase button
          InkWell(
            onTap: _isUpdating ? null : () => _updateQuantity(item, cartNotifier, item.quantity + 1),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: Icon(
                Icons.add,
                size: 18,
                color: _isUpdating ? Colors.grey : const Color(0xFF565959),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build cart summary with totals and checkout button
  Widget _buildCartSummary(CartModel cart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Order Summary Title
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F1111),
            ),
          ),
          const SizedBox(height: 16),
          
          // Items count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Items (${cart.totalItems}):', 
                style: const TextStyle(fontSize: 16, color: Color(0xFF565959)),
              ),
              Text(
                '₹${_formatPrice(cart.subtotal)}',
                style: const TextStyle(fontSize: 16, color: Color(0xFF0F1111)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Shipping
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Shipping:', 
                style: TextStyle(fontSize: 16, color: Color(0xFF565959)),
              ),
              Text(
                cart.shipping == 0 ? 'FREE' : '₹${_formatPrice(cart.shipping)}',
                style: TextStyle(
                  fontSize: 16, 
                  color: cart.shipping == 0 ? Colors.green : const Color(0xFF0F1111),
                  fontWeight: cart.shipping == 0 ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Divider
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 16),
          
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F1111),
                ),
              ),
              Text(
                '₹${_formatPrice(cart.total)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F1111),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Buy Now Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handleBuyNow(cart),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9900),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Buy Now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Proceed to Checkout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/checkout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9900),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Proceed to Checkout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF007185),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Continue Shopping Link
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Continue Shopping',
                style: TextStyle(
                  color: Color(0xFF007185),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Update item quantity with loading state
  Future<void> _updateQuantity(CartItem item, CartNotifier cartNotifier, int newQuantity) async {
    if (newQuantity < 1) {
      _showRemoveDialog(item, cartNotifier);
      return;
    }

    setState(() => _isUpdating = true);
    
    try {
      await cartNotifier.updateQuantity(item.id, newQuantity);
      
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated quantity to $newQuantity'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Show error feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update quantity: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  /// Show remove item confirmation dialog
  void _showRemoveDialog(CartItem item, CartNotifier cartNotifier) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Item'),
          content: Text('Are you sure you want to remove "${item.product.name}" from your cart?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _removeItem(item, cartNotifier);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCC0C39),
                foregroundColor: Colors.white,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  /// Remove item from cart with feedback
  Future<void> _removeItem(CartItem item, CartNotifier cartNotifier) async {
    try {
      await cartNotifier.removeFromCart(item.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed "${item.product.name}" from cart'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () {
                // Add back to cart
                cartNotifier.addToCart(
                  product: item.product,
                  quantity: item.quantity,
                  selectedColor: item.selectedColor,
                  selectedSize: item.selectedSize,
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove item: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Build recommendations section
  Widget _buildRecommendationsSection() {
    return Consumer(
      builder: (context, ref, child) {
        final recommendationsAsync = ref.watch(cartRecommendationsProvider);
        
        return recommendationsAsync.when(
          data: (recommendations) {
            if (recommendations.isEmpty) {
              return const SizedBox.shrink();
            }
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header
                const Text(
                  'You might also like',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F1111),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Recommendations grid/list
                SizedBox(
                  height: 280,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: recommendations.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return _buildRecommendationCard(recommendations[index]);
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => _buildRecommendationsLoading(),
          error: (error, stack) => _buildRecommendationsError(),
        );
      },
    );
  }

  /// Build individual recommendation card
  Widget _buildRecommendationCard(ProductModel product) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            width: double.infinity,
            height: 140,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              child: Image.network(
                product.imageUrls.isNotEmpty 
                    ? product.imageUrls.first 
                    : 'https://via.placeholder.com/180x140',
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFFF9900),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, size: 40, color: Colors.grey),
                ),
              ),
            ),
          ),
          
          // Product Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0F1111),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  
                  // Rating
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < product.rating.floor()
                                ? Icons.star
                                : Icons.star_border,
                            size: 14,
                            color: const Color(0xFFFF9900),
                          );
                        }),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${product.reviewCount}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF007185),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Price and discount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.hasDiscount)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFCC0C39),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                '${product.discountPercentage.toInt()}% off',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${_formatPrice(product.price)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F1111),
                        ),
                      ),
                      if (product.hasDiscount)
                        Text(
                          'M.R.P: ₹${_formatPrice(product.originalPrice!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF565959),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Add to Cart button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _addRecommendationToCart(product),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9900),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 1,
                      ),
                      child: const Text(
                        'Add to cart',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build recommendations loading state
  Widget _buildRecommendationsLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'You might also like',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F1111),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return Container(
                width: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF9900),
                    strokeWidth: 2,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build recommendations error state
  Widget _buildRecommendationsError() {
    return const SizedBox.shrink(); // Fail silently for recommendations
  }

  /// Add recommendation to cart
  Future<void> _addRecommendationToCart(ProductModel product) async {
    try {
      final cartNotifier = ref.read(cartProvider.notifier);
      await cartNotifier.addToCart(
        product: product,
        quantity: 1,
        selectedColor: null,
        selectedSize: null,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${product.name}" to cart'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'View Cart',
              textColor: Colors.white,
              onPressed: () {
                // Already in cart screen, just scroll to top
                // Could implement scroll to top functionality here
              },
            ),
          ),
        );
        
        // Refresh recommendations after adding item
        ref.invalidate(cartRecommendationsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add item: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Format price with proper comma separation
  String _formatPrice(double price) {
    return price.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
