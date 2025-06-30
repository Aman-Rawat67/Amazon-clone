import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import '../../providers/product_provider.dart';
import '../../services/firestore_service.dart';
import '../../constants/app_constants.dart';
import '../../constants/filter_constants.dart';
import '../../widgets/home/product_card.dart';
import '../../widgets/home/hover_dropdown_menu.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/home/top_nav_bar.dart';
import '../../widgets/home/search_bar_widget.dart';
import '../../widgets/home/sort_filter_widget.dart';

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
  late String decodedCategory;
  late String? decodedSubcategory;
  CategoryModel? categoryData;
  bool isLoadingCategory = true;
  String? categoryError;

  @override
  void initState() {
    super.initState();
    // Decode the category and subcategory parameters
    decodedCategory = Uri.decodeComponent(widget.category);
    decodedSubcategory = widget.subcategory != null ? Uri.decodeComponent(widget.subcategory!) : null;
    
    // Set initial category filter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productFiltersProvider.notifier).updateCategory(decodedCategory);
      if (decodedSubcategory != null) {
        ref.read(productFiltersProvider.notifier).updateSubcategory(decodedSubcategory!);
      }
      _loadCategoryData();
    });
  }

  Future<void> _loadCategoryData() async {
    try {
      setState(() {
        isLoadingCategory = true;
        categoryError = null;
      });

      final doc = await FirebaseFirestore.instance
          .collection('categories')
          .where('name', isEqualTo: decodedCategory)
          .get();
      
      if (doc.docs.isNotEmpty) {
        setState(() {
          categoryData = CategoryModel.fromJson({
            'id': doc.docs.first.id,
            ...doc.docs.first.data(),
          });
          isLoadingCategory = false;
        });
      } else {
        setState(() {
          categoryError = 'Category not found';
          isLoadingCategory = false;
        });
      }
    } catch (e) {
      setState(() {
        categoryError = 'Error loading category data';
        isLoadingCategory = false;
      });
      debugPrint('Error loading category data: $e');
    }
  }

  Query<Map<String, dynamic>> _buildQuery() {
    final filters = ref.watch(productFiltersProvider);
    
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('products')
        .where('category', isEqualTo: decodedCategory.toLowerCase());

    // Add subcategory filter only if it's provided
    if (decodedSubcategory != null && decodedSubcategory!.isNotEmpty) {
      query = query.where('subcategory', isEqualTo: decodedSubcategory!.toLowerCase());
    }

    // Apply price filter
    if (filters.minPrice != null) {
      query = query.where('price', isGreaterThanOrEqualTo: filters.minPrice);
    }
    if (filters.maxPrice != null && filters.maxPrice != double.infinity) {
      query = query.where('price', isLessThanOrEqualTo: filters.maxPrice);
    }

    // Apply rating filter
    if (filters.minRating != null) {
      query = query.where('rating', isGreaterThanOrEqualTo: filters.minRating);
    }

    // Apply sorting
    switch (filters.sortBy) {
      case SortOption.priceLowToHigh:
        query = query.orderBy('price', descending: false);
        break;
      case SortOption.priceHighToLow:
        query = query.orderBy('price', descending: true);
        break;
      case SortOption.newest:
        query = query.orderBy('createdAt', descending: true);
        break;
      case SortOption.popularity:
        query = query.orderBy('rating', descending: true);
        break;
    }

    return query;
  }

  Widget _buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.go('/'),
            child: const Text(
              'Home',
              style: TextStyle(
                color: Color(0xFF0F1111),
                fontSize: 14,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          if (decodedSubcategory != null) ...[
            InkWell(
              onTap: () => context.go('/category/${Uri.encodeComponent(decodedCategory)}'),
              child: Text(
                decodedCategory,
                style: const TextStyle(
                  color: Color(0xFF0F1111),
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            Text(
              decodedSubcategory!,
              style: const TextStyle(
                color: Color(0xFF0F1111),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else ...[
            Text(
              decodedCategory,
              style: const TextStyle(
                color: Color(0xFF0F1111),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryHeader() {
    if (isLoadingCategory) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: SizedBox(
            height: 2,
            width: 100,
            child: LinearProgressIndicator(
              backgroundColor: Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF232F3E)),
            ),
          ),
        ),
      );
    }

    if (categoryError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 20, color: Colors.red.shade400),
            const SizedBox(width: 8),
            Text(
              categoryError!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
      );
    }

    if (categoryData == null || !categoryData!.hasSubcategories) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          decodedCategory,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F1111),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            decodedCategory,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F1111),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categoryData!.subcategories.map((subcategory) {
              final isSelected = decodedSubcategory == subcategory;
              final subcategoryMetadata = categoryData!.metadata?['subcategories']?[subcategory] as Map<String, dynamic>?;
              final iconUrl = subcategoryMetadata?['iconUrl'] as String?;

              return InkWell(
                onTap: () {
                  context.go('/category/${Uri.encodeComponent(decodedCategory)}/${Uri.encodeComponent(subcategory)}');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF232F3E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF232F3E) : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (iconUrl != null) ...[
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Image.network(
                            iconUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.category,
                              size: 16,
                              color: isSelected ? Colors.white : Colors.grey.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        subcategory,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected ? Colors.white : const Color(0xFF0F1111),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(productFiltersProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFEAeded),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: TopNavBar()),
          const SliverToBoxAdapter(child: SearchBarWidget()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBreadcrumb(),
                  const SizedBox(height: 16),
                  _buildCategoryHeader(),
                  const SizedBox(height: 16),
                  // Filters section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Filters',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F1111),
                              ),
                            ),
                            const Spacer(),
                            if (filters.hasActiveFilters)
                              TextButton.icon(
                                onPressed: () {
                                  ref.read(productFiltersProvider.notifier).resetFilters();
                                },
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Reset'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.grey.shade700,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SortFilterWidget(
                          onSortChanged: (sort) {
                            ref.read(productFiltersProvider.notifier).updateSortBy(sort);
                          },
                          onPriceRangeChanged: (min, max) {
                            ref.read(productFiltersProvider.notifier).updatePriceRange(min, max);
                          },
                          onRatingChanged: (rating) {
                            ref.read(productFiltersProvider.notifier).updateRating(rating);
                          },
                          selectedSort: filters.sortBy,
                          selectedPriceRange: RangeValues(
                            filters.minPrice ?? 0,
                            filters.maxPrice ?? double.infinity,
                          ),
                          selectedRating: filters.minRating ?? 0,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Products grid
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _buildQuery().snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Text('Error: ${snapshot.error}'),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final products = snapshot.data!.docs
                  .map((doc) => ProductModel.fromJson({
                        'id': doc.id,
                        ...doc.data(),
                      }))
                  .toList();

              if (products.isEmpty) {
                return SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters or search criteria',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 2 : 4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.7,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ProductCard(product: products[index]),
                    childCount: products.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
} 