import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  Widget build(BuildContext context) {
    // ... existing code ...
  }

  @override
  void dispose() {
    super.dispose();
    // ... existing code ...
  }

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
} 