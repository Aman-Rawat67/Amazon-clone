import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../constants/app_constants.dart';
import '../../models/product_model.dart';
import '../../services/firestore_service.dart';

/// Provider for vendor products
final vendorProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final user = ref.watch(userProvider).asData?.value;
  if (user == null) return [];
  
  return FirestoreService().getVendorProducts(user.id);
});

class VendorProductsScreen extends ConsumerWidget {
  const VendorProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(vendorProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Products'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/vendor/add-product'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(vendorProductsProvider);
        },
        child: productsAsync.when(
          data: (products) => _buildProductsList(context, ref, products),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorWidget(context, ref, error),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/vendor/add-product'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProductsList(BuildContext context, WidgetRef ref, List<ProductModel> products) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(
              'No products yet',
              style: TextStyle(
                fontSize: AppDimensions.fontLarge,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              'Start by adding your first product',
              style: TextStyle(
                fontSize: AppDimensions.fontMedium,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            ElevatedButton.icon(
              onPressed: () => context.go('/vendor/add-product'),
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(context, ref, product);
      },
    );
  }

  Widget _buildProductCard(BuildContext context, WidgetRef ref, ProductModel product) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      child: InkWell(
        onTap: () => _showProductDetails(context, product),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Row(
            children: [
              // Product Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  color: Colors.grey[200],
                ),
                child: product.imageUrls.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        child: Image.network(
                          product.imageUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[400],
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[400],
                      ),
              ),
              const SizedBox(width: AppDimensions.paddingMedium),
              
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontMedium,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimensions.paddingSmall),
                    Text(
                      '${AppConstants.currencySymbol}${product.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: AppDimensions.fontLarge,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingSmall),
                    Row(
                      children: [
                        Icon(
                          Icons.inventory,
                          size: 16,
                          color: product.isInStock ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Stock: ${product.stockQuantity}',
                          style: TextStyle(
                            fontSize: AppDimensions.fontSmall,
                            color: product.isInStock ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.paddingMedium),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: product.isApproved 
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            product.isApproved ? 'Approved' : 'Pending',
                            style: TextStyle(
                              fontSize: AppDimensions.fontSmall,
                              color: product.isApproved ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action Menu
              PopupMenuButton<String>(
                onSelected: (value) => _handleProductAction(context, ref, product, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: product.isActive ? 'deactivate' : 'activate',
                    child: Row(
                      children: [
                        Icon(
                          product.isActive ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(product.isActive ? 'Deactivate' : 'Activate'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: const Icon(Icons.more_vert),
              ),
            ],
          ),
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
          const Text('Error loading products'),
          const SizedBox(height: AppDimensions.paddingSmall),
          Text(
            error.toString(),
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          ElevatedButton(
            onPressed: () => ref.refresh(vendorProductsProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showProductDetails(BuildContext context, ProductModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
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
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        color: Colors.grey[200],
                      ),
                      child: product.imageUrls.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                              child: Image.network(
                                product.imageUrls.first,
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
                            product.name,
                            style: const TextStyle(
                              fontSize: AppDimensions.fontTitle,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${AppConstants.currencySymbol}${product.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: AppDimensions.fontLarge,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingLarge),
                
                // Details
                _buildDetailRow('Category', product.category),
                _buildDetailRow('Subcategory', product.subcategory),
                _buildDetailRow('Stock', '${product.stockQuantity} units'),
                _buildDetailRow('Status', product.isActive ? 'Active' : 'Inactive'),
                _buildDetailRow('Approval', product.isApproved ? 'Approved' : 'Pending'),
                _buildDetailRow('Rating', '${product.rating.toStringAsFixed(1)} ⭐ (${product.reviewCount} reviews)'),
                _buildDetailRow('Created', _formatDate(product.createdAt)),
                
                if (product.description.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.paddingMedium),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: AppDimensions.fontMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingSmall),
                  Text(product.description),
                ],
                
                const SizedBox(height: AppDimensions.paddingLarge),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Navigate to edit product
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Product'),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingMedium),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                      ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: AppDimensions.fontMedium,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: AppDimensions.fontMedium),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleProductAction(BuildContext context, WidgetRef ref, ProductModel product, String action) {
    switch (action) {
      case 'edit':
        // Navigate to edit product screen
        break;
      case 'activate':
      case 'deactivate':
        _toggleProductStatus(context, ref, product);
        break;
      case 'delete':
        _showDeleteConfirmation(context, ref, product);
        break;
    }
  }

  void _toggleProductStatus(BuildContext context, WidgetRef ref, ProductModel product) {
    final newStatus = !product.isActive;
    final statusText = newStatus ? 'activated' : 'deactivated';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${newStatus ? 'Activate' : 'Deactivate'} Product'),
        content: Text('Are you sure you want to $statusText "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirestoreService().updateProductStatus(product.id, newStatus);
                ref.refresh(vendorProductsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Product $statusText successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirestoreService().deleteProduct(product.id);
                ref.refresh(vendorProductsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 