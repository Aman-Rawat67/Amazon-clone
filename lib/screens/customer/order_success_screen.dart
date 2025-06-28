import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/order_model.dart';

/// Screen to show order success confirmation
class OrderSuccessScreen extends StatelessWidget {
  final OrderModel order;

  const OrderSuccessScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF131921),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Order Placed',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildSuccessHeader(),
              const SizedBox(height: 30),
              _buildOrderDetails(),
              const SizedBox(height: 30),
              _buildExpectedDelivery(),
              const SizedBox(height: 30),
              _buildActionButtons(context),
              const SizedBox(height: 20),
              _buildAdditionalInfo(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build success header with checkmark and message
  Widget _buildSuccessHeader() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.green.shade200, width: 2),
          ),
          child: Icon(
            Icons.check_circle,
            size: 60,
            color: Colors.green.shade600,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Order Placed Successfully!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F1111),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Thank you for your order. We\'ll send you a confirmation email shortly.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build order details section
  Widget _buildOrderDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F1111),
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Order ID', order.orderNumber),
          _buildDetailRow('Items', '${order.totalItems} item${order.totalItems > 1 ? 's' : ''}'),
          _buildDetailRow('Total Amount', '₹${order.totalAmount.toStringAsFixed(2)}'),
          _buildDetailRow('Payment Method', order.paymentMethod),
          _buildDetailRow('Status', _getStatusDisplayText(order.status)),
        ],
      ),
    );
  }

  /// Build individual detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF0F1111),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build expected delivery section
  Widget _buildExpectedDelivery() {
    final deliveryDate = DateTime.now().add(const Duration(days: 4));
    final formattedDate = _formatDate(deliveryDate);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF007185).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF007185).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.local_shipping,
                color: const Color(0xFF007185),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Expected Delivery',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007185),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formattedDate,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F1111),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'We\'ll notify you when your order is on its way',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build action buttons section
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.push('/orders'),
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
              'Track Your Orders',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.go('/home'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade400),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Continue Shopping',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F1111),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build additional information section
  Widget _buildAdditionalInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'What happens next?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoPoint('📧', 'You\'ll receive an order confirmation email'),
          _buildInfoPoint('📦', 'We\'ll prepare your order for shipment'),
          _buildInfoPoint('🚚', 'You\'ll get tracking info when it ships'),
          _buildInfoPoint('📱', 'Track your order anytime in the Orders section'),
        ],
      ),
    );
  }

  /// Build individual info point
  Widget _buildInfoPoint(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get status display text
  String _getStatusDisplayText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Order Pending';
      case OrderStatus.confirmed:
        return 'Order Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.refunded:
        return 'Refunded';
      case OrderStatus.returned:
        return 'Returned';
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    final day = date.day;
    final month = months[date.month - 1];
    final year = date.year;
    
    // Add ordinal suffix
    String getDayWithSuffix(int day) {
      if (day >= 11 && day <= 13) return '${day}th';
      switch (day % 10) {
        case 1: return '${day}st';
        case 2: return '${day}nd';
        case 3: return '${day}rd';
        default: return '${day}th';
      }
    }
    
    return '${getDayWithSuffix(day)} $month, $year';
  }
} 