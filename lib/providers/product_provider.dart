import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';
import '../constants/filter_constants.dart';
import 'package:flutter/foundation.dart';

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
      // Use normalized lowercase category
      final normalizedCategory = category.trim().toLowerCase();
      final products = await _firestoreService.getProductsByCategory(normalizedCategory);
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
        category: category?.trim().toLowerCase(),
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

/// Class to hold all product filter states
class ProductFilters {
  final String? category;
  final String? subcategory;
  final SortOption sortBy;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;

  const ProductFilters({
    this.category,
    this.subcategory,
    this.sortBy = SortOption.newest,
    this.minPrice,
    this.maxPrice,
    this.minRating,
  });

  bool get hasActiveFilters =>
      category != null ||
      subcategory != null ||
      sortBy != SortOption.newest ||
      minPrice != null ||
      maxPrice != null ||
      minRating != null;

  ProductFilters copyWith({
    String? category,
    String? subcategory,
    SortOption? sortBy,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool clearCategory = false,
    bool clearSubcategory = false,
    bool clearPriceRange = false,
    bool clearRating = false,
  }) {
    return ProductFilters(
      category: clearCategory ? null : (category ?? this.category),
      subcategory: clearSubcategory ? null : (subcategory ?? this.subcategory),
      sortBy: sortBy ?? this.sortBy,
      minPrice: clearPriceRange ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPriceRange ? null : (maxPrice ?? this.maxPrice),
      minRating: clearRating ? null : (minRating ?? this.minRating),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category?.trim().toLowerCase(),
      'subcategory': subcategory?.trim().toLowerCase(),
      'sortBy': sortBy.toString(),
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'minRating': minRating,
    };
  }

  @override
  String toString() {
    return 'ProductFilters(category: $category, subcategory: $subcategory, sortBy: $sortBy, minPrice: $minPrice, maxPrice: $maxPrice, minRating: $minRating)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ProductFilters &&
        other.category?.trim().toLowerCase() == category?.trim().toLowerCase() &&
        other.subcategory?.trim().toLowerCase() == subcategory?.trim().toLowerCase() &&
        other.sortBy == sortBy &&
        other.minPrice == minPrice &&
        other.maxPrice == maxPrice &&
        other.minRating == minRating;
  }

  @override
  int get hashCode {
    return category.hashCode ^
        subcategory.hashCode ^
        sortBy.hashCode ^
        minPrice.hashCode ^
        maxPrice.hashCode ^
        minRating.hashCode;
  }
}

/// Provider for filtered products
final filteredProductsProvider = StateNotifierProvider<ProductsNotifier, AsyncValue<List<ProductModel>>>((ref) {
  return ProductsNotifier(ref);
});

/// Provider for product filters
final productFiltersProvider = StateNotifierProvider<ProductFiltersNotifier, ProductFilters>((ref) {
  return ProductFiltersNotifier();
});

/// Notifier for product filters
class ProductFiltersNotifier extends StateNotifier<ProductFilters> {
  ProductFiltersNotifier() : super(const ProductFilters());
  bool _isUpdating = false;

  void resetFilters() {
    if (_isUpdating || state == const ProductFilters()) return;
    _isUpdating = true;
    
    debugPrint("debugging:: resetting all filters");
    state = const ProductFilters();
    _isUpdating = false;
  }

  void updateCategory(String? category) {
    if (_isUpdating || category?.toLowerCase() == state.category?.toLowerCase()) return;
    _isUpdating = true;
    
    debugPrint("debugging:: updating category to: $category");
    state = state.copyWith(
      category: category,
      clearSubcategory: true, // Clear subcategory when category changes
    );
    _isUpdating = false;
  }

  void updateSubcategory(String? subcategory) {
    if (_isUpdating || subcategory?.toLowerCase() == state.subcategory?.toLowerCase()) return;
    _isUpdating = true;
    
    debugPrint("debugging:: updating subcategory to: $subcategory");
    state = state.copyWith(subcategory: subcategory);
    _isUpdating = false;
  }

  void updateSortBy(SortOption sortBy) {
    if (sortBy == state.sortBy) return;
    state = state.copyWith(sortBy: sortBy);
  }

  void updatePriceRange(double? minPrice, double? maxPrice) {
    // Validate price range
    if (minPrice != null && maxPrice != null && minPrice > maxPrice) {
      final temp = minPrice;
      minPrice = maxPrice;
      maxPrice = temp;
    }
    
    if (minPrice == state.minPrice && maxPrice == state.maxPrice) return;
    state = state.copyWith(
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }

  void updateRating(double? minRating) {
    if (minRating == state.minRating) return;
    state = state.copyWith(minRating: minRating);
  }

  void updateFilters({
    String? category,
    String? subcategory,
    SortOption? sortBy,
    double? minPrice,
    double? maxPrice,
    double? minRating,
  }) {
    if (_isUpdating) return;
    _isUpdating = true;
    
    debugPrint("debugging:: updating filters - category: $category, subcategory: $subcategory");
    
    // Validate price range
    if (minPrice != null && maxPrice != null && minPrice > maxPrice) {
      final temp = minPrice;
      minPrice = maxPrice;
      maxPrice = temp;
    }

    // Skip update if all values are the same
    if (category?.toLowerCase() == state.category?.toLowerCase() &&
        subcategory?.toLowerCase() == state.subcategory?.toLowerCase() &&
        sortBy == state.sortBy &&
        minPrice == state.minPrice &&
        maxPrice == state.maxPrice &&
        minRating == state.minRating) {
      _isUpdating = false;
      return;
    }

    state = state.copyWith(
      category: category,
      subcategory: subcategory,
      sortBy: sortBy,
      minPrice: minPrice,
      maxPrice: maxPrice,
      minRating: minRating,
    );
    _isUpdating = false;
  }
}

class ProductsNotifier extends StateNotifier<AsyncValue<List<ProductModel>>> {
  final Ref _ref;
  final FirestoreService _firestoreService;
  ProductFilters _filters = const ProductFilters();
  bool _isLoading = false;

  ProductsNotifier(this._ref)
      : _firestoreService = _ref.read(firestoreServiceProvider),
        super(const AsyncValue.loading()) {
    _loadProducts();

    // Listen to filter changes
    _ref.listen(productFiltersProvider, (previous, next) {
      if (previous != next) {
        _filters = next;
        _loadProducts();
      }
    });
  }

  Future<void> _loadProducts() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      state = const AsyncValue.loading();
      final products = await _applyFilters(_filters);
      
      if (products.isEmpty && (_filters.category != null || _filters.subcategory != null)) {
        // If no products found with current filters, try without subcategory
        if (_filters.subcategory != null) {
          final filtersWithoutSubcategory = _filters.copyWith(clearSubcategory: true);
          final productsWithoutSubcategory = await _applyFilters(filtersWithoutSubcategory);
          if (productsWithoutSubcategory.isNotEmpty) {
            state = AsyncValue.data(productsWithoutSubcategory);
            _isLoading = false;
            return;
          }
        }
        
        // If still no products, try without category and subcategory
        if (_filters.category != null) {
          final filtersWithoutCategory = _filters.copyWith(clearCategory: true, clearSubcategory: true);
          final productsWithoutCategory = await _applyFilters(filtersWithoutCategory);
          if (productsWithoutCategory.isNotEmpty) {
            state = AsyncValue.data(productsWithoutCategory);
            _isLoading = false;
            return;
          }
        }
      }
      
      state = AsyncValue.data(products);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    } finally {
      _isLoading = false;
    }
  }

  Future<List<ProductModel>> _applyFilters(ProductFilters filters) async {
    try {
      CollectionReference productsRef = FirebaseFirestore.instance.collection('products');
      Query query = productsRef.where('isActive', isEqualTo: true)
          .where('isApproved', isEqualTo: true);

      // Apply category filter (case-insensitive)
      if (filters.category != null) {
        query = query.where('categoryLower', isEqualTo: filters.category?.toLowerCase());
      }

      // Apply subcategory filter (case-insensitive)
      if (filters.subcategory != null) {
        query = query.where('subcategoryLower', isEqualTo: filters.subcategory?.toLowerCase());
      }

      // Due to Firestore limitations, we can't combine multiple range filters
      // So we'll fetch all products that meet the basic criteria and filter in memory
      final querySnapshot = await query.get();
      List<ProductModel> products = querySnapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Apply price range filter in memory
      if (filters.minPrice != null || filters.maxPrice != null) {
        products = products.where((product) {
          final price = product.price;
          if (filters.minPrice != null && price < filters.minPrice!) {
            return false;
          }
          if (filters.maxPrice != null && price > filters.maxPrice!) {
            return false;
          }
          return true;
        }).toList();
      }

      // Apply rating filter in memory
      if (filters.minRating != null) {
        products = products.where((product) => 
          product.rating >= filters.minRating!
        ).toList();
      }

      // Apply sorting in memory
      switch (filters.sortBy) {
        case SortOption.priceLowToHigh:
          products.sort((a, b) => a.price.compareTo(b.price));
          break;
        case SortOption.priceHighToLow:
          products.sort((a, b) => b.price.compareTo(a.price));
          break;
        case SortOption.popularity:
          products.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case SortOption.newest:
          products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
      }

      return products;
    } catch (e) {
      print('Error applying filters: $e');
      return [];
    }
  }

  void updateFilters(ProductFilters filters) {
    if (_filters == filters) return;
    _filters = filters;
    _loadProducts();
  }
}

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