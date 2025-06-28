import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../services/firestore_service.dart';
import '../../constants/app_constants.dart';
import '../../widgets/home/product_card.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Enum for sorting options
enum SortOption {
  newest,
  priceLowToHigh,
  priceHighToLow,
  rating,
  popularity,
}

/// Extension to get display text for sort options
extension SortOptionExtension on SortOption {
  String get displayText {
    switch (this) {
      case SortOption.newest:
        return 'Newest First';
      case SortOption.priceLowToHigh:
        return 'Price: Low to High';
      case SortOption.priceHighToLow:
        return 'Price: High to Low';
      case SortOption.rating:
        return 'Customer Rating';
      case SortOption.popularity:
        return 'Popularity';
    }
  }
}

/// Provider for category products with sorting and filtering
final categoryProductsProvider = StateNotifierProvider.family<CategoryProductsNotifier, AsyncValue<List<ProductModel>>, String>((ref, category) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return CategoryProductsNotifier(firestoreService, category);
});

/// State notifier for managing category products with sorting and filtering
class CategoryProductsNotifier extends StateNotifier<AsyncValue<List<ProductModel>>> {
  final FirestoreService _firestoreService;
  final String _category;
  List<ProductModel> _allProducts = [];
  SortOption _currentSort = SortOption.newest;
  String _searchQuery = '';

  CategoryProductsNotifier(this._firestoreService, this._category) : super(const AsyncValue.loading()) {
    loadProducts();
  }

  /// Load all products for the category
  Future<void> loadProducts() async {
    try {
      state = const AsyncValue.loading();
      final products = await _firestoreService.getProductsByCategory(_category);
      _allProducts = products;
      _applySortAndFilter();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Update sort option and reapply filtering
  void updateSort(SortOption sortOption) {
    _currentSort = sortOption;
    _applySortAndFilter();
  }

  /// Update search query and reapply filtering
  void updateSearch(String query) {
    _searchQuery = query.toLowerCase();
    _applySortAndFilter();
  }

  /// Apply current sort and filter settings
  void _applySortAndFilter() {
    var filteredProducts = List<ProductModel>.from(_allProducts);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredProducts = filteredProducts.where((product) {
        return product.name.toLowerCase().contains(_searchQuery) ||
               product.description.toLowerCase().contains(_searchQuery) ||
               product.category.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Apply sorting
    switch (_currentSort) {
      case SortOption.newest:
        filteredProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.priceLowToHigh:
        filteredProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.priceHighToLow:
        filteredProducts.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortOption.rating:
        filteredProducts.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.popularity:
        // Sort by a combination of rating and orders (mock popularity)
        filteredProducts.sort((a, b) => (b.rating * 100 + b.stockQuantity).compareTo(a.rating * 100 + a.stockQuantity));
        break;
    }

    state = AsyncValue.data(filteredProducts);
  }

  SortOption get currentSort => _currentSort;
  String get searchQuery => _searchQuery;
}

/// Screen that displays products for a specific category with filtering and sorting
class CategoryProductsScreen extends ConsumerStatefulWidget {
  final String category;

  const CategoryProductsScreen({
    super.key,
    required this.category,
  });

  @override
  ConsumerState<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends ConsumerState<CategoryProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final notifier = ref.read(categoryProductsProvider(widget.category).notifier);
    notifier.updateSearch(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700 && !kIsWeb;
    final productsAsyncValue = ref.watch(categoryProductsProvider(widget.category));
    final notifier = ref.read(categoryProductsProvider(widget.category).notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          _getCategoryDisplayName(widget.category),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.push('/cart'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search in ${_getCategoryDisplayName(widget.category)}',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 12),
                // Sort Options
                Row(
                  children: [
                    const Icon(Icons.sort, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Text(
                      'Sort by:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<SortOption>(
                          value: notifier.currentSort,
                          onChanged: (SortOption? newValue) {
                            if (newValue != null) {
                              notifier.updateSort(newValue);
                            }
                          },
                          items: SortOption.values.map((SortOption option) {
                            return DropdownMenuItem<SortOption>(
                              value: option,
                              child: Text(
                                option.displayText,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Products Grid
          Expanded(
            child: productsAsyncValue.when(
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(error),
              data: (products) => _buildProductsGrid(products, isMobile),
            ),
          ),
        ],
      ),
    );
  }

  /// Build loading state with shimmer effect
  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(MediaQuery.of(context).size.width),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: 8,
        itemBuilder: (context, index) => _buildShimmerCard(),
      ),
    );
  }

  /// Build shimmer loading card
  Widget _buildShimmerCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load products',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.read(categoryProductsProvider(widget.category).notifier).loadProducts();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Build products grid
  Widget _buildProductsGrid(List<ProductModel> products, bool isMobile) {
    if (products.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        controller: _scrollController,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(MediaQuery.of(context).size.width),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return ProductCard(
            product: products[index],
            showAddToCart: true,
          );
        },
      ),
    );
  }

  /// Build empty state when no products found
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              ref.read(categoryProductsProvider(widget.category).notifier).updateSort(SortOption.newest);
            },
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  /// Get cross axis count based on screen width
  int _getCrossAxisCount(double width) {
    if (width < 600) return 2; // Mobile: 2 columns
    if (width < 900) return 3; // Tablet: 3 columns
    if (width < 1200) return 4; // Small desktop: 4 columns
    return 5; // Large desktop: 5 columns
  }

  /// Get display name for category
  String _getCategoryDisplayName(String category) {
    return category.split(' ').map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ');
  }
} 