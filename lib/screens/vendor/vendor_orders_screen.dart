import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_constants.dart';
import '../../models/order_model.dart';
import '../../models/cart_model.dart';
import '../../services/firestore_service.dart';

/// Provider for vendor orders
final vendorOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final user = ref.watch(userProvider).asData?.value;
  if (user == null) return [];
  
  return FirestoreService().getVendorOrders(user.id);
});

class VendorOrdersScreen extends ConsumerWidget {
  const VendorOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(vendorOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(vendorOrdersProvider);
        },
        child: ordersAsync.when(
          data: (orders) => _buildOrdersList(context, ref, orders),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorWidget(context, ref, error),
        ),
      ),
    );
  }

  Widget _buildOrdersList(BuildContext context, WidgetRef ref, List<OrderModel> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(
              'No orders yet',
              style: TextStyle(
                fontSize: AppDimensions.fontLarge,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              'Orders for your products will appear here',
              style: TextStyle(
                fontSize: AppDimensions.fontMedium,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // Group orders by status
    final pendingOrders = orders.where((order) => 
        order.status == OrderStatus.pending || 
        order.status == OrderStatus.confirmed).toList();
    final processingOrders = orders.where((order) => 
        order.status == OrderStatus.processing || 
        order.status == OrderStatus.shipped).toList();
    final completedOrders = orders.where((order) => 
        order.status == OrderStatus.delivered).toList();

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      children: [
        if (pendingOrders.isNotEmpty) ...[
          _buildStatusSection('Pending Orders', pendingOrders, context, ref),
          const SizedBox(height: AppDimensions.paddingLarge),
        ],
        if (processingOrders.isNotEmpty) ...[
          _buildStatusSection('Processing Orders', processingOrders, context, ref),
          const SizedBox(height: AppDimensions.paddingLarge),
        ],
        if (completedOrders.isNotEmpty) ...[
          _buildStatusSection('Completed Orders', completedOrders, context, ref),
        ],
      ],
    );
  }

  Widget _buildStatusSection(String title, List<OrderModel> orders, BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: AppDimensions.fontLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        
        ...orders.map((order) => _buildOrderCard(context, ref, order)),
      ],
    );
  }

  Widget _buildOrderCard(BuildContext context, WidgetRef ref, OrderModel order) {
    // Get vendor items from the order
    final vendorItems = order.items.where((item) => 
        item.product.vendorId == ref.read(userProvider).asData?.value?.id).toList();
    
    if (vendorItems.isEmpty) return const SizedBox.shrink();

    final totalAmount = vendorItems.fold<double>(
      0, (sum, item) => sum + (item.product.price * item.quantity));

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      child: InkWell(
        onTap: () => _showOrderDetails(context, order, vendorItems),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.orderNumber}',
                          style: const TextStyle(
                            fontSize: AppDimensions.fontMedium,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.paddingSmall),
                        Text(
                          _formatDate(order.createdAt),
                          style: TextStyle(
                            fontSize: AppDimensions.fontSmall,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(order.status),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
              
              // Order Items Preview
              ...vendorItems.take(2).map((item) => _buildOrderItemPreview(item)),
              if (vendorItems.length > 2)
                Padding(
                  padding: const EdgeInsets.only(top: AppDimensions.paddingSmall),
                  child: Text(
                    'and ${vendorItems.length - 2} more items',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSmall,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              const SizedBox(height: AppDimensions.paddingMedium),
              
              // Order Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${AppConstants.currencySymbol}${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: AppDimensions.fontMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      if (order.status == OrderStatus.pending || 
                          order.status == OrderStatus.confirmed)
                        ElevatedButton(
                          onPressed: () => _updateOrderStatus(context, ref, order, OrderStatus.processing),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text('Process'),
                        ),
                      if (order.status == OrderStatus.processing)
                        ElevatedButton(
                          onPressed: () => _updateOrderStatus(context, ref, order, OrderStatus.shipped),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text('Ship'),
                        ),
                      if (order.status == OrderStatus.shipped)
                        ElevatedButton(
                          onPressed: () => _updateOrderStatus(context, ref, order, OrderStatus.delivered),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text('Deliver'),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItemPreview(CartItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              color: Colors.grey[200],
            ),
            child: item.product.imageUrls.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    child: Image.network(
                      item.product.imageUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.image_not_supported, color: Colors.grey[400]);
                      },
                    ),
                  )
                : Icon(Icons.image_not_supported, color: Colors.grey[400]),
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Qty: ${item.quantity} × ${AppConstants.currencySymbol}${item.product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSmall,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case OrderStatus.confirmed:
        color = Colors.blue;
        text = 'Confirmed';
        break;
      case OrderStatus.processing:
        color = Colors.purple;
        text = 'Processing';
        break;
      case OrderStatus.shipped:
        color = Colors.indigo;
        text = 'Shipped';
        break;
      case OrderStatus.outForDelivery:
        color = Colors.teal;
        text = 'Out for Delivery';
        break;
      case OrderStatus.delivered:
        color = Colors.green;
        text = 'Delivered';
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled';
        break;
      case OrderStatus.refunded:
        color = Colors.grey;
        text = 'Refunded';
        break;
      case OrderStatus.returned:
        color = Colors.brown;
        text = 'Returned';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: AppDimensions.fontSmall,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: AppDimensions.paddingMedium),
          const Text('Error loading orders'),
          const SizedBox(height: AppDimensions.paddingSmall),
          Text(
            error.toString(),
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          ElevatedButton(
            onPressed: () => ref.refresh(vendorOrdersProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context, OrderModel order, List<CartItem> vendorItems) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${order.orderNumber}',
                            style: const TextStyle(
                              fontSize: AppDimensions.fontTitle,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatDate(order.createdAt),
                            style: TextStyle(
                              fontSize: AppDimensions.fontMedium,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(order.status),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingLarge),
                
                // Customer Info
                const Text(
                  'Customer Information',
                  style: TextStyle(
                    fontSize: AppDimensions.fontLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingMedium),
                _buildInfoRow('Name', order.shippingAddress.name),
                _buildInfoRow('Phone', order.shippingAddress.phone),
                _buildInfoRow('Address', order.shippingAddress.formattedAddress),
                
                const SizedBox(height: AppDimensions.paddingLarge),
                
                // Order Items
                const Text(
                  'Your Products',
                  style: TextStyle(
                    fontSize: AppDimensions.fontLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingMedium),
                
                ...vendorItems.map((item) => _buildOrderItemDetail(item)),
                
                const SizedBox(height: AppDimensions.paddingLarge),
                
                // Order Summary
                const Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: AppDimensions.fontLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingMedium),
                
                Builder(
                  builder: (context) {
                    final totalAmount = vendorItems.fold<double>(
                      0, (sum, item) => sum + (item.product.price * item.quantity));
                    
                    return Column(
                      children: [
                        _buildSummaryRow('Subtotal', '${AppConstants.currencySymbol}${totalAmount.toStringAsFixed(2)}'),
                        _buildSummaryRow('Shipping', '${AppConstants.currencySymbol}${order.shippingCost.toStringAsFixed(2)}'),
                        _buildSummaryRow('Tax', '${AppConstants.currencySymbol}${order.tax.toStringAsFixed(2)}'),
                        const Divider(),
                        _buildSummaryRow(
                          'Total', 
                          '${AppConstants.currencySymbol}${totalAmount.toStringAsFixed(2)}',
                          isTotal: true,
                        ),
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: AppDimensions.paddingLarge),
                
                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItemDetail(CartItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                color: Colors.grey[200],
              ),
              child: item.product.imageUrls.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      child: Image.network(
                        item.product.imageUrls.first,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(Icons.image_not_supported, color: Colors.grey[400]),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppDimensions.paddingSmall),
                  Text(
                    'Quantity: ${item.quantity}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    'Price: ${AppConstants.currencySymbol}${item.product.price.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Text(
              '${AppConstants.currencySymbol}${(item.product.price * item.quantity).toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: AppDimensions.fontMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? AppDimensions.fontMedium : AppDimensions.fontSmall,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? AppDimensions.fontMedium : AppDimensions.fontSmall,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Orders'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Filter functionality will be implemented here'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(BuildContext context, WidgetRef ref, OrderModel order, OrderStatus newStatus) async {
    try {
      await FirestoreService().updateOrderStatus(order.id, newStatus);
      ref.refresh(vendorOrdersProvider);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to ${newStatus.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating order status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 