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
import '../../services/razorpay_web_service.dart';

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
  String _selectedAddressId = '';
  
  // Razorpay integration
  Razorpay? _razorpay;
  final _firestoreService = FirestoreService();
  final _orderService = OrderService();
  
  final _formKey = GlobalKey<FormState>();

  // Add RazorpayWebService
  final _razorpayWebService = RazorpayWebService();

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
    _initializeSelectedAddress();
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

  /// Initialize selected address ID based on user's default address
  void _initializeSelectedAddress() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(userProvider).value;
      if (user?.addresses.isNotEmpty == true) {
        try {
          // Find default address or use first address
          final defaultAddressString = user!.addresses.firstWhere(
            (addr) {
              final parts = addr.split('|');
              return parts.length > 8 && parts[8].toLowerCase() == 'true';
            },
            orElse: () => user.addresses.first,
          );
          
          final defaultAddress = ShippingAddress.fromString(defaultAddressString);
          if (mounted) {
            setState(() {
              _selectedAddressId = defaultAddress.id;
            });
          }
        } catch (e) {
          print('Error initializing selected address: $e');
        }
      }
    });
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

      // Get the selected shipping address
      final userData = ref.read(userProvider).value;
      if (userData == null || userData.addresses.isEmpty) {
        throw Exception('No shipping address available');
      }

      ShippingAddress? selectedAddress;
      if (_selectedAddressId.isNotEmpty) {
        try {
          final addressString = userData.addresses.firstWhere(
            (addr) => addr.startsWith('$_selectedAddressId|'),
          );
          selectedAddress = ShippingAddress.fromString(addressString);
        } catch (e) {
          print('Error finding selected address: $e');
        }
      }

      // Fallback to default address or first address if no selection
      if (selectedAddress == null) {
        try {
          final defaultAddressString = userData.addresses.firstWhere(
            (addr) {
              final parts = addr.split('|');
              return parts.length > 8 && parts[8].toLowerCase() == 'true';
            },
            orElse: () => userData.addresses.first,
          );
          selectedAddress = ShippingAddress.fromString(defaultAddressString);
        } catch (e) {
          throw Exception('Unable to find a valid shipping address');
        }
      }

      // Create order with selected address
      final order = await _createOrderWithRazorpayPayment(
        cart.items,
        selectedAddress,
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
          if (order.id.isEmpty) {
            throw Exception('Order ID is empty');
          }
          context.go('/home/order-success', extra: order);
        } catch (navigationError) {
          print('🔥 Navigation error: $navigationError');
          // Fallback: Go to orders page or home
          context.go('/home/orders');
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

  /// Handle payment initiation
  Future<void> _handlePayment() async {
    if (_isPlacingOrder) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackBar('Please login to continue');
        return;
      }

      final cartState = ref.read(cartProvider);
      final cart = cartState.value;
      
      if (cart == null || cart.items.isEmpty) {
        _showErrorSnackBar('Your cart is empty');
        return;
      }

      setState(() {
        _isPlacingOrder = true;
      });

      final finalTotal = _calculateFinalTotal(cart);

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
            _isPlacingOrder = false;
          });
        }
        return;
      }

      // Mobile platform - use Razorpay Flutter SDK
      if (_razorpay == null) {
        throw Exception('Razorpay not initialized');
      }

      final options = {
        'key': AppConstants.razorpayApiKey,
        'amount': (finalTotal * 100).toInt(),
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
      print('🔥 Error handling payment: $e');
      _showErrorSnackBar('Failed to process payment: ${e.toString()}');
      setState(() {
        _isPlacingOrder = false;
      });
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _phoneController.dispose();
    
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
    final cartState = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF131921),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Back button
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            // Title
            const Text(
              'Checkout',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: cartState.when(
        data: (cart) {
          if (cart == null || cart.items.isEmpty) {
            return const Center(
              child: Text('Your cart is empty'),
            );
          }
          return _isSelectingAddress
              ? _buildAddressSelectionScreen(cart)
              : _buildCheckoutContent(cart);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
      ),
    );
  }

  Widget _buildCheckoutContent(CartModel cart) {
    final userAsync = ref.watch(userProvider);
    
    return userAsync.when(
      data: (user) {
        ShippingAddress? defaultAddress;
        if (user?.addresses.isNotEmpty == true) {
          try {
            defaultAddress = ShippingAddress.fromString(
              user!.addresses.firstWhere(
                (addr) {
                  final parts = addr.split('|');
                  return parts.length > 8 && parts[8].toLowerCase() == 'true';
                },
                orElse: () => user.addresses.first,
              ),
            );
          } catch (e) {
            print('Error parsing address: $e');
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Delivery address section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery Address',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F1111),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (defaultAddress != null) ...[
                      // Address details
                      Text(
                        defaultAddress.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0F1111),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        defaultAddress.address,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF565959),
                        ),
                      ),
                      Text(
                        '${defaultAddress.city}, ${defaultAddress.state}, ${defaultAddress.zipCode}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF565959),
                        ),
                      ),
                      Text(
                        defaultAddress.country,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF565959),
                        ),
                      ),
                      Text(
                        'Phone: ${defaultAddress.phone}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF565959),
                        ),
                      ),
                      if (defaultAddress.deliveryInstructions?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Instructions: ${defaultAddress.deliveryInstructions}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF565959),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ] else ...[
                      const Text(
                        'No address selected',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF565959),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    // Edit button
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSelectingAddress = true;
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: const Color(0xFF007185),
                      ),
                      child: Text(defaultAddress != null ? 'Change address' : 'Select address'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Payment method section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F1111),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRazorpayPaymentMethod(),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Order summary section
              _buildOrderSummary(cart),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading user data: $error'),
      ),
    );
  }

  Widget _buildRazorpayPaymentMethod() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Payment method selection
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/images/razorpay_logo.png',
                height: 24,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.payment,
                  size: 24,
                  color: Color(0xFF0F1111),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Pay with Razorpay',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F1111),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.check_circle,
                color: Color(0xFF007600),
                size: 20,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Payment button
        SizedBox(
          width: double.infinity,
          child: LoadingButton(
            isLoading: _isPlacingOrder,
            onPressed: () => _handlePayment(),
            text: 'Place your order',
            backgroundColor: const Color(0xFFFFD814),
            foregroundColor: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary(CartModel cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F1111),
            ),
          ),
          const SizedBox(height: 16),
          // Items
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
          // Delivery
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
                cart.totalPrice >= 100.0 ? 'FREE' : '₹10.00',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF0F1111),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Tax
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
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          // Total
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
    );
  }

  Widget _buildAddressSelectionScreen(CartModel cart) {
    final userAsync = ref.watch(userProvider);
    
    return userAsync.when(
      data: (user) {
        if (user == null || user.addresses.isEmpty) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select a delivery address',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F1111),
                  ),
                ),
                const SizedBox(height: 24),
                
                // No addresses found
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.location_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No addresses found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add your first address to continue',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _showEditAddressDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Address'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD814),
                            foregroundColor: Colors.black,
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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Select a delivery address',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F1111),
                ),
              ),
              const SizedBox(height: 24),

              // Address list
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User addresses
                    ...user.addresses.asMap().entries.map((entry) {
                      try {
                        final address = ShippingAddress.fromString(entry.value);
                        return Column(
                          children: [
                            RadioListTile<String>(
                              value: address.id,
                              groupValue: _selectedAddressId,
                              onChanged: (value) {
                                setState(() {
                                  _selectedAddressId = value!;
                                });
                              },
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      address.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF0F1111),
                                      ),
                                    ),
                                  ),
                                  if (address.isDefault)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Default',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green.shade800,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    address.formattedAddress,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF565959),
                                    ),
                                  ),
                                  Text(
                                    'Phone: ${address.phone}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF565959),
                                    ),
                                  ),
                                  if (address.deliveryInstructions?.isNotEmpty == true)
                                    Text(
                                      'Instructions: ${address.deliveryInstructions}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF565959),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (entry.key < user.addresses.length - 1) const Divider(),
                          ],
                        );
                      } catch (e) {
                        // Skip invalid address strings
                        return const SizedBox.shrink();
                      }
                    }).toList(),
                    
                    const Divider(),
                    // Add new address button
                    TextButton.icon(
                      onPressed: _showEditAddressDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add a new address'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF007185),
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Order summary
              _buildAddressSelectionOrderSummary(cart),

              const SizedBox(height: 24),

              // Use this address button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedAddressId.isNotEmpty ? () {
                    setState(() {
                      _isSelectingAddress = false;
                    });
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD814),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Use this address',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading addresses: $error'),
      ),
    );
  }

  Widget _buildAddressSelectionOrderSummary(CartModel cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F1111),
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
                cart.totalPrice >= 100.0 ? 'FREE' : '₹10.00',
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
    );
  }

  /// Show edit address dialog
  void _showEditAddressDialog() {
    // Navigate to addresses screen
    context.push('/addresses').then((_) {
      // Refresh address selection when returning
      _initializeSelectedAddress();
    });
  }
}
