import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../constants/app_constants.dart';
import '../../models/order_model.dart';

/// Provider for fetching user orders
final userOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final user = ref.watch(userProvider).asData?.value;
  if (user == null) return [];
  
  return FirestoreService().getUserOrders(user.id);
});

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(userOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 100,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  Text(
                    'No orders found',
                    style: TextStyle(
                      fontSize: AppDimensions.fontTitle,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingSmall),
                  Text(
                    'Start shopping to see your orders here',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingLarge),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                    child: const Text('Start Shopping'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildOrderCard(context, order);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: AppDimensions.paddingMedium),
                const Text(
                  'Unable to Load Orders',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingSmall),
                Text(
                  'There was an issue loading your orders. This might be due to database configuration.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingMedium),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.red),
                      const SizedBox(height: 8),
                      Text(
                        'Technical Details:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        error.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingLarge),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => ref.refresh(userOrdersProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Go Back'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        fontSize: AppDimensions.fontMedium,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingSmall),
                    Text(
                      DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: AppDimensions.fontSmall,
                      ),
                    ),
                  ],
                ),
                _buildStatusChip(order.status),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMedium),

            // Order Items Preview (show first 2 items)
            ...order.items.take(2).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    ),
                    child: item.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                            child: Image.network(
                              item.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image, size: 20),
                            ),
                          )
                        : const Icon(Icons.image, size: 20),
                  ),
                  const SizedBox(width: AppDimensions.paddingMedium),
                  Expanded(
                    child: Text(
                      item.productName,
                      style: const TextStyle(fontSize: AppDimensions.fontSmall),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'Qty: ${item.quantity}',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSmall,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )).toList(),

            // Show more items indicator
            if (order.items.length > 2)
              Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
                child: Text(
                  '+ ${order.items.length - 2} more items',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: AppDimensions.fontSmall,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            const Divider(),

            // Order Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total: ${AppConstants.currencySymbol}${order.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: AppDimensions.fontMedium,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingSmall),
                    Text(
                      'Payment: ${_getPaymentMethodText(order.paymentMethod)}',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSmall,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    OutlinedButton(
                      onPressed: () => _showOrderDetails(context, order),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                      child: const Text('View Details'),
                    ),
                    if (order.status == OrderStatus.pending)
                      TextButton(
                        onPressed: () => _showCancelOrderDialog(context, order),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Cancel Order'),
                      ),
                  ],
                ),
              ],
            ),

            // Delivery Progress
            if (order.status != OrderStatus.cancelled && order.status != OrderStatus.pending)
              Column(
                children: [
                  const SizedBox(height: AppDimensions.paddingMedium),
                  _buildDeliveryProgress(order.status),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case OrderStatus.pending:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        text = 'Pending';
        break;
      case OrderStatus.confirmed:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        text = 'Confirmed';
        break;
      case OrderStatus.processing:
        backgroundColor = Colors.indigo[100]!;
        textColor = Colors.indigo[800]!;
        text = 'Processing';
        break;
      case OrderStatus.shipped:
        backgroundColor = Colors.purple[100]!;
        textColor = Colors.purple[800]!;
        text = 'Shipped';
        break;
      case OrderStatus.outForDelivery:
        backgroundColor = Colors.teal[100]!;
        textColor = Colors.teal[800]!;
        text = 'Out for Delivery';
        break;
      case OrderStatus.delivered:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        text = 'Delivered';
        break;
      case OrderStatus.cancelled:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        text = 'Cancelled';
        break;
      case OrderStatus.refunded:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        text = 'Refunded';
        break;
      case OrderStatus.returned:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
        text = 'Returned';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: AppDimensions.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: AppDimensions.fontSmall,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDeliveryProgress(OrderStatus status) {
    final steps = [
      {'title': 'Confirmed', 'status': OrderStatus.confirmed},
      {'title': 'Shipped', 'status': OrderStatus.shipped},
      {'title': 'Delivered', 'status': OrderStatus.delivered},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Progress',
          style: TextStyle(
            fontSize: AppDimensions.fontSmall,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        Row(
          children: steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isCompleted = status.index >= (step['status'] as OrderStatus).index;
            final isActive = status == step['status'];

            return Expanded(
              child: Row(
                children: [
                  // Circle
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? (isActive ? AppColors.primary : Colors.green)
                          : Colors.grey[300],
                    ),
                    child: isCompleted
                        ? Icon(
                            isActive ? Icons.radio_button_checked : Icons.check,
                            size: 12,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  
                  // Line (except for last item)
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isCompleted ? Colors.green : Colors.grey[300],
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        Row(
          children: steps.map((step) {
            return Expanded(
              child: Text(
                step['title'] as String,
                style: TextStyle(
                  fontSize: AppDimensions.fontSmall - 2,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getPaymentMethodText(String paymentMethod) {
    switch (paymentMethod) {
      case 'COD':
        return 'Cash on Delivery';
      case 'RAZORPAY':
        return 'Razorpay';
      case 'STRIPE':
        return 'Stripe';
      default:
        return paymentMethod;
    }
  }

  void _showOrderDetails(BuildContext context, OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppDimensions.radiusLarge),
              topRight: Radius.circular(AppDimensions.radiusLarge),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: AppDimensions.paddingMedium),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order Details',
                      style: const TextStyle(
                        fontSize: AppDimensions.fontTitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              const Divider(),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Info
                      _buildDetailSection(
                        'Order Information',
                        [
                          'Order ID: #${order.id.substring(0, 8).toUpperCase()}',
                          'Date: ${DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt)}',
                          'Status: ${order.status.toString().split('.').last.toUpperCase()}',
                          'Payment: ${_getPaymentMethodText(order.paymentMethod)}',
                        ],
                      ),
                      
                      // Items
                      _buildDetailSection(
                        'Items (${order.items.length})',
                        order.items.map((item) =>
                          '${item.productName} × ${item.quantity} - ${AppConstants.currencySymbol}${(item.price * item.quantity).toStringAsFixed(2)}'
                        ).toList(),
                      ),
                      
                      // Shipping Address
                      _buildDetailSection(
                        'Shipping Address',
                        [
                          order.shippingAddress.street,
                          '${order.shippingAddress.city}, ${order.shippingAddress.state}',
                          order.shippingAddress.zipCode,
                          'Phone: ${order.shippingAddress.phoneNumber}',
                        ],
                      ),
                      
                      // Payment Summary
                      _buildDetailSection(
                        'Payment Summary',
                        [
                          'Subtotal: ${AppConstants.currencySymbol}${order.subtotal.toStringAsFixed(2)}',
                          'Shipping: ${order.shipping > 0 ? '${AppConstants.currencySymbol}${order.shipping.toStringAsFixed(2)}' : 'FREE'}',
                          'Total: ${AppConstants.currencySymbol}${order.total.toStringAsFixed(2)}',
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: AppDimensions.fontMedium,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
          child: Text(
            item,
            style: TextStyle(
              color: Colors.grey[700],
            ),
          ),
        )).toList(),
        const SizedBox(height: AppDimensions.paddingMedium),
      ],
    );
  }

  void _showCancelOrderDialog(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelOrder(context, order);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _cancelOrder(BuildContext context, OrderModel order) async {
    try {
      await FirestoreService().updateOrderStatus(order.id, OrderStatus.cancelled);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
