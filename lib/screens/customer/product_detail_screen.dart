import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../models/product_model.dart';
import '../../models/cart_model.dart';
import '../../models/order_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/order_service.dart';
import '../../services/emi_service.dart';
import '../../widgets/common/order_confirmation_dialog.dart';
import '../../widgets/common/optimized_action_button.dart';
import '../../widgets/common/quantity_selector.dart';
import '../../widgets/common/product_delivery_features.dart';
import '../../widgets/common/product_offers_section.dart';
import '../../constants/app_constants.dart';
import '../../services/razorpay_web_service.dart';

/// Complete product detail screen with Firebase Firestore integration
/// Styled like Amazon's product page with dynamic data fetching
class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;
  String? _selectedColor;
  String? _selectedSize;
  bool _isAddingToCart = false;
  bool _isBuyingNow = false;
  ProductModel? _cachedProduct;
  late Future<ProductModel?> _productFuture;

  // Razorpay integration
  Razorpay? _razorpay;
  final _orderService = OrderService();

  // Add RazorpayWebService
  final _razorpayWebService = RazorpayWebService();

  @override
  void initState() {
    super.initState();
    _productFuture = _firestoreService.getProduct(widget.productId);
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
        _isBuyingNow = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get current quantity
      final quantity = QuantitySelector.globalQuantity;

      // Create cart item for this product
      final cartItem = CartItem(
        id: '${widget.productId}_${_selectedColor ?? 'default'}_${null}',
        productId: widget.productId,
        product: _cachedProduct!,
        quantity: quantity,
        selectedColor: _selectedColor,
        selectedSize: null,
        addedAt: DateTime.now(),
      );

      // Create shipping address
      final shippingAddress = _orderService.createDefaultAddress();

      // Create order with Razorpay payment details
      final order = await _createOrderWithRazorpayPayment(
        [cartItem],
        shippingAddress,
        response.paymentId!,
        _cachedProduct!.price * quantity,
      );

      print('🔥 Order created successfully: ${order.id}');

      // Navigate to order success screen
      if (mounted) {
        try {
          if (order.id.isEmpty) {
            throw Exception('Order ID is empty');
          }
          context.goNamed('order_success', extra: order);
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
    _showErrorSnackBar(
      'Payment failed: ${response.message ?? 'Unknown error'}',
    );
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
      0.0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );

    final shippingCost = subtotal >= 100.0 ? 0.0 : 10.0;
    final tax = subtotal * 0.05; // 5% tax
    final finalTotal = subtotal + shippingCost + tax;

    // Generate unique order ID and number
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final orderNumber =
        'AMZ${timestamp}${user.uid.substring(0, 4).toUpperCase()}';

    // Create OrderModel with Razorpay payment details
    final order = OrderModel(
      id: '',
      // Will be set by FirestoreService
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

  /// Show test payment dialog (fallback for web platform)
  void _showTestPaymentDialog(CartItem cartItem) {
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
                      'Product: ${cartItem.product.name}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Quantity: ${cartItem.quantity}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total: ₹${(cartItem.product.price * cartItem.quantity).toStringAsFixed(2)}',
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('✅ Simulate Payment Success'),
          ),
        ],
      ),
    );
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
    _imagePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: BackButton(onPressed: () => context.go('/home')),
        title: const Text('Product Details'),
      ),
      body: FutureBuilder<ProductModel?>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return _buildNotFoundState();
          }

          final product = snapshot.data!;
          _cachedProduct = product;
          _initializeSelectedColor(product);

          return _buildProductContent(product);
        },
      ),
    );
  }

  /// Initialize selected color with first available color or null
  void _initializeSelectedColor(ProductModel product) {
    if (_selectedColor == null && product.colors.isNotEmpty) {
      _selectedColor = product.colors.first;
    }
  }

  /// Build app bar with Amazon-style design
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF131921),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Container(
        height: 40,
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search Amazon.in',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            suffixIcon: Container(
              width: 45,
              decoration: const BoxDecoration(
                color: Color(0xFFFF9900),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: const Icon(Icons.search, color: Colors.black),
            ),
          ),
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
                  onPressed: () => context.push('/home/cart'),
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
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildBreadcrumbShimmer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image section shimmer
                Expanded(flex: 2, child: _buildImageShimmer()),
                const SizedBox(width: 16),
                // Product details shimmer
                Expanded(flex: 3, child: _buildProductDetailsShimmer()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build shimmer for breadcrumb
  Widget _buildBreadcrumbShimmer() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 12,
          width: double.infinity,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Build shimmer for image section
  Widget _buildImageShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Container(
            height: 400,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              5,
              (index) => Container(
                width: 60,
                height: 60,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build shimmer for product details section
  Widget _buildProductDetailsShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 20, width: double.infinity, color: Colors.white),
          const SizedBox(height: 8),
          Container(height: 20, width: 200, color: Colors.white),
          const SizedBox(height: 16),
          Container(height: 16, width: 150, color: Colors.white),
          const SizedBox(height: 8),
          Container(height: 24, width: 100, color: Colors.white),
          const SizedBox(height: 16),
          Container(height: 16, width: double.infinity, color: Colors.white),
          const SizedBox(height: 8),
          Container(height: 16, width: 250, color: Colors.white),
          const SizedBox(height: 24),
          Container(height: 40, width: 150, color: Colors.white),
          const SizedBox(height: 12),
          Container(height: 40, width: 150, color: Colors.white),
        ],
      ),
    );
  }

  /// Build error state with retry option
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Failed to load product details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() {}), // Triggers rebuild and refetch
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9900),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build not found state
  Widget _buildNotFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Product not found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'The product you\'re looking for doesn\'t exist or has been removed.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9900),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build complete product content with optimized layout
  Widget _buildProductContent(ProductModel product) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800;
    final horizontalPadding = isWideScreen ? 24.0 : 16.0;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBreadcrumb(product),

          // Main content with adaptive padding
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 12,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (isWideScreen) {
                  // Desktop/tablet layout
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: constraints.maxWidth * 0.05,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildImageSection(product)),
                        SizedBox(width: horizontalPadding),
                        Expanded(flex: 4, child: _buildProductDetails(product)),
                        SizedBox(width: horizontalPadding),
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product price
                                Text(
                                  '₹860',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    // FREE Delivery text here something will open when we click
                                    Text(
                                      "FREE delivery",
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      ' Thursday, 3 July.',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text('Order within'),
                                    Text(
                                      '7 hrs 1 min. ',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    // This will be link
                                    Text(
                                      "Details",

                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Icon(
                                      CupertinoIcons.location_solid,
                                      color: Colors.grey,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    // This is where we have to deliver the product
                                    Text(
                                      'User Address',
                                      style: TextStyle(
                                        color: Colors.blueAccent,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                const Text(
                                  "In stock",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Ships from ",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.black54,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          "Sold by",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.black54,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          "Payment",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.black54,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 20),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Amazon",
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          "Sold by name",
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          "Secure transaction",
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),
                                Container(
                                  height: 33,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.black12.withAlpha(10),
                                    borderRadius: BorderRadius.circular(7),
                                    border: Border.all(
                                      color: Colors.grey.shade400,

                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 0,
                                      ),
                                      value: 1,
                                      icon: const Icon(Icons.arrow_drop_down),
                                      items:
                                          List.generate(
                                                10,
                                                (index) => index + 1,
                                              )
                                              .map(
                                                (qty) => DropdownMenuItem(
                                                  value: qty,
                                                  child: Text(
                                                    "Quantity: $qty",
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                      onChanged: (value) {
                                        // handle value change
                                      },
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.yellow[700],
                                      foregroundColor: Colors.black,
                                    ),
                                    onPressed: () {},
                                    child: const Text("Add to Cart"),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange[700],
                                      foregroundColor: Colors.black,
                                    ),
                                    onPressed: () {},
                                    child: const Text("Buy Now"),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Checkbox(value: false, onChanged: (_) {}),
                                    const Text("Add gift options"),
                                  ],
                                ),
                                const Divider(),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    style: ButtonStyle(),
                                    onPressed: () {},
                                    child: const Text("Add to Wish List"),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Mobile layout
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImageSection(product),
                      const SizedBox(height: 16),
                      _buildProductDetails(product),
                    ],
                  );
                }
              },
            ),
          ),

          // Divider before action buttons
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: const Divider(color: Colors.grey, height: 1),
          ),
          const SizedBox(height: 12),

          // Action buttons
          _buildActionButtons(product),

          // Bottom padding for better scrolling experience
          SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
        ],
      ),
    );
  }

  /// Build breadcrumb navigation
  Widget _buildBreadcrumb(ProductModel product) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
      child: Text(
        '${product.category} › ${product.subcategory}',
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF007185),
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  /// Show full-screen image viewer
  void _showFullScreenImage(
    BuildContext context,
    int initialIndex,
    List<String> imageUrls,
  ) {
    final images = imageUrls.isNotEmpty
        ? imageUrls
        : ['https://via.placeholder.com/400x400.png?text=No+Image'];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: const Color(0xFFF6F6F6),
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 5.0,
                      child: Center(
                        child: CachedNetworkImage(
                          imageUrl: images[index],
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(
                              color: Colors.orange,
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.error,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.black87,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build optimized image section with carousel and zoom
  Widget _buildImageSection(ProductModel product) {
    final images = product.imageUrls.isNotEmpty
        ? product.imageUrls
        : ['https://via.placeholder.com/400x400.png?text=No+Image'];

    return Column(
      children: [
        Card(
          elevation: 12,
          shadowColor: Colors.black.withOpacity(0.12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.grey[50]!, Colors.white, Colors.grey[50]!],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Enhanced Image carousel with zoom
                Container(
                  height: MediaQuery.of(context).size.width > 600 ? 480 : 380,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _imagePageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: GestureDetector(
                              onTap: () =>
                                  _showFullScreenImage(context, index, images),
                              child: InteractiveViewer(
                                panEnabled: true,
                                boundaryMargin: const EdgeInsets.all(20),
                                minScale: 0.8,
                                maxScale: 4.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Container(color: Colors.grey[50]),
                                        CachedNetworkImage(
                                          imageUrl: images[index],
                                          fit: BoxFit.contain,
                                          placeholder: (context, url) =>
                                              Shimmer.fromColors(
                                            baseColor: Colors.grey[300]!,
                                            highlightColor: Colors.grey[100]!,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: const Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.broken_image_outlined,
                                                  size: 48,
                                                  color: Colors.grey,
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'Image unavailable',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Enhanced Zoom & Fullscreen indicator
                      Positioned(
                        top: 28,
                        right: 28,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.fullscreen,
                                color: Colors.black87,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Tap to expand',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Enhanced Image indicators and thumbnails
                if (images.length > 1) ...[
                  const SizedBox(height: 20),

                  // Enhanced Dot indicators with animation
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: images.asMap().entries.map((entry) {
                        final isActive = _currentImageIndex == entry.key;
                        return GestureDetector(
                          onTap: () {
                            _imagePageController.animateToPage(
                              entry.key,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            width: isActive ? 32 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: isActive
                                  ? const Color(0xFFFF9900)
                                  : Colors.grey[300],
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFFF9900,
                                        ).withOpacity(0.4),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Enhanced Thumbnail strip with better styling
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: images.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final isSelected = _currentImageIndex == index;
                        return GestureDetector(
                          onTap: () {
                            _imagePageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            width: isSelected ? 72 : 64,
                            height: isSelected ? 72 : 64,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFFF9900)
                                    : Colors.grey[300]!,
                                width: isSelected ? 3 : 1.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFFF9900,
                                        ).withOpacity(0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: images[index],
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        Shimmer.fromColors(
                                          baseColor: Colors.grey[300]!,
                                          highlightColor: Colors.grey[100]!,
                                          child: Container(
                                            color: Colors.white,
                                            child: const Icon(
                                              Icons.image_outlined,
                                              color: Colors.grey,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey[100],
                                      child: const Icon(
                                        Icons.broken_image_outlined,
                                        size: 24,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  if (!isSelected)
                                    Container(color: Colors.black.withOpacity(0.1)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildRecommendedProducts(product),
      ],
    );
  }

  /// Build recommended products section
  Widget _buildRecommendedProducts(ProductModel product) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You may also like',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<ProductModel>>(
            future: _getRecommendedProducts(product),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildRecommendedProductsLoading();
              }

              if (snapshot.hasError) {
                return _buildRecommendedProductsError();
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildRecommendedProductsEmpty();
              }

              return _buildRecommendedProductsList(snapshot.data!);
            },
          ),
        ],
      ),
    );
  }

  /// Fetch recommended products from Firestore
  Future<List<ProductModel>> _getRecommendedProducts(
    ProductModel product,
  ) async {
    try {
      // Fetch products from the same category, excluding current product
      final products = await _firestoreService.getProducts(
        category: product.category,
        limit: 6,
      );

      // Remove current product from recommendations
      return products.where((p) => p.id != product.id).take(5).toList();
    } catch (e) {
      print('Error fetching recommended products: $e');
      return [];
    }
  }

  /// Build loading state for recommended products
  Widget _buildRecommendedProductsLoading() {
    return SizedBox(
      height: 280,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build error state for recommended products
  Widget _buildRecommendedProductsError() {
    return Container(
      height: 100,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.grey[400], size: 32),
          const SizedBox(height: 8),
          Text(
            'Failed to load recommendations',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// Build empty state for recommended products
  Widget _buildRecommendedProductsEmpty() {
    return Container(
      height: 100,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, color: Colors.grey[400], size: 32),
          const SizedBox(height: 8),
          Text(
            'No recommendations available',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// Build recommended products list
  Widget _buildRecommendedProductsList(List<ProductModel> products) {
    return SizedBox(
      height: 280,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildRecommendedProductCard(product);
        },
      ),
    );
  }

  /// Build individual recommended product card
  Widget _buildRecommendedProductCard(ProductModel product) {
    return GestureDetector(
      onTap: () {
        // Navigate to product detail screen
        context.push('/product/${product.id}');
      },
      child: Container(
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
            // Product image
            Container(
              height: 140,
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                child: CachedNetworkImage(
                  imageUrl: product.imageUrls.isNotEmpty
                      ? product.imageUrls.first
                      : 'https://via.placeholder.com/200x200.png?text=No+Image',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[100],
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 32,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),

            // Product details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF007185),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Rating
                    if (product.rating > 0) ...[
                      Row(
                        children: [
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < product.rating.floor()
                                    ? Icons.star
                                    : index < product.rating
                                    ? Icons.star_half
                                    : Icons.star_border,
                                color: const Color(0xFFFF9900),
                                size: 12,
                              );
                            }),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${product.reviewCount})',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF007185),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Price
                    Row(
                      children: [
                        Text(
                          '₹${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB12704),
                          ),
                        ),
                        if (product.originalPrice != null &&
                            product.hasDiscount) ...[
                          const SizedBox(width: 6),
                          Text(
                            '₹${product.originalPrice!.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Discount
                    if (product.hasDiscount) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${product.discountPercentage.toStringAsFixed(0)}% off',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build product details section with card-based design
  Widget _buildProductDetails(ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Product Info Card
        Card(
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product title
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Brand name if available
                if (product.brand != null) ...[
                  Text(
                    'Brand: ${product.brand}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF007185),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Rating and reviews
                _buildRatingSection(product),
                const SizedBox(height: 20),

                // Pricing section
                _buildPricingSection(product),
                const SizedBox(height: 20),

                // Delivery information
                _buildDeliveryInfo(product),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Options Card (Color, Size, Quantity)
        Card(
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Product Options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Color selection
                if (product.colors.isNotEmpty) ...[
                  _buildColorSelection(product),
                  const SizedBox(height: 16),
                ],

                // Size selection
                if (product.sizes.isNotEmpty) ...[
                  _buildSizeSelection(product),
                  const SizedBox(height: 16),
                ],

                // Quantity selection
                _buildQuantitySelection(),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Delivery Features and Offers
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Offers Section
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: ProductOffersSection(productPrice: product.price),
              ),
              
              // Divider between sections
              Divider(color: Colors.grey[200], height: 1),
              
              // Delivery Features
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: ProductDeliveryFeatures(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Product Description Card
        Card(
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildProductDescription(product),
          ),
        ),

        const SizedBox(height: 16),

        // Seller & Return Policy Card
        Card(
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSellerInfo(product),
                const SizedBox(height: 20),
                _buildReturnPolicy(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build rating section with stars
  Widget _buildRatingSection(ProductModel product) {
    return Row(
      children: [
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < product.rating.floor()
                  ? Icons.star
                  : index < product.rating
                  ? Icons.star_half
                  : Icons.star_border,
              color: const Color(0xFFFF9900),
              size: 20,
            );
          }),
        ),
        const SizedBox(width: 8),
        Text(
          product.rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF007185),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '(${product.reviewCount} reviews)',
          style: const TextStyle(fontSize: 14, color: Color(0xFF007185)),
        ),
      ],
    );
  }

  /// Build pricing section with discount
  Widget _buildPricingSection(ProductModel product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '₹${product.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                if (product.originalPrice != null && product.hasDiscount) ...[
                  const TextSpan(text: '  ', style: TextStyle(fontSize: 16)),
                  TextSpan(
                    text: '₹${product.originalPrice!.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (product.hasDiscount) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${product.discountPercentage.toStringAsFixed(0)}% OFF',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                'Inclusive of all taxes',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build delivery information
  Widget _buildDeliveryInfo(ProductModel product) {
    final shippingInfo = product.shippingInfo;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping, color: Color(0xFF007185), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (shippingInfo?['freeDelivery'] == true)
                  const Text(
                    'FREE Delivery',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                if (shippingInfo?['deliveryTime'] != null)
                  Text(
                    shippingInfo!['deliveryTime'],
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                if (shippingInfo?['location'] != null)
                  Text(
                    'Delivering to ${shippingInfo!['location']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build modern color selection with pill buttons
  Widget _buildColorSelection(ProductModel product) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Color: ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                _selectedColor ?? 'Select a color',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _selectedColor != null
                      ? const Color(0xFFFF9900)
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: product.colors.map((color) {
              final isSelected = _selectedColor == color;
              // Try to convert color name to actual color for display
              Color? displayColor = _getColorFromName(color);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFF9900).withOpacity(0.1)
                        : Colors.white,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFF9900)
                          : Colors.grey.shade300,
                      width: isSelected ? 2.5 : 1.5,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? const Color(0xFFFF9900).withOpacity(0.2)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: isSelected ? 8 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (displayColor != null) ...[
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: displayColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        color,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFFFF9900)
                              : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.check,
                          size: 16,
                          color: Color(0xFFFF9900),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Helper method to get color from color name
  Color? _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'grey' || 'gray':
        return Colors.grey;
      case 'brown':
        return Colors.brown;
      case 'cyan':
        return Colors.cyan;
      case 'indigo':
        return Colors.indigo;
      case 'lime':
        return Colors.lime;
      case 'teal':
        return Colors.teal;
      default:
        return null;
    }
  }

  /// Build modern size selection with pill buttons
  Widget _buildSizeSelection(ProductModel product) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Size: ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                _selectedSize ?? 'Select a size',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _selectedSize != null
                      ? const Color(0xFFFF9900)
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: product.sizes.map((size) {
              final isSelected = _selectedSize == size;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSize = size;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFF9900).withOpacity(0.1)
                        : Colors.white,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFF9900)
                          : Colors.grey.shade300,
                      width: isSelected ? 2.5 : 1.5,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? const Color(0xFFFF9900).withOpacity(0.2)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: isSelected ? 8 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        size,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFFFF9900)
                              : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.check,
                          size: 16,
                          color: Color(0xFFFF9900),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Build quantity selection
  Widget _buildQuantitySelection() {
    return QuantitySelector(
      onQuantityChanged: (quantity) {
        // Quantity changes are handled internally by QuantitySelector
        // This callback could be used for other purposes if needed
      },
    );
  }

  /// Build product description section
  Widget _buildProductDescription(ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About this item',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          product.description.isNotEmpty
              ? product.description
              : 'No description available for this product.',
          style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
        ),
        const SizedBox(height: 16),

        // Specifications
        if (product.specifications.isNotEmpty) ...[
          const Text(
            'Specifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: product.specifications.entries.map((entry) {
                final isLast = entry == product.specifications.entries.last;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          '${entry.key}:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  /// Build seller information
  Widget _buildSellerInfo(ProductModel product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.store, color: Color(0xFF007185), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sold by',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  product.vendorName.isNotEmpty
                      ? product.vendorName
                      : 'Unknown Seller',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007185),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build return policy section
  Widget _buildReturnPolicy() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[100]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '30-day return policy\nReturns are easy. Just contact us for a returns and refund process.',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  /// Build optimized action buttons with icons
  Widget _buildActionButtons(ProductModel product) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isWideScreen ? 24 : 16),
        child: Column(
          children: [
            // Stock status
            if (!product.isInStock) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning, color: Colors.red[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Out of Stock',
                      style: TextStyle(
                        color: Colors.red[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action buttons
            Row(
              children: [
                // Add to Cart button
                Expanded(
                  child: OptimizedActionButton(
                    onPressed: _isAddingToCart || !product.isInStock
                        ? null
                        : () => _handleAddToCart(product),
                    isLoading: _isAddingToCart,
                    style: OptimizedButtonStyle.outlined,
                    icon: Icons.shopping_cart_outlined,
                    text: 'Add to Cart',
                  ),
                ),
                const SizedBox(width: 16),
                // Buy Now button
                Expanded(
                  child: OptimizedActionButton(
                    onPressed: _isBuyingNow || !product.isInStock
                        ? null
                        : () => _handleBuyNow(product),
                    isLoading: _isBuyingNow,
                    style: OptimizedButtonStyle.filled,
                    icon: Icons.flash_on,
                    text: 'Buy Now',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Handle adding product to cart
  Future<void> _handleAddToCart(ProductModel product) async {
    if (_isAddingToCart) return;

    setState(() {
      _isAddingToCart = true;
    });

    try {
      final cartNotifier = ref.read(cartProvider.notifier);
      // Get quantity from the global QuantitySelector state
      final quantity = QuantitySelector.globalQuantity;

      await cartNotifier.addToCart(
        product: product,
        quantity: quantity,
        selectedColor: _selectedColor,
        selectedSize: _selectedSize,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Added $quantity item${quantity > 1 ? 's' : ''} to cart',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'View Cart',
              textColor: Colors.white,
              onPressed: () => context.go('/cart'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to add to cart: ${e.toString()}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  /// Handle buy now action
  Future<void> _handleBuyNow(ProductModel product) async {
    if (_isBuyingNow) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackBar('Please login to continue');
        return;
      }

      setState(() {
        _isBuyingNow = true;
      });

      // Get current quantity
      final quantity = QuantitySelector.globalQuantity;

      // Create cart item for this product
      final cartItem = CartItem(
        id: '${product.id}_${_selectedColor ?? 'default'}_${null}',
        productId: product.id,
        product: product,
        quantity: quantity,
        selectedColor: _selectedColor,
        selectedSize: null,
        addedAt: DateTime.now(),
      );

      // Calculate final total
      final subtotal = product.price * quantity;
      final shippingCost = subtotal >= 100.0 ? 0.0 : 10.0;
      final tax = subtotal * 0.05; // 5% tax
      final finalTotal = subtotal + shippingCost + tax;

      // Handle web platform
      if (kIsWeb) {
        final result = await _razorpayWebService.initiatePayment(
          amount: finalTotal,
          description: 'Payment for ${product.name}',
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
        'description': 'Payment for ${product.name}',
        'prefill': {'contact': '7618447467', 'email': user.email ?? ''},
        'external': {
          'wallets': ['paytm'],
        },
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
}
