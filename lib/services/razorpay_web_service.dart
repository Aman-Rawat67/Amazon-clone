import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

/// Service class for handling Razorpay payments on web platform
class RazorpayWebService {
  static final RazorpayWebService _instance = RazorpayWebService._internal();
  factory RazorpayWebService() => _instance;
  RazorpayWebService._internal();

  /// Initialize Razorpay payment on web
  Future<Map<String, dynamic>> initiatePayment({
    required double amount,
    required String description,
    required String userEmail,
    required String userPhone,
    String? userName,
    String? orderId,
  }) async {
    if (!kIsWeb) {
      throw Exception('RazorpayWebService can only be used on web platform');
    }

    final completer = Completer<Map<String, dynamic>>();

    try {
      // Create payment options
      final options = {
        'key': AppConstants.razorpayApiKey,
        'amount': (amount * 100).toInt(), // Convert to paise
        'currency': 'INR',
        'name': AppConstants.appName,
        'description': description,
        'image': 'icons/Icon-192.png',
        'prefill': {
          'name': userName ?? '',
          'email': userEmail,
          'contact': userPhone,
        },
        'order_id': orderId,
      };

      // Create success callback
      final onSuccess = js.allowInterop((response) {
        completer.complete({
          'success': true,
          'paymentId': response['razorpay_payment_id'],
          'orderId': response['razorpay_order_id'],
          'signature': response['razorpay_signature'],
        });
      });

      // Create error callback
      final onError = js.allowInterop((error) {
        completer.complete({
          'success': false,
          'code': error['code'],
          'message': error['message'],
        });
      });

      // Call JavaScript function to initialize payment
      js.context.callMethod(
        'initializeRazorpayPayment',
        [js.JsObject.jsify(options), onSuccess, onError],
      );
    } catch (e) {
      completer.complete({
        'success': false,
        'code': 'INITIALIZATION_ERROR',
        'message': e.toString(),
      });
    }

    return completer.future;
  }

  /// Cleanup Razorpay instance
  void cleanup() {
    if (kIsWeb) {
      js.context.callMethod('cleanupRazorpay');
    }
  }
} 