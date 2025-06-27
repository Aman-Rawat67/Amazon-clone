import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';

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
      
      // Reload products to include the new one
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
      
      // Update the product in the current state
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
      
      // Remove the product from the current state
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
      final products = await _firestoreService.getProductsByCategory(category);
      state = AsyncValue.data(products);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Search products
  Future<void> searchProducts(String searchQuery) async {
    try {
      state = const AsyncValue.loading();
      final products = await _firestoreService.searchProducts(searchQuery);
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

/// Provider for filtered products
final filteredProductsProvider = StateProvider<List<ProductModel>>((ref) => []);

/// Provider for search query
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for selected category
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Provider for price range filter
final priceRangeProvider = StateProvider<RangeValues>((ref) => const RangeValues(0, 10000));

/// Provider for sort option
final sortOptionProvider = StateProvider<ProductSortOption>((ref) => ProductSortOption.newest);

/// Enum for product sorting options
enum ProductSortOption {
  newest,
  oldest,
  priceLowToHigh,
  priceHighToLow,
  nameAZ,
  nameZA,
  rating,
  popularity,
}

/// Provider for sorted and filtered products
final sortedAndFilteredProductsProvider = Provider<List<ProductModel>>((ref) {
  final products = ref.watch(productProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final priceRange = ref.watch(priceRangeProvider);
  final sortOption = ref.watch(sortOptionProvider);

  return products.when(
    data: (productList) {
      var filteredProducts = productList;

      // Filter by search query
      if (searchQuery.isNotEmpty) {
        filteredProducts = filteredProducts.where((product) {
          return product.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              product.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
              product.tags.any((tag) => tag.toLowerCase().contains(searchQuery.toLowerCase()));
        }).toList();
      }

      // Filter by category
      if (selectedCategory != null && selectedCategory.isNotEmpty) {
        filteredProducts = filteredProducts.where((product) {
          return product.category == selectedCategory;
        }).toList();
      }

      // Filter by price range
      filteredProducts = filteredProducts.where((product) {
        return product.price >= priceRange.start && product.price <= priceRange.end;
      }).toList();

      // Filter only approved and active products for customers
      filteredProducts = filteredProducts.where((product) {
        return product.isApproved && product.isActive;
      }).toList();

      // Sort products
      switch (sortOption) {
        case ProductSortOption.newest:
          filteredProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case ProductSortOption.oldest:
          filteredProducts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
        case ProductSortOption.priceLowToHigh:
          filteredProducts.sort((a, b) => a.price.compareTo(b.price));
          break;
        case ProductSortOption.priceHighToLow:
          filteredProducts.sort((a, b) => b.price.compareTo(a.price));
          break;
        case ProductSortOption.nameAZ:
          filteredProducts.sort((a, b) => a.name.compareTo(b.name));
          break;
        case ProductSortOption.nameZA:
          filteredProducts.sort((a, b) => b.name.compareTo(a.name));
          break;
        case ProductSortOption.rating:
          filteredProducts.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case ProductSortOption.popularity:
          filteredProducts.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
          break;
      }

      return filteredProducts;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for featured products
final featuredProductsProvider = Provider<List<ProductModel>>((ref) {
  final products = ref.watch(productProvider);
  
  return products.when(
    data: (productList) {
      return productList
          .where((product) => product.isApproved && product.isActive && product.rating >= 4.0)
          .take(10)
          .toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for vendor's products
final vendorProductsProvider = FutureProvider.family<List<ProductModel>, String>((ref, vendorId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getProducts(vendorId: vendorId);
});

/// Provider for products pending approval (admin only)
final pendingApprovalProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getProducts(isApproved: false);
});

/// Range values class for price filtering
class RangeValues {
  final double start;
  final double end;

  const RangeValues(this.start, this.end);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RangeValues && other.start == start && other.end == end;
  }

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
} 