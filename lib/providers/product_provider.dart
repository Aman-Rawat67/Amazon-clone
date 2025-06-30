import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';
import '../constants/filter_constants.dart';

/// Provider for Firestore service
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

/// Provider for product management
final productProvider = StateNotifierProvider<ProductNotifier, AsyncValue<List<ProductModel>>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return ProductNotifier(firestoreService);
});

/// State notifier for product management
class ProductNotifier extends StateNotifier<AsyncValue<List<ProductModel>>> {
  final FirestoreService _firestoreService;

  ProductNotifier(this._firestoreService) : super(const AsyncValue.loading()) {
    loadProducts();
  }

  /// Load products with optional filters
  Future<void> loadProducts({
    String? category,
    String? searchQuery,
    bool? isApproved,
    String? vendorId,
    bool refresh = false,
    SortOption sortBy = SortOption.newest,
  }) async {
    try {
      if (refresh) {
        state = const AsyncValue.loading();
      }

      final products = await _firestoreService.getProducts(
        category: category,
        searchQuery: searchQuery,
        isApproved: isApproved,
        vendorId: vendorId,
        sortBy: sortBy,
      );

      state = AsyncValue.data(products);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Add a new product
  Future<String> addProduct(ProductModel product) async {
    try {
      final productId = await _firestoreService.addProduct(product);
      await loadProducts(refresh: true);
      return productId;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Update an existing product
  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    try {
      await _firestoreService.updateProduct(productId, data);
      state.whenData((products) {
        final updatedProducts = products.map((product) {
          if (product.id == productId) {
            return product.copyWith(
              name: data['name'] ?? product.name,
              description: data['description'] ?? product.description,
              price: data['price']?.toDouble() ?? product.price,
              originalPrice: data['originalPrice']?.toDouble() ?? product.originalPrice,
              category: data['category'] ?? product.category,
              subcategory: data['subcategory'] ?? product.subcategory,
              stockQuantity: data['stockQuantity'] ?? product.stockQuantity,
              isActive: data['isActive'] ?? product.isActive,
              isApproved: data['isApproved'] ?? product.isApproved,
              updatedAt: DateTime.now(),
            );
          }
          return product;
        }).toList();
        state = AsyncValue.data(updatedProducts);
      });
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Delete a product
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestoreService.deleteProduct(productId);
      state.whenData((products) {
        final updatedProducts = products.where((product) => product.id != productId).toList();
        state = AsyncValue.data(updatedProducts);
      });
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Get products by category
  Future<void> loadProductsByCategory(String category) async {
    try {
      state = const AsyncValue.loading();
      // Try both lowercase and original casing
      final products = await _firestoreService.getProductsByCategory(category);
      state = AsyncValue.data(products);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Search products
  Future<void> searchProducts(String searchQuery, {String? category}) async {
    try {
      state = const AsyncValue.loading();
      final products = await _firestoreService.searchProducts(
        query: searchQuery,
        category: category,
      );
      state = AsyncValue.data(products);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Get products for vendor
  Future<void> loadVendorProducts(String vendorId) async {
    try {
      state = const AsyncValue.loading();
      final products = await _firestoreService.getProducts(vendorId: vendorId);
      state = AsyncValue.data(products);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Get products for admin (including unapproved)
  Future<void> loadAllProductsForAdmin() async {
    try {
      state = const AsyncValue.loading();
      final products = await _firestoreService.getProducts();
      state = AsyncValue.data(products);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Approve product (admin only)
  Future<void> approveProduct(String productId) async {
    try {
      await updateProduct(productId, {'isApproved': true});
    } catch (e) {
      rethrow;
    }
  }

  /// Reject product (admin only)
  Future<void> rejectProduct(String productId) async {
    try {
      await updateProduct(productId, {'isApproved': false});
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle product active status
  Future<void> toggleProductStatus(String productId, bool isActive) async {
    try {
      await updateProduct(productId, {'isActive': isActive});
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for a single product
final singleProductProvider = FutureProvider.family<ProductModel?, String>((ref, productId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getProduct(productId);
});

/// Provider for product by ID (alias for consistency)
final productByIdProvider = singleProductProvider;

/// Provider for product categories
final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getCategories();
});

/// Product filter state class
class ProductFilters {
  final SortOption sortBy;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final String? category;
  final String? subcategory;
  final String? priceRange;
  
  ProductFilters({
    this.sortBy = SortOption.newest,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.category,
    this.subcategory,
    this.priceRange,
  });

  /// Whether any filters are active
  bool get hasActiveFilters {
    return sortBy != SortOption.newest ||
           minPrice != null ||
           maxPrice != null ||
           minRating != null ||
           priceRange != null;
  }

  ProductFilters copyWith({
    SortOption? sortBy,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? category,
    String? subcategory,
    String? priceRange,
  }) {
    return ProductFilters(
      sortBy: sortBy ?? this.sortBy,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      priceRange: priceRange ?? this.priceRange,
    );
  }
}

/// Provider for product filters
final productFiltersProvider = StateNotifierProvider<ProductFiltersNotifier, ProductFilters>((ref) {
  return ProductFiltersNotifier(ref);
});

/// Notifier for product filters
class ProductFiltersNotifier extends StateNotifier<ProductFilters> {
  final Ref _ref;

  ProductFiltersNotifier(this._ref) : super(ProductFilters());

  /// Update sort option
  void updateSortBy(SortOption sortBy) {
    state = state.copyWith(sortBy: sortBy);
    _refreshProducts();
  }

  /// Update price range
  void updatePriceRange(double? minPrice, double? maxPrice) {
    state = state.copyWith(
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
    _refreshProducts();
  }

  /// Update minimum rating
  void updateRating(double? rating) {
    state = state.copyWith(minRating: rating);
    _refreshProducts();
  }

  /// Update category
  void updateCategory(String? category) {
    state = state.copyWith(
      category: category,
      subcategory: null, // Reset subcategory when category changes
    );
    _refreshProducts();
  }

  /// Update subcategory
  void updateSubcategory(String? subcategory) {
    state = state.copyWith(subcategory: subcategory);
    _refreshProducts();
  }

  /// Reset all filters
  void resetFilters() {
    state = ProductFilters();
    _refreshProducts();
  }

  /// Refresh products with current filters
  void _refreshProducts() {
    _ref.read(productProvider.notifier).loadProducts(
      category: state.category,
      sortBy: state.sortBy,
    );
  }
}

/// Provider for filtered products
final filteredProductsProvider = Provider<AsyncValue<List<ProductModel>>>((ref) {
  final filters = ref.watch(productFiltersProvider);
  final productsAsyncValue = ref.watch(productProvider);

  return productsAsyncValue.when(
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
    data: (products) {
      // Apply filters
      var filteredProducts = products.where((product) {
        // Category filter
        if (filters.category != null && filters.category!.isNotEmpty) {
          if (product.category.toLowerCase() != filters.category!.toLowerCase()) {
            return false;
          }
        }

        // Price range filter
        if (filters.minPrice != null && product.price < filters.minPrice!) {
          return false;
        }
        if (filters.maxPrice != null && product.price > filters.maxPrice!) {
          return false;
        }

        // Rating filter
        if (filters.minRating != null && filters.minRating! > 0 && product.rating < filters.minRating!) {
          return false;
        }

        return true;
      }).toList();

      // Apply sorting
      switch (filters.sortBy) {
        case SortOption.priceLowToHigh:
          filteredProducts.sort((a, b) => a.price.compareTo(b.price));
          break;
        case SortOption.priceHighToLow:
          filteredProducts.sort((a, b) => b.price.compareTo(a.price));
          break;
        case SortOption.popularity:
          filteredProducts.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case SortOption.newest:
        default:
          filteredProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
      }

      return AsyncValue.data(filteredProducts);
    },
  );
});

/// Provider for searching products with query and optional category filter
final searchProductsProvider = FutureProvider.family<List<ProductModel>, ({String query, String? category})>((ref, params) async {
  final firestoreService = ref.read(firestoreServiceProvider);
  
  try {
    return await firestoreService.searchProducts(
      query: params.query,
      category: params.category == 'All' ? null : params.category,
    );
  } catch (e) {
    throw Exception('Failed to search products: $e');
  }
});