import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';  // Add this import for TimeoutException
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import '../../providers/product_provider.dart';
import '../../constants/filter_constants.dart';
import '../../widgets/home/horizontal_product_card.dart';
import '../../widgets/home/top_nav_bar.dart';
import '../../widgets/home/filter_bottom_sheet.dart';
import 'package:go_router/go_router.dart';

/// Screen that displays products for a specific category with filtering and sorting
class CategoryProductsScreen extends ConsumerStatefulWidget {
  final String category;
  final String? subcategory;

  const CategoryProductsScreen({
    super.key,
    required this.category,
    this.subcategory,
  });

  @override
  ConsumerState<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends ConsumerState<CategoryProductsScreen> {
  bool isLoading = true;
  String? error;
  List<ProductModel> products = [];
  
  late String decodedCategory;
  String? decodedSubcategory;

  @override
  void initState() {
    super.initState();
    // Schedule state updates for after the frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCategoryAndLoad();
    });
  }

  @override
  void didUpdateWidget(CategoryProductsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category || 
        oldWidget.subcategory != widget.subcategory) {
      // Schedule state updates for after the frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateCategoryAndLoad();
      });
    }
  }

  void _updateCategoryAndLoad() {
    if (!mounted) return;

    decodedCategory = Uri.decodeComponent(widget.category);
    decodedSubcategory = widget.subcategory != null 
        ? Uri.decodeComponent(widget.subcategory!)
        : null;

    // Update filters in provider
    Future.microtask(() {
      if (!mounted) return;
      final notifier = ref.read(productFiltersProvider.notifier);
      notifier.updateCategory(decodedCategory);
      if (decodedSubcategory != null) {
        notifier.updateSubcategory(decodedSubcategory);
      }
    });

    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;

    try {
      setState(() {
        isLoading = true;
        error = null;
        products = []; // Clear existing products while loading
      });

      // Create base query for approved products
      var query = FirebaseFirestore.instance
          .collection('products')
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true);

      // Add category filter (case-insensitive)
      final normalizedCategory = decodedCategory.trim().toLowerCase();
      query = query.where('categoryLower', isEqualTo: normalizedCategory);

      // Add subcategory filter if present (case-insensitive)
      if (decodedSubcategory != null && decodedSubcategory!.isNotEmpty) {
        final normalizedSubcategory = decodedSubcategory!.trim().toLowerCase();
        query = query.where('subcategoryLower', isEqualTo: normalizedSubcategory);
      }

      // Add sorting based on current filter settings
      final filters = ref.read(productFiltersProvider);
      switch (filters.sortBy) {
        case SortOption.priceLowToHigh:
          query = query.orderBy('price', descending: false);
          break;
        case SortOption.priceHighToLow:
          query = query.orderBy('price', descending: true);
          break;
        case SortOption.popularity:
          query = query.orderBy('rating', descending: true);
          break;
        case SortOption.newest:
        default:
          query = query.orderBy('createdAt', descending: true);
          break;
      }

      // Execute query with error handling
      final querySnapshot = await query.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Failed to load products. Please check your connection and try again.');
        },
      );
      
      if (!mounted) return;

      // Convert to product models with validation
      final loadedProducts = querySnapshot.docs.map((doc) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          // Add ID to data if not present
          data['id'] = data['id'] ?? doc.id;
          return ProductModel.fromMap(data, doc.id);
        } catch (e) {
          print('❌ Error parsing product ${doc.id}: $e');
          return null;
        }
      }).whereType<ProductModel>().toList();

      if (!mounted) return;

      setState(() {
        products = loadedProducts;
        isLoading = false;
      });

      // Log success/failure for debugging
      print('✅ Loaded ${products.length} products for category: $decodedCategory, subcategory: $decodedSubcategory');

    } catch (e, stackTrace) {
      print('❌ Error loading products: $e');
      print('Stack trace: $stackTrace');
      
      if (!mounted) return;
      
      setState(() {
        error = e is TimeoutException 
            ? e.toString()
            : 'Error loading products. Please try again.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the filters to rebuild when they change
    final filters = ref.watch(productFiltersProvider);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Top navigation bar
          const TopNavBar(),
          
          // Breadcrumb navigation
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    // Navigate to category without subcategory
                    final encodedCategory = Uri.encodeComponent(decodedCategory);
                    context.go('/category/$encodedCategory');
                  },
                  child: Text(
                    decodedCategory,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.blue,
                    ),
                  ),
                ),
                if (decodedSubcategory != null) ...[
                  const Icon(Icons.chevron_right),
                  const SizedBox(width: 8),
                  Text(
                    decodedSubcategory!,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ],
            ),
          ),

          // Results count and filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${products.length} results',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Show filter modal
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => const FilterBottomSheet(),
                    );
                  },
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filter & Sort'),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              error!,
                              style: TextStyle(color: Colors.red[700]),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadProducts,
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      )
                    : products.isEmpty
                        ? Center(
                            child: Text(
                              'No products found',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 8, bottom: 24),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              return HorizontalProductCard(
                                product: products[index],
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
} 