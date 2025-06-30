import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_constants.dart';
import '../../widgets/common/loading_button.dart';
import '../../models/order_model.dart';
import '../../services/firestore_service.dart';
import '../../services/order_service.dart';
import '../../models/cart_model.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isPlacingOrder = false;
  bool _isSelectingAddress = false;
  String _selectedAddressId = 'address_1';
  
  // Razorpay integration
  Razorpay? _razorpay;
  final _firestoreService = FirestoreService();
  final _orderService = OrderService();
  
  final _formKey = GlobalKey<FormState>();

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

  /// Handle Razorpay payment success
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('🔥 Payment success: ${response.paymentId}');
    
    try {
      setState(() {
        _isPlacingOrder = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final cartState = ref.read(cartProvider);
      final cart = cartState.value;
      
      if (cart == null || cart.items.isEmpty) {
        throw Exception('Cart is empty');
      }

      // Create shipping address (using default for now)
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
      
      // Clear cart provider
      await ref.read(cartProvider.notifier).clearCart();

      // Navigate to order success screen
      if (mounted) {
        try {
          context.pushReplacement('/order-success');
        } catch (navigationError) {
          print('🔥 Navigation error: $navigationError');
          // Fallback: Go to orders page or home
          context.pushReplacement('/orders');
        }
      }
    } catch (e) {
      print('🔥 Error in payment success handler: $e');
      _showErrorSnackBar('Failed to create order: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  /// Handle Razorpay payment error
  void _handlePaymentError(PaymentFailureResponse response) {
    print('🔥 Payment error: ${response.code} - ${response.message}');
    setState(() {
      _isPlacingOrder = false;
    });
    _showErrorSnackBar('Payment failed: ${response.message ?? 'Unknown error'}');
  }

  /// Handle external wallet selection
  void _handleExternalWallet(ExternalWalletResponse response) {
    print('🔥 External wallet selected: ${response.walletName}');
    setState(() {
      _isPlacingOrder = false;
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

    // Save order to Firestore using the proper API
    final orderId = await _firestoreService.createOrder(order);
    if (orderId == null || orderId.isEmpty) {
      throw Exception('Order creation failed: orderId is null or empty');
    }
    // Return order with generated ID
    return order.copyWith(id: orderId);
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Calculate final total including tax and shipping
  double _calculateFinalTotal(CartModel cart) {
    final shippingCost = cart.totalPrice >= 100.0 ? 0.0 : 10.0;
    final tax = cart.totalPrice * 0.05; // 5% tax
    return cart.totalPrice + shippingCost + tax;
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
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Web Platform Testing',
                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Razorpay plugin only works on mobile platforms. On web, we simulate the payment process for testing.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildPaymentSummaryRow('Items:', '${cart.items.length}'),
              _buildPaymentSummaryRow('Subtotal:', '₹${cart.totalPrice.toStringAsFixed(2)}'),
              _buildPaymentSummaryRow('Shipping:', cart.totalPrice >= 100 ? 'Free' : '₹10.00'),
              _buildPaymentSummaryRow('Tax (5%):', '₹${(cart.totalPrice * 0.05).toStringAsFixed(2)}'),
              const Divider(height: 20),
              _buildPaymentSummaryRow(
                'Total Amount:', 
                '₹${_calculateFinalTotal(cart).toStringAsFixed(2)}',
                isTotal: true,
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
                _isPlacingOrder = false;
              });
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Simulate successful payment for testing
              final fakeResponse = PaymentSuccessResponse('web_test_payment_${DateTime.now().millisecondsSinceEpoch}', 'web_test_order_${DateTime.now().millisecondsSinceEpoch}', 'web_test_signature', null);
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

  Widget _buildPaymentSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: isTotal ? Colors.green[700] : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// Initiate Razorpay payment
  void _initiateRazorpayPayment(CartModel cart) {
    print('🔥 Place Order button pressed!'); // Debug log
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      print('🔥 Current user: ${user?.email}'); // Debug log
      
      if (user == null) {
        _showErrorSnackBar('Please login to continue');
        return;
      }

      if (cart.items.isEmpty) {
        _showErrorSnackBar('Your cart is empty');
        return;
      }

      setState(() {
        _isPlacingOrder = true;
      });

      final finalTotal = _calculateFinalTotal(cart);
      print('🔥 Final total: ₹$finalTotal'); // Debug log

      // Check if running on web platform
      if (kIsWeb) {
        print('🔥 Running on web - using test payment dialog');
        _showTestPaymentDialog(cart);
        return;
      }

      // Only use Razorpay on mobile platforms
      final options = {
        'key': 'rzp_test_UVwxEu8DrexcG2',
        'amount': (finalTotal * 100).toInt(), // Amount in paise
        'name': 'Amazon Clone',
        'description': 'Order payment for ${cart.items.length} items',
        'retry': {'enabled': true, 'max_count': 1},
        'send_sms_hash': true,
        'prefill': {
          'contact': '7618447467',
          'email': user.email ?? 'customer@example.com',
        },
        'external': {
          'wallets': ['paytm']
        }
      };

      print('🔥 Opening Razorpay with options: $options'); // Debug log
      
      try {
        _razorpay?.open(options);
        print('🔥 Razorpay.open() called successfully');
      } catch (razorpayError) {
        print('🔥 Razorpay.open() failed: $razorpayError');
        // Fallback: Show a test payment dialog for debugging
        _showTestPaymentDialog(cart);
      }
    } catch (e) {
      print('🔥 Error in _initiateRazorpayPayment: $e'); // Debug log
      setState(() {
        _isPlacingOrder = false;
      });
      _showErrorSnackBar('Failed to initiate payment: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _phoneController.dispose();
    
    // Only clear Razorpay if it was initialized (not on web)
    if (!kIsWeb && _razorpay != null) {
      try {
        _razorpay!.clear();
      } catch (e) {
        print('🔥 Error clearing Razorpay: $e');
      }
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: cartState.when(
        data: (cart) {
          if (cart == null || cart.items.isEmpty) {
            return _buildEmptyCart();
          }
          return _buildCheckoutContent(cart);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF131921),
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // Amazon logo
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Image.asset(
              'assets/images/amazon_logo.png',
              height: 25,
              errorBuilder: (context, error, stackTrace) => const Text(
                'amazon.in',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const Spacer(),
          // Secure checkout
          const Text(
            'Secure checkout',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white,
            size: 20,
          ),
          const Spacer(),
          // Cart icon
          Consumer(
            builder: (context, ref, child) {
              final cartItemCount = ref.watch(cartItemCountProvider);
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                    onPressed: () => context.pop(),
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
          const Text(
            'Cart',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey),
          const SizedBox(height: 20),
          const Text('Your cart is empty'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return const Center(child: Text('Error loading checkout'));
  }

  Widget _buildCheckoutContent(CartModel cart) {
    if (_isSelectingAddress) {
      return _buildAddressSelectionScreen(cart);
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main checkout content (left side)
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDeliverySection(),
                const SizedBox(height: 32),
                _buildPaymentSection(),
                const SizedBox(height: 32),
                _buildReviewSection(),
              ],
            ),
          ),
        ),
        // Right sidebar - Order summary
        Container(
          width: 320,
          height: MediaQuery.of(context).size.height - kToolbarHeight,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  left: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              child: _buildOrderSummary(cart),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliverySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Delivering to Aman Singh',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F1111),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isSelectingAddress = true;
                  });
                },
                child: const Text(
                  'Change',
                  style: TextStyle(
                    color: Color(0xFF007185),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Sewla Kalan Chandrabani Road, Parvati vihar, DEHRADUN, UTTARAKHAND, 248001, India',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF565959),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
            child: const Text(
              'Add delivery instructions',
              style: TextStyle(
                color: Color(0xFF007185),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F1111),
            ),
          ),
          const SizedBox(height: 24),
          _buildRazorpayPaymentMethod(),
        ],
      ),
    );
  }

  Widget _buildRazorpayPaymentMethod() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kIsWeb ? Colors.orange[600] : const Color(0xFF3395FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  kIsWeb ? Icons.web : Icons.payment,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kIsWeb ? 'Web Payment Simulation' : 'Pay securely with Razorpay',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F1111),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      kIsWeb 
                          ? 'Test payment flow for web platform development'
                          : 'Supports Credit/Debit Cards, Net Banking, UPI & Wallets',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF565959),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                kIsWeb ? Icons.info_outline : Icons.security, 
                size: 16, 
                color: kIsWeb ? Colors.orange[600] : const Color(0xFF007185)
              ),
              const SizedBox(width: 8),
              Text(
                kIsWeb 
                    ? 'Web testing mode - payment will be simulated'
                    : 'Secure payment powered by Razorpay',
                style: TextStyle(
                  fontSize: 12,
                  color: kIsWeb ? Colors.orange[600] : const Color(0xFF007185),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review items and shipping',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F1111),
            ),
          ),
          SizedBox(height: 16),
          // This would contain the order items review
          Text(
            'Order items will be displayed here...',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF565959),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CartModel cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Place Order Button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Material(
                  color: _isPlacingOrder ? Colors.grey.shade300 : const Color(0xFFFFD814),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: _isPlacingOrder ? null : () {
                      print('🔥 Button tapped!'); // Debug log
                      print('🔥 Cart items count: ${cart.items.length}');
                      print('🔥 Cart total: ₹${cart.totalPrice}');
                      
                      // Add small delay to ensure the tap is registered
                      Future.delayed(const Duration(milliseconds: 50), () {
                        _initiateRazorpayPayment(cart);
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: _isPlacingOrder
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Processing...',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Place Order',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Items:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₹${cart.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Delivery:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    cart.totalPrice >= 100 ? 'Free' : '₹10.00',
                    style: TextStyle(
                      fontSize: 14,
                      color: cart.totalPrice >= 100 ? const Color(0xFF007600) : const Color(0xFF0F1111),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Tax:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₹${(cart.totalPrice * 0.05).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Text(
                    'Promotion Applied:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                  Spacer(),
                  Text(
                    '--',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Order Total:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB12704),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₹${_calculateFinalTotal(cart).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB12704),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSelectionScreen(CartModel cart) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main address selection content (left side)
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  'Select a delivery address',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF0F1111),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Warning box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E6),
                    border: Border.all(color: const Color(0xFFFFCC80)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        color: Color(0xFFFF9900),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'One-time password required at time of delivery',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F1111),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text(
                                  'Please ensure someone will be available to receive this delivery. ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF0F1111),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {},
                                  child: const Text(
                                    'Learn more',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF007185),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Delivery addresses section
                const Text(
                  'Delivery addresses (1)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F1111),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Address list
                _buildAddressList(),
                
                const SizedBox(height: 24),
                
                // Add new address link
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Add a new delivery address',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF007185),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Deliver to multiple addresses
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Deliver to multiple addresses',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF007185),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Deliver to this address button
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isSelectingAddress = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD814),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Deliver to this address',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Gift card section
                _buildGiftCardSection(),
                
                const SizedBox(height: 32),
                
                // Review items section
                _buildReviewItemsSection(),
              ],
            ),
          ),
        ),
                 // Right sidebar - Order summary with deliver button
         Container(
           width: 320,
           height: MediaQuery.of(context).size.height - kToolbarHeight,
           child: SingleChildScrollView(
             padding: const EdgeInsets.all(24),
             child: Container(
               decoration: BoxDecoration(
                 color: Colors.grey[50],
                 border: Border(
                   left: BorderSide(color: Colors.grey[300]!, width: 1),
                 ),
               ),
               child: _buildAddressSelectionOrderSummary(cart),
             ),
           ),
         ),
      ],
    );
  }

  Widget _buildAddressList() {
    final addresses = [
      {
        'id': 'address_1',
        'name': 'Aman Singh',
        'address': 'Sewla Kalan Chandrabani Road, Parvati vihar, DEHRADUN, UTTARAKHAND, 248001, India',
        'phone': '7618447467',
      },
    ];

    return Column(
      children: addresses.map((address) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: _selectedAddressId == address['id'] 
                  ? const Color(0xFF007185) 
                  : Colors.grey[300]!,
              width: _selectedAddressId == address['id'] ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: RadioListTile<String>(
            value: address['id'] as String,
            groupValue: _selectedAddressId,
            onChanged: (value) {
              setState(() {
                _selectedAddressId = value!;
              });
            },
            activeColor: const Color(0xFF007185),
            contentPadding: const EdgeInsets.all(16),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address['name'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F1111),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address['address'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF565959),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Phone number: ${address['phone']}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF565959),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                                         GestureDetector(
                       onTap: () {
                         _showEditAddressDialog();
                       },
                       child: const Text(
                         'Edit address',
                         style: TextStyle(
                           fontSize: 14,
                           color: Color(0xFF007185),
                         ),
                       ),
                     ),
                    const Text(
                      ' | ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF565959),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: const Text(
                        'Add delivery instructions',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF007185),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGiftCardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Use a gift card, voucher or promo code',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF007185),
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: const Text(
                'Change',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF007185),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review items and shipping',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F1111),
          ),
        ),
        const SizedBox(height: 32),
        
        // Help section
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Need help? Check our ',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0F1111),
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'help pages',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF007185),
                    ),
                  ),
                ),
                const Text(
                  ' or ',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0F1111),
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'contact us 24x7',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF007185),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'When your order is placed, we\'ll send you an e-mail message acknowledging receipt of your order. If you choose to pay using an electronic payment method (credit card, debit card or net banking), you will be directed to your bank\'s website to complete your payment. Your contract to purchase an item will not be complete until we receive your electronic payment and dispatch your item. If you choose to pay using Pay on Delivery (POD), you can pay using cash/card/net banking when you receive your item.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF0F1111),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'See Amazon.in\'s ',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0F1111),
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Return Policy',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF007185),
                    ),
                  ),
                ),
                const Text(
                  '.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0F1111),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
                         GestureDetector(
               onTap: () => context.pop(),
               child: const Text(
                 'Back to cart',
                 style: TextStyle(
                   fontSize: 13,
                   color: Color(0xFF007185),
                 ),
               ),
             ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressSelectionOrderSummary(CartModel cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Deliver to this address button at top
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _isSelectingAddress = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD814),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Deliver to this address',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Order summary details
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text(
                    'Items:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                  Spacer(),
                  Text(
                    '--',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Text(
                    'Delivery:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                  Spacer(),
                  Text(
                    '--',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                  Spacer(),
                  Text(
                    '--',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Text(
                    'Promotion Applied:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                  Spacer(),
                  Text(
                    '--',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Order Total:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB12704),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₹${cart.totalPrice.toInt().toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]},',
                    )}.00',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB12704),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditAddressDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: Colors.white,
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                                         const Text(
                       'Edit your address',
                       style: TextStyle(
                         fontSize: 20,
                         fontWeight: FontWeight.w400,
                         color: Color(0xFF0F1111),
                       ),
                     ),
                                         IconButton(
                       onPressed: () => Navigator.of(context).pop(),
                       icon: const Icon(
                         Icons.close,
                         color: Color(0xFF565959),
                         size: 24,
                       ),
                       padding: EdgeInsets.zero,
                       constraints: const BoxConstraints(),
                       splashRadius: 20,
                     ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Autofill section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F3FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Save time. Autofill your current location.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0F1111),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                                             ElevatedButton(
                         onPressed: () {},
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.white,
                           foregroundColor: const Color(0xFF0F1111),
                           elevation: 0,
                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(4),
                             side: BorderSide(color: Colors.grey[300]!),
                           ),
                         ),
                         child: const Text(
                           'Autofill',
                           style: TextStyle(
                             fontSize: 13,
                             fontWeight: FontWeight.w500,
                           ),
                         ),
                       ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Form fields
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Country/Region
                        _buildFormField(
                          'Country/Region',
                          DropdownButtonFormField<String>(
                            value: 'India',
                            decoration: _getInputDecoration(),
                            style: const TextStyle(
                              color: Color(0xFF0F1111),
                              fontSize: 13,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'India', 
                                child: Text(
                                  'India',
                                  style: TextStyle(
                                    color: Color(0xFF0F1111),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) {},
                          ),
                        ),
                        
                        // Full name
                        _buildFormField(
                          'Full name (First and Last name)',
                          TextFormField(
                            initialValue: 'Aman Singh',
                            decoration: _getInputDecoration(),
                            style: _getInputTextStyle(),
                          ),
                        ),
                        
                        // Mobile number
                        _buildFormField(
                          'Mobile number',
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                initialValue: '7618447467',
                                decoration: _getInputDecoration(),
                                keyboardType: TextInputType.phone,
                                style: _getInputTextStyle(),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'May be used to assist delivery',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF565959),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Pincode
                        _buildFormField(
                          'Pincode',
                          TextFormField(
                            initialValue: '248001',
                            decoration: _getInputDecoration(),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        
                        // Flat, House no.
                        _buildFormField(
                          'Flat, House no., Building, Company, Apartment',
                          TextFormField(
                            initialValue: 'Sewla Kalan Chandrabani Road',
                            decoration: _getInputDecoration(),
                          ),
                        ),
                        
                        // Area, Street
                        _buildFormField(
                          'Area, Street, Sector, Village',
                          TextFormField(
                            initialValue: 'Parvati vihar',
                            decoration: _getInputDecoration(),
                          ),
                        ),
                        
                                                 // Landmark
                         _buildFormField(
                           'Landmark',
                           TextFormField(
                             decoration: _getInputDecoration().copyWith(
                               hintText: 'E.g. near apollo hospital',
                             ),
                           ),
                         ),
                        
                        // Town/City and State
                        Row(
                          children: [
                            Expanded(
                              child: _buildFormField(
                                'Town/City',
                                TextFormField(
                                  initialValue: 'DEHRADUN',
                                  decoration: _getInputDecoration(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildFormField(
                                'State',
                                DropdownButtonFormField<String>(
                                  value: 'UTTARAKHAND',
                                  decoration: _getInputDecoration(),
                                  style: const TextStyle(
                                    color: Color(0xFF0F1111),
                                    fontSize: 13,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'UTTARAKHAND', 
                                      child: Text(
                                        'UTTARAKHAND',
                                        style: TextStyle(
                                          color: Color(0xFF0F1111),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {},
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                                                 // Make default address checkbox
                         const SizedBox(height: 8),
                         Row(
                           children: [
                             Checkbox(
                               value: false,
                               onChanged: (value) {},
                               activeColor: const Color(0xFF007185),
                               materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                             ),
                             const SizedBox(width: 8),
                             const Expanded(
                               child: Text(
                                 'Make this my default address',
                                 style: TextStyle(
                                   fontSize: 13,
                                   color: Color(0xFF0F1111),
                                 ),
                               ),
                             ),
                           ],
                         ),
                        
                                                 // Delivery instructions
                         const SizedBox(height: 16),
                         Container(
                           decoration: BoxDecoration(
                             border: Border.all(color: Colors.grey[300]!),
                             borderRadius: BorderRadius.circular(4),
                           ),
                           child: ExpansionTile(
                             title: const Text(
                               'Delivery instructions (optional)',
                               style: TextStyle(
                                 fontSize: 13,
                                 fontWeight: FontWeight.w600,
                                 color: Color(0xFF0F1111),
                               ),
                             ),
                             subtitle: const Text(
                               'Add preferences, notes, access codes and more',
                               style: TextStyle(
                                 fontSize: 11,
                                 color: Color(0xFF565959),
                               ),
                             ),
                             iconColor: const Color(0xFF007185),
                             collapsedIconColor: const Color(0xFF007185),
                             children: [
                               Padding(
                                 padding: const EdgeInsets.all(16),
                                 child: TextFormField(
                                   decoration: _getInputDecoration().copyWith(
                                     hintText: 'Add delivery instructions',
                                   ),
                                   maxLines: 3,
                                 ),
                               ),
                             ],
                           ),
                         ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Use this address button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD814),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Use this address',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F1111),
          ),
        ),
        const SizedBox(height: 8),
        field,
        const SizedBox(height: 16),
      ],
    );
  }

  InputDecoration _getInputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFF007185), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      hintStyle: TextStyle(
        color: Colors.grey[500],
        fontSize: 13,
      ),
    );
  }

  TextStyle _getInputTextStyle() {
    return const TextStyle(
      color: Color(0xFF0F1111),
      fontSize: 13,
    );
  }
}

