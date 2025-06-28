import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product_model.dart';
import '../../constants/app_constants.dart';

/// Admin screen for managing product approvals
class AdminProductApprovalScreen extends ConsumerStatefulWidget {
  const AdminProductApprovalScreen({super.key});

  @override
  ConsumerState<AdminProductApprovalScreen> createState() => _AdminProductApprovalScreenState();
}

class _AdminProductApprovalScreenState extends ConsumerState<AdminProductApprovalScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ProductModel> _pendingProducts = [];
  List<ProductModel> _approvedProducts = [];
  bool _isLoading = true;
  String _selectedTab = 'pending';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    
    try {
      // Load pending products
      final pendingQuery = await _firestore
          .collection(AppConstants.productsCollection)
          .where('isApproved', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      // Load approved products
      final approvedQuery = await _firestore
          .collection(AppConstants.productsCollection)
          .where('isApproved', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      setState(() {
        _pendingProducts = pendingQuery.docs
            .map((doc) => ProductModel.fromJson(doc.data()))
            .toList();
        _approvedProducts = approvedQuery.docs
            .map((doc) => ProductModel.fromJson(doc.data()))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load products: $e');
    }
  }

  Future<void> _approveProduct(String productId) async {
    try {
      await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .update({
        'isApproved': true,
        'isActive': true,
        'updatedAt': Timestamp.now(),
      });

      _showSuccessSnackBar('Product approved successfully!');
      _loadProducts(); // Refresh list
    } catch (e) {
      _showErrorSnackBar('Failed to approve product: $e');
    }
  }

  Future<void> _rejectProduct(String productId) async {
    try {
      await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .update({
        'isApproved': false,
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });

      _showSuccessSnackBar('Product rejected');
      _loadProducts(); // Refresh list
    } catch (e) {
      _showErrorSnackBar('Failed to reject product: $e');
    }
  }

  Future<void> _bulkApproveAll() async {
    try {
      final batch = _firestore.batch();
      
      for (final product in _pendingProducts) {
        final docRef = _firestore
            .collection(AppConstants.productsCollection)
            .doc(product.id);
        
        batch.update(docRef, {
          'isApproved': true,
          'isActive': true,
          'updatedAt': Timestamp.now(),
        });
      }

      await batch.commit();
      _showSuccessSnackBar('All products approved!');
      _loadProducts();
    } catch (e) {
      _showErrorSnackBar('Failed to bulk approve: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Approval Center'),
        backgroundColor: const Color(0xFF232F3E),
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          if (_pendingProducts.isNotEmpty && _selectedTab == 'pending')
            TextButton.icon(
              onPressed: _bulkApproveAll,
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text(
                'Approve All',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          IconButton(
            onPressed: _loadProducts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    'pending',
                    'Pending Approval (${_pendingProducts.length})',
                    Icons.pending_actions,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    'approved',
                    'Approved (${_approvedProducts.length})',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab, String title, IconData icon, Color color) {
    final isSelected = _selectedTab == tab;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? color : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final products = _selectedTab == 'pending' ? _pendingProducts : _approvedProducts;

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedTab == 'pending' ? Icons.inbox : Icons.check_circle_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _selectedTab == 'pending' 
                  ? 'No products pending approval'
                  : 'No approved products yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Header
            Row(
              children: [
                // Product Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: product.imageUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
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
                const SizedBox(width: 16),
                
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.category, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            product.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.store, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              product.vendorName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Product Description
            Text(
              product.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 16),

            // Action Buttons
            if (_selectedTab == 'pending')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveProduct(product.id),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectProduct(product.id),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),

            if (_selectedTab == 'approved')
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Approved',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _rejectProduct(product.id),
                    icon: const Icon(Icons.remove_circle_outline),
                    label: const Text('Revoke'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
} 