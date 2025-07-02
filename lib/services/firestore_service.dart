import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';  // Add this import for TimeoutException
import '../models/product_model.dart';
import '../models/cart_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/product_section_model.dart';
import '../models/banner_model.dart';
import '../models/category_model.dart';
import '../models/deal_model.dart';
import '../constants/app_constants.dart';
import '../constants/filter_constants.dart';

/// Provider for FirestoreService
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Service class for handling Firestore database operations
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // PRODUCT OPERATIONS

  /// Add a new product and auto-assign to appropriate section
  Future<String> addProduct(ProductModel product) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.productsCollection)
          .add(product.toJson());
      
      // Update product with the generated ID
      await docRef.update({'id': docRef.id});
      
      // Auto-assign to product section based on category
      await _autoAssignProductToSection(docRef.id, product.category);
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add product: ${e.toString()}');
    }
  }

  /// Automatically assign product to appropriate section
  Future<void> _autoAssignProductToSection(String productId, String category) async {
    try {
      // Find existing section for this category
      final sectionsQuery = await _firestore
          .collection(AppConstants.productSectionsCollection)
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (sectionsQuery.docs.isNotEmpty) {
        // Add to existing section
        final sectionDoc = sectionsQuery.docs.first;
        final currentProductIds = List<String>.from(sectionDoc.data()['productIds'] ?? []);
        
        if (!currentProductIds.contains(productId)) {
          currentProductIds.add(productId);
          await sectionDoc.reference.update({
            'productIds': currentProductIds,
            'updatedAt': Timestamp.now(),
          });
        }
      } else {
        // Create new section for this category
        await _createCategorySection(category, productId);
      }
    } catch (e) {
      print('Warning: Could not auto-assign product to section: $e');
      // Don't throw error - product creation should still succeed
    }
  }

  /// Create a new product section for a category
  Future<void> _createCategorySection(String category, String firstProductId) async {
    try {
      final sectionTitle = _generateSectionTitle(category);
      final encodedCategory = Uri.encodeComponent(category.toLowerCase());
      
      await _firestore
          .collection(AppConstants.productSectionsCollection)
          .add({
        'title': sectionTitle,
        'subtitle': 'Best deals on $category',
        'category': category,
        'productIds': [firstProductId],
        'seeMoreText': 'See all offers',
        'seeMoreRoute': '/category/$encodedCategory',
        'displayCount': 4,
        'isActive': true,
        'order': await _getNextSectionOrder(),
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to create category section: $e');
    }
  }

  /// Generate section title based on category
  String _generateSectionTitle(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return 'Starting ₹999 | Electronics';
      case 'fashion':
        return 'Starting ₹299 | Fashion';
      case 'home & kitchen':
        return 'Starting ₹199 | Home & Kitchen';
      case 'books':
        return 'Starting ₹99 | Books';
      case 'sports':
        return 'Starting ₹499 | Sports';
      default:
        return 'Great deals on $category';
    }
  }

  /// Get next section order number
  Future<int> _getNextSectionOrder() async {
    try {
      final sectionsQuery = await _firestore
          .collection(AppConstants.productSectionsCollection)
          .orderBy('order', descending: true)
          .limit(1)
          .get();

      if (sectionsQuery.docs.isNotEmpty) {
        final lastOrder = sectionsQuery.docs.first.data()['order'] as int? ?? 0;
        return lastOrder + 1;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Update an existing product
  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .update(data);
    } catch (e) {
      throw Exception('Failed to update product: ${e.toString()}');
    }
  }

  /// Delete a product
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete product: ${e.toString()}');
    }
  }

  /// Get product by ID
  Future<ProductModel?> getProduct(String productId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .get();

      if (doc.exists) {
        return ProductModel.fromJson(doc.data()!);
      }
    } catch (e) {
      throw Exception('Failed to get product: ${e.toString()}');
    }
    return null;
  }

  /// Get products with pagination
  Future<List<ProductModel>> getProducts({
    int limit = AppConstants.defaultPageSize,
    DocumentSnapshot? lastDocument,
    String? category,
    String? searchQuery,
    bool? isApproved,
    String? vendorId,
    SortOption sortBy = SortOption.newest,
  }) async {
    try {
      Query query = _firestore.collection(AppConstants.productsCollection);

      // Add base filters for active products
      query = query.where('isActive', isEqualTo: true);
      
      // Add category filter (case-insensitive)
      if (category != null && category.isNotEmpty) {
        final normalizedCategory = category.trim().toLowerCase();
        query = query.where('categoryLower', isEqualTo: normalizedCategory);
      }

      // Add approval filter
      if (isApproved != null) {
        query = query.where('isApproved', isEqualTo: isApproved);
      }

      // Add vendor filter
      if (vendorId != null && vendorId.isNotEmpty) {
        query = query.where('vendorId', isEqualTo: vendorId);
      }

      // Add search functionality
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final normalizedSearch = searchQuery.trim().toLowerCase();
        query = query.where('searchKeywords', arrayContains: normalizedSearch);
      }

      // Add sorting
      switch (sortBy) {
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

      // Add pagination
      query = query.limit(limit);
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      // Execute query with timeout
      final querySnapshot = await query.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Failed to load products. Please check your connection and try again.');
        },
      );

      // Convert to product models with validation
      final products = querySnapshot.docs.map((doc) {
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

      // Log success/failure for debugging
      print('✅ Loaded ${products.length} products with filters: category=$category, searchQuery=$searchQuery, isApproved=$isApproved, vendorId=$vendorId, sortBy=$sortBy');

      return products;
    } catch (e, stackTrace) {
      print('❌ Error getting products: $e');
      print('Stack trace: $stackTrace');
      if (e is TimeoutException) {
        throw TimeoutException('Failed to load products: Connection timed out');
      }
      throw Exception('Failed to load products: ${e.toString()}');
    }
  }

  /// Get products by category with subcategory support
  Future<List<ProductModel>> getProductsByCategory(String category, {String? subcategory}) async {
    try {
      Query query = _firestore.collection(AppConstants.productsCollection)
          .where('isActive', isEqualTo: true)
          .where('isApproved', isEqualTo: true);

      // Add category filter (case-insensitive)
      final normalizedCategory = category.trim().toLowerCase();
      query = query.where('categoryLower', isEqualTo: normalizedCategory);

      // Add subcategory filter if present (case-insensitive)
      if (subcategory != null && subcategory.isNotEmpty) {
        final normalizedSubcategory = subcategory.trim().toLowerCase();
        query = query.where('subcategoryLower', isEqualTo: normalizedSubcategory);
      }

      // Add sorting by creation date
      query = query.orderBy('createdAt', descending: true);

      // Execute query with timeout
      final querySnapshot = await query.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Failed to load products. Please check your connection and try again.');
        },
      );

      // Convert to product models with validation
      final products = querySnapshot.docs.map((doc) {
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

      // Log success/failure for debugging
      print('✅ Loaded ${products.length} products for category: $category, subcategory: $subcategory');

      return products;
    } catch (e, stackTrace) {
      print('❌ Error getting products by category: $e');
      print('Stack trace: $stackTrace');
      if (e is TimeoutException) {
        throw TimeoutException('Failed to load products: Connection timed out');
      }
      throw Exception('Failed to load products: ${e.toString()}');
    }
  }

  // CART OPERATIONS

  /// Stream cart data for a user
  Stream<CartModel?> streamCart(String userId) {
    return _firestore
        .collection(AppConstants.cartsCollection)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return CartModel.fromJson(snapshot.docs.first.data());
        });
  }

  /// Update cart data
  Future<void> updateCart(CartModel cart) async {
    try {
      await _firestore
          .collection(AppConstants.cartsCollection)
          .doc(cart.id)
          .set(cart.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update cart: $e');
    }
  }

  /// Delete cart
  Future<void> deleteCart(String cartId) async {
    try {
      await _firestore
          .collection(AppConstants.cartsCollection)
          .doc(cartId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete cart: $e');
    }
  }

  /// Add item to cart with improved error handling
  Future<void> addToCart(String userId, CartItem item) async {
    try {
      if (userId.isEmpty) {
        throw Exception('Invalid user ID');
      }

      final cartRef = _firestore
          .collection(AppConstants.cartsCollection)
          .doc(userId);

      final cartDoc = await cartRef.get();

      if (cartDoc.exists) {
        // Update existing cart
        final cart = CartModel.fromJson(cartDoc.data()!);
        
        // Create unique key for product (considering variants)
        final itemKey = _createCartItemKey(item.productId, item.selectedColor, item.selectedSize);
        
        // Find existing item using the same key logic
        final existingItemIndex = cart.items.indexWhere(
          (cartItem) => _createCartItemKey(cartItem.productId, cartItem.selectedColor, cartItem.selectedSize) == itemKey,
        );

        List<CartItem> updatedItems = [...cart.items];

        if (existingItemIndex != -1) {
          // Update quantity of existing item
          final existingItem = updatedItems[existingItemIndex];
          updatedItems[existingItemIndex] = existingItem.copyWith(
            quantity: existingItem.quantity + item.quantity,
            addedAt: DateTime.now(), // Update timestamp
          );
        } else {
          // Add new item with unique ID
          updatedItems.add(item.copyWith(
            id: itemKey, // Use the same key logic for ID
          ));
        }

        await cartRef.update({
          'items': updatedItems.map((e) => e.toJson()).toList(),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      } else {
        // Create new cart
        final newItem = item.copyWith(
          id: _createCartItemKey(item.productId, item.selectedColor, item.selectedSize),
        );
        
        final cart = CartModel(
          id: userId,
          userId: userId,
          items: [newItem],
          createdAt: DateTime.now(),
        );

        await cartRef.set(cart.toJson());
      }
    } catch (e) {
      print('🔥 Error adding item to cart: $e');
      throw Exception('Failed to add item to cart: ${e.toString()}');
    }
  }

  /// Create unique key for cart item (prevents duplicates)
  String _createCartItemKey(String productId, String? selectedColor, String? selectedSize) {
    final colorKey = selectedColor ?? 'no-color';
    final sizeKey = selectedSize ?? 'no-size';
    return '${productId}_${colorKey}_$sizeKey';
  }

  /// Update cart item quantity
  Future<void> updateCartItemQuantity(
    String userId,
    String itemId,
    int quantity,
  ) async {
    try {
      final cartRef = _firestore
          .collection(AppConstants.cartsCollection)
          .doc(userId);

      final cartDoc = await cartRef.get();

      if (cartDoc.exists) {
        final cart = CartModel.fromJson(cartDoc.data()!);
        final updatedItems = cart.items.map((item) {
          if (item.id == itemId) {
            return item.copyWith(quantity: quantity);
          }
          return item;
        }).toList();

        await cartRef.update({
          'items': updatedItems.map((e) => e.toJson()).toList(),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      throw Exception('Failed to update cart item: ${e.toString()}');
    }
  }

  /// Remove item from cart
  Future<void> removeFromCart(String userId, String itemId) async {
    try {
      final cartRef = _firestore
          .collection(AppConstants.cartsCollection)
          .doc(userId);

      final cartDoc = await cartRef.get();

      if (cartDoc.exists) {
        final cart = CartModel.fromJson(cartDoc.data()!);
        final updatedItems = cart.items.where((item) => item.id != itemId).toList();

        await cartRef.update({
          'items': updatedItems.map((e) => e.toJson()).toList(),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      throw Exception('Failed to remove item from cart: ${e.toString()}');
    }
  }

  /// Get user cart
  Future<CartModel?> getCart(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.cartsCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return CartModel.fromJson(doc.data()!);
      }
    } catch (e) {
      throw Exception('Failed to get cart: ${e.toString()}');
    }
    return null;
  }

  /// Clear cart
  Future<void> clearCart(String userId) async {
    try {
      await _firestore
          .collection(AppConstants.cartsCollection)
          .doc(userId)
          .update({
        'items': [],
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to clear cart: ${e.toString()}');
    }
  }

  /// Get product recommendations based on cart items
  Future<List<ProductModel>> getCartRecommendations(String userId, {int limit = 6}) async {
    try {
      final cart = await getCart(userId);
      if (cart == null || cart.items.isEmpty) {
        return getPopularProducts(limit: limit);
      }

      // Get categories from cart items
      final cartCategories = cart.items
          .map((item) => item.product.category)
          .toSet()
          .toList();

      // Get product IDs already in cart to exclude them
      final cartProductIds = cart.items
          .map((item) => item.productId)
          .toSet();

      List<ProductModel> recommendations = [];

      // Strategy 1: Same category products
      for (final category in cartCategories) {
        final categoryProducts = await _getProductsByCategory(
          category, 
          limit: 4,
          excludeIds: cartProductIds,
        );
        recommendations.addAll(categoryProducts);
      }

      // Strategy 2: Frequently bought together
      final frequentlyBought = await _getFrequentlyBoughtTogether(
        cartProductIds.toList(),
        limit: 3,
        excludeIds: cartProductIds,
      );
      recommendations.addAll(frequentlyBought);

      // Strategy 3: Popular products if we don't have enough
      if (recommendations.length < limit) {
        final popular = await getPopularProducts(
          limit: limit - recommendations.length,
          excludeIds: cartProductIds,
        );
        recommendations.addAll(popular);
      }

      // Remove duplicates and limit results
      final uniqueRecommendations = <String, ProductModel>{};
      for (final product in recommendations) {
        if (!uniqueRecommendations.containsKey(product.id)) {
          uniqueRecommendations[product.id] = product;
        }
      }

      return uniqueRecommendations.values.take(limit).toList();
    } catch (e) {
      // Fallback to popular products
      return getPopularProducts(limit: limit);
    }
  }

  /// Get products by category (for recommendations)
  Future<List<ProductModel>> _getProductsByCategory(
    String category, {
    int limit = 4,
    Set<String>? excludeIds,
  }) async {
    try {
      Query query = _firestore
          .collection(AppConstants.productsCollection)
          .where('category', isEqualTo: category)
          .where('isApproved', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit * 2); // Get more to filter out exclusions

      final querySnapshot = await query.get();
      final products = querySnapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data() as Map<String, dynamic>))
          .where((product) => excludeIds?.contains(product.id) != true)
          .take(limit)
          .toList();

      return products;
    } catch (e) {
      return [];
    }
  }

  /// Get frequently bought together products
  Future<List<ProductModel>> _getFrequentlyBoughtTogether(
    List<String> productIds, {
    int limit = 3,
    Set<String>? excludeIds,
  }) async {
    try {
      // Query orders that contain any of the cart products
      final ordersQuery = await _firestore
          .collection(AppConstants.ordersCollection)
          .where('status', isEqualTo: 'delivered')
          .limit(100) // Sample recent orders
          .get();

      // Count frequency of products bought together
      final Map<String, int> productFrequency = {};

      for (final orderDoc in ordersQuery.docs) {
        try {
          final order = OrderModel.fromJson(orderDoc.data());
          final orderProductIds = order.items.map((item) => item.product.id).toSet();
          
          // If this order contains any of our cart products
          if (productIds.any((id) => orderProductIds.contains(id))) {
            // Count other products in this order
            for (final productId in orderProductIds) {
              if (!productIds.contains(productId) && excludeIds?.contains(productId) != true) {
                productFrequency[productId] = (productFrequency[productId] ?? 0) + 1;
              }
            }
          }
        } catch (e) {
          // Skip invalid order documents
          continue;
        }
      }

      // Get top products by frequency
      final sortedProducts = productFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topProductIds = sortedProducts
          .take(limit)
          .map((entry) => entry.key)
          .toList();

      // Fetch full product details
      final List<ProductModel> products = [];
      for (final productId in topProductIds) {
        final product = await getProduct(productId);
        if (product != null) {
          products.add(product);
        }
      }

      return products;
    } catch (e) {
      return [];
    }
  }

  /// Get popular products (fallback recommendation)
  Future<List<ProductModel>> getPopularProducts({
    int limit = 6,
    Set<String>? excludeIds,
  }) async {
    try {
      Query query = _firestore
          .collection(AppConstants.productsCollection)
          .where('isApproved', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit * 2); // Get more to filter exclusions

      final querySnapshot = await query.get();
      final products = querySnapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data() as Map<String, dynamic>))
          .where((product) => excludeIds?.contains(product.id) != true)
          .take(limit)
          .toList();

      return products;
    } catch (e) {
      return [];
    }
  }

  /// Get recently viewed products for user (if tracking is implemented)
  Future<List<ProductModel>> getRecentlyViewedProducts(
    String userId, {
    int limit = 4,
    Set<String>? excludeIds,
  }) async {
    try {
      // This would require implementing user activity tracking
      // For now, return popular products as fallback
      return getPopularProducts(limit: limit, excludeIds: excludeIds);
    } catch (e) {
      return [];
    }
  }

  /// Track product view (for recommendation engine)
  Future<void> trackProductView(String userId, String productId) async {
    try {
      await _firestore
          .collection('user_activity')
          .doc(userId)
          .collection('viewed_products')
          .doc(productId)
          .set({
        'productId': productId,
        'viewedAt': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));
    } catch (e) {
      // Fail silently for tracking
    }
  }

  // ORDER OPERATIONS

  /// Create a new order
  Future<String> createOrder(OrderModel order) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.ordersCollection)
          .add(order.toJson());

      // Update order with the generated ID
      await docRef.update({'id': docRef.id});

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create order: ${e.toString()}');
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(
    String orderId,
    OrderStatus status, {
    String? notes,
  }) async {
    try {
      final updateData = {
        'status': status.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (status == OrderStatus.delivered) {
        updateData['deliveredAt'] = Timestamp.fromDate(DateTime.now());
      }

      if (notes != null) {
        updateData['notes'] = notes;
      }

      await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update order status: ${e.toString()}');
    }
  }

  /// Add order tracking
  Future<void> addOrderTracking(String orderId, OrderTracking tracking) async {
    try {
      await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .update({
        'tracking': FieldValue.arrayUnion([tracking.toJson()]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to add order tracking: ${e.toString()}');
    }
  }

  /// Get order by ID
  Future<OrderModel?> getOrder(String orderId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .get();

      if (doc.exists) {
        return OrderModel.fromJson(doc.data()!);
      }
    } catch (e) {
      throw Exception('Failed to get order: ${e.toString()}');
    }
    return null;
  }

  /// Get user orders with fallback for missing index
  Future<List<OrderModel>> getUserOrders(String userId) async {
    try {
      // Try optimized query first (requires composite index)
      final querySnapshot = await _firestore
          .collection(AppConstants.ordersCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => OrderModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      // Check if error is due to missing index
      if (e.toString().contains('failed-precondition') || 
          e.toString().contains('requires an index')) {
        print('Using fallback query for getUserOrders - composite index not available');
        return _getUserOrdersFallback(userId);
      }
      throw Exception('Failed to get user orders: ${e.toString()}');
    }
  }

  /// Fallback method for getting user orders without composite index
  Future<List<OrderModel>> _getUserOrdersFallback(String userId) async {
    try {
      // Simple query without orderBy to avoid index requirement
      final querySnapshot = await _firestore
          .collection(AppConstants.ordersCollection)
          .where('userId', isEqualTo: userId)
          .get();

      // Convert to OrderModel and sort in memory
      final orders = querySnapshot.docs
          .map((doc) => OrderModel.fromJson(doc.data()))
          .toList();

      // Sort by createdAt in descending order (newest first)
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return orders;
    } catch (e) {
      throw Exception('Failed to get user orders (fallback): ${e.toString()}');
    }
  }

  /// Get all orders (for admin)
  Future<List<OrderModel>> getAllOrders({
    OrderStatus? status,
    int limit = AppConstants.defaultPageSize,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore.collection(AppConstants.ordersCollection);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      query = query.orderBy('createdAt', descending: true);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => OrderModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get orders: ${e.toString()}');
    }
  }

  // ANALYTICS AND REPORTING

  /// Get sales analytics for vendor
  Future<Map<String, dynamic>> getVendorAnalytics(String vendorId) async {
    try {
      final ordersQuery = await _firestore
          .collection(AppConstants.ordersCollection)
          .get();

      final productsQuery = await _firestore
          .collection(AppConstants.productsCollection)
          .where('vendorId', isEqualTo: vendorId)
          .get();

      double totalSales = 0;
      int totalOrders = 0;
      int totalProducts = productsQuery.docs.length;
      double totalRating = 0;
      int totalReviews = 0;

      // Calculate sales and orders
      for (final doc in ordersQuery.docs) {
        final order = OrderModel.fromJson(doc.data());
        final vendorItems = order.items.where((item) => item.product.vendorId == vendorId).toList();
        
        if (vendorItems.isNotEmpty && order.status == OrderStatus.delivered) {
          final vendorTotal = vendorItems.fold<double>(
            0, (sum, item) => sum + (item.product.price * item.quantity));
          totalSales += vendorTotal;
          totalOrders++;
        }
      }

      // Calculate average rating
      for (final doc in productsQuery.docs) {
        final product = ProductModel.fromJson(doc.data());
        totalRating += product.rating * product.reviewCount;
        totalReviews += product.reviewCount;
      }

      final averageRating = totalReviews > 0 ? totalRating / totalReviews : 0.0;

      return {
        'totalSales': totalSales,
        'totalOrders': totalOrders,
        'totalProducts': totalProducts,
        'averageRating': averageRating,
        'averageOrderValue': totalOrders > 0 ? totalSales / totalOrders : 0,
      };
    } catch (e) {
      throw Exception('Failed to get vendor analytics: ${e.toString()}');
    }
  }

  /// Get admin analytics
  Future<Map<String, dynamic>> getAdminAnalytics() async {
    try {
      final ordersQuery = await _firestore
          .collection(AppConstants.ordersCollection)
          .get();

      final productsQuery = await _firestore
          .collection(AppConstants.productsCollection)
          .get();

      final usersQuery = await _firestore
          .collection(AppConstants.usersCollection)
          .get();

      double totalRevenue = 0;
      int totalOrders = 0;
      int pendingOrders = 0;
      int deliveredOrders = 0;

      for (final doc in ordersQuery.docs) {
        final order = OrderModel.fromJson(doc.data());
        totalOrders++;
        
        if (order.status == OrderStatus.delivered) {
          totalRevenue += order.totalAmount;
          deliveredOrders++;
        } else if (order.status == OrderStatus.pending) {
          pendingOrders++;
        }
      }

      return {
        'totalRevenue': totalRevenue,
        'totalOrders': totalOrders,
        'pendingOrders': pendingOrders,
        'deliveredOrders': deliveredOrders,
        'totalProducts': productsQuery.docs.length,
        'totalUsers': usersQuery.docs.length,
        'averageOrderValue': totalOrders > 0 ? totalRevenue / totalOrders : 0,
      };
    } catch (e) {
      throw Exception('Failed to get admin analytics: ${e.toString()}');
    }
  }

  // UTILITY METHODS

  /// Generate order number
  String generateOrderNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'ORD$timestamp';
  }

  /// Batch update products
  Future<void> batchUpdateProducts(List<Map<String, dynamic>> updates) async {
    try {
      final batch = _firestore.batch();

      for (final update in updates) {
        final docRef = _firestore
            .collection(AppConstants.productsCollection)
            .doc(update['id']);
        batch.update(docRef, update['data']);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch update products: ${e.toString()}');
    }
  }

  /// Get categories
  Future<List<String>> getCategories() async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .get();

      final categories = <String>{};
      
      for (final doc in querySnapshot.docs) {
        final product = ProductModel.fromJson(doc.data());
        categories.add(product.category);
      }

      return categories.toList()..sort();
    } catch (e) {
      throw Exception('Failed to get categories: ${e.toString()}');
    }
  }

  // VENDOR OPERATIONS

  /// Get vendor products
  Future<List<ProductModel>> getVendorProducts(String vendorId) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .where('vendorId', isEqualTo: vendorId)
          .get();

      final products = querySnapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data()))
          .toList();

      // Sort by creation date on client side (newest first)
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return products;
    } catch (e) {
      throw Exception('Failed to get vendor products: ${e.toString()}');
    }
  }

  /// Update product status (active/inactive)
  Future<void> updateProductStatus(String productId, bool isActive) async {
    try {
      await _firestore
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .update({
        'isActive': isActive,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update product status: ${e.toString()}');
    }
  }

  /// Get vendor orders
  Future<List<OrderModel>> getVendorOrders(String vendorId) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.ordersCollection)
          .orderBy('createdAt', descending: true)
          .get();

      // Filter orders that contain products from this vendor
      final vendorOrders = <OrderModel>[];
      
      for (final doc in querySnapshot.docs) {
        final order = OrderModel.fromJson(doc.data());
        final hasVendorItems = order.items.any((item) => item.product.vendorId == vendorId);
        
        if (hasVendorItems) {
          vendorOrders.add(order);
        }
      }

      return vendorOrders;
    } catch (e) {
      throw Exception('Failed to get vendor orders: ${e.toString()}');
    }
  }

  // DEMO ACCOUNT CREATION (FOR TESTING ONLY)

  /// Create demo accounts for testing
  Future<void> createDemoAccounts() async {
    try {
      final demoAccounts = [
        {
          'email': 'customer@demo.com',
          'name': 'Demo Customer',
          'role': UserRole.customer,
        },
        {
          'email': 'vendor@gmail.com',
          'name': 'Demo Vendor',
          'role': UserRole.vendor,
        },
        {
          'email': 'admin@demo.com',
          'name': 'Demo Admin',
          'role': UserRole.admin,
        },
      ];

      for (final account in demoAccounts) {
        // Check if account already exists
        final existingUser = await _firestore
            .collection(AppConstants.usersCollection)
            .where('email', isEqualTo: account['email'])
            .get();

        if (existingUser.docs.isEmpty) {
          // Create demo user document
          await _firestore
              .collection(AppConstants.usersCollection)
              .add({
            'email': account['email'],
            'name': account['name'],
            'role': (account['role'] as UserRole).name,
            'isVerified': true,
            'createdAt': Timestamp.fromDate(DateTime.now()),
            'lastLoginAt': Timestamp.fromDate(DateTime.now()),
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to create demo accounts: ${e.toString()}');
    }
  }

  // PRODUCT SECTIONS OPERATIONS

  /// Get product sections as a stream
  Stream<List<ProductSection>> getProductSectionsStream() {
    return _firestore
        .collection('product_sections')
        .orderBy('order')
        .snapshots()
        .asyncMap((snapshot) async {
      final sections = <ProductSection>[];
      
      for (final doc in snapshot.docs) {
        try {
          final sectionData = doc.data();
          final productIds = List<String>.from(sectionData['productIds'] ?? []);
          
          // Fetch products for this section
          final products = await _fetchProductsForSection(productIds);
          
          sections.add(ProductSection(
            id: doc.id,
            title: sectionData['title'] as String? ?? '',
            subtitle: sectionData['subtitle'] as String?,
            imageUrl: sectionData['imageUrl'] as String?,
            seeMoreText: sectionData['seeMoreText'] as String?,
            seeMoreRoute: sectionData['seeMoreRoute'] as String?,
            products: products,
            isActive: sectionData['isActive'] as bool? ?? true,
            order: sectionData['order'] as int? ?? 0,
            displayCount: sectionData['displayCount'] as int? ?? 4,
            createdAt: (sectionData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          ));
        } catch (e) {
          print('Error processing section ${doc.id}: $e');
          continue;
        }
      }
      
      return sections;
    });
  }

  /// Get product sections as a future
  Future<List<ProductSection>> getProductSections() async {
    final snapshot = await _firestore
        .collection('product_sections')
        .orderBy('order')
        .get();

    final sections = <ProductSection>[];
    
    for (final doc in snapshot.docs) {
      try {
        final sectionData = doc.data();
        final productIds = List<String>.from(sectionData['productIds'] ?? []);
        
        // Fetch products for this section
        final products = await _fetchProductsForSection(productIds);
        
        sections.add(ProductSection(
          id: doc.id,
          title: sectionData['title'] as String? ?? '',
          subtitle: sectionData['subtitle'] as String?,
          imageUrl: sectionData['imageUrl'] as String?,
          seeMoreText: sectionData['seeMoreText'] as String?,
          seeMoreRoute: sectionData['seeMoreRoute'] as String?,
          products: products,
          isActive: sectionData['isActive'] as bool? ?? true,
          order: sectionData['order'] as int? ?? 0,
          displayCount: sectionData['displayCount'] as int? ?? 4,
          createdAt: (sectionData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        ));
      } catch (e) {
        print('Error processing section ${doc.id}: $e');
        continue;
      }
    }
    
    return sections;
  }

  /// Helper method to fetch products for a section
  Future<List<ProductModel>> _fetchProductsForSection(List<String> productIds) async {
    if (productIds.isEmpty) return [];

    final products = <ProductModel>[];
    final chunks = productIds.take(10).toList();
    
    final snapshot = await _firestore
        .collection('products')
        .where(FieldPath.documentId, whereIn: chunks)
        .get();

    for (final doc in snapshot.docs) {
      try {
        final data = doc.data();
        if (data['isApproved'] == true && data['isActive'] == true) {
          products.add(ProductModel.fromMap(data, doc.id));
        }
      } catch (e) {
        print('Error processing product ${doc.id}: $e');
        continue;
      }
    }

    return products;
  }

  /// Create a new product section (admin only)
  Future<String> createProductSection(ProductSection section) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.productSectionsCollection)
          .add({
        'title': section.title,
        'subtitle': section.subtitle,
        'productIds': section.products.map((p) => p.id).toList(),
        'seeMoreText': section.seeMoreText,
        'seeMoreRoute': section.seeMoreRoute,
        'displayCount': section.displayCount,
        'imageUrl': section.imageUrl,
        'isActive': section.isActive,
        'order': section.order,
        'createdAt': Timestamp.fromDate(section.createdAt),
        'metadata': section.metadata,
      });
      
      // Update with generated ID
      await docRef.update({'id': docRef.id});
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create product section: ${e.toString()}');
    }
  }

  /// Update product section (admin only)
  Future<void> updateProductSection(String sectionId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(AppConstants.productSectionsCollection)
          .doc(sectionId)
          .update({
        ...data,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update product section: ${e.toString()}');
    }
  }

  /// Delete product section (admin only)
  Future<void> deleteProductSection(String sectionId) async {
    try {
      await _firestore
          .collection(AppConstants.productSectionsCollection)
          .doc(sectionId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete product section: ${e.toString()}');
    }
  }

  /// Create demo product sections for testing
  Future<void> createDemoProductSections() async {
    try {
      // Get some products for the demo sections
      final allProducts = await getProducts(limit: 50);
      final products = allProducts.where((p) => p.isApproved && p.isActive).toList();
      
      if (products.length < 8) {
        throw Exception('Not enough products to create demo sections. Please add at least 8 products first.');
      }

      final demoSections = [
        {
          'title': 'Appliances for your home | Up to 55% off',
          'subtitle': 'Best deals on home appliances',
          'productIds': products.take(4).map((p) => p.id).toList(),
          'seeMoreText': 'See more',
          'seeMoreRoute': '/home/category/appliances',
          'displayCount': 4,
          'order': 0,
          'isActive': true,
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'metadata': {
            'backgroundColor': '#ffffff',
            'textColor': '#000000',
          },
        },
        {
          'title': 'Starting ₹149 | Headphones',
          'subtitle': 'Premium audio experience',
          'productIds': products.skip(4).take(4).map((p) => p.id).toList(),
          'seeMoreText': 'See all offers',
          'seeMoreRoute': '/home/category/headphones',
          'displayCount': 4,
          'order': 1,
          'isActive': true,
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'metadata': {
            'backgroundColor': '#ffffff',
            'textColor': '#000000',
          },
        },
        {
          'title': 'Revamp your home in style',
          'subtitle': 'Beautiful home decor items',
          'productIds': products.skip(8).take(4).map((p) => p.id).toList(),
          'seeMoreText': 'Explore all',
          'seeMoreRoute': '/home/category/home-decor',
          'displayCount': 4,
          'order': 2,
          'isActive': true,
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'metadata': {
            'backgroundColor': '#ffffff',
            'textColor': '#000000',
          },
        },
        {
          'title': 'Fashion trends | Up to 60% off',
          'subtitle': 'Latest fashion collection',
          'productIds': products.skip(12).take(4).map((p) => p.id).toList(),
          'seeMoreText': 'Shop now',
          'seeMoreRoute': '/home/category/fashion',
          'displayCount': 4,
          'order': 3,
          'isActive': true,
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'metadata': {
            'backgroundColor': '#ffffff',
            'textColor': '#000000',
          },
        },
      ];

      for (final section in demoSections) {
        // Check if section already exists
        final existing = await _firestore
            .collection(AppConstants.productSectionsCollection)
            .where('title', isEqualTo: section['title'])
            .get();

        if (existing.docs.isEmpty) {
          await _firestore
              .collection(AppConstants.productSectionsCollection)
              .add(section);
        }
      }
    } catch (e) {
      throw Exception('Failed to create demo product sections: ${e.toString()}');
    }
  }

  /// Ensure data exists and is properly configured
  Future<Map<String, dynamic>> ensureDataExists() async {
    final result = <String, dynamic>{
      'hasProducts': false,
      'hasApprovedProducts': false,
      'hasSections': false,
      'hasValidSections': false,
      'productCount': 0,
      'approvedProductCount': 0,
      'sectionCount': 0,
      'validSectionCount': 0,
      'errors': <String>[],
      'fixes': <String>[],
    };

    try {
      // Check products
      final productsSnapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .get();
      
      result['productCount'] = productsSnapshot.docs.length;
      result['hasProducts'] = productsSnapshot.docs.isNotEmpty;

      int approvedCount = 0;
      final unapprovedProducts = <String>[];
      
      for (final doc in productsSnapshot.docs) {
        final data = doc.data();
        if (data['isApproved'] == true && data['isActive'] == true) {
          approvedCount++;
        } else {
          unapprovedProducts.add(doc.id);
        }
      }

      result['approvedProductCount'] = approvedCount;
      result['hasApprovedProducts'] = approvedCount > 0;

      // Create basic test data if no products exist at all
      if (result['productCount'] == 0) {
        await createBasicTestData();
        result['fixes'].add('Created basic test data (4 products + 1 section)');
        result['productCount'] = 4;
        result['approvedProductCount'] = 4;
        result['hasProducts'] = true;
        result['hasApprovedProducts'] = true;
      } 
      // Auto-approve products if needed (only if we don't have enough approved products)
      else if (unapprovedProducts.isNotEmpty && approvedCount < 4) {
        final productsToApprove = unapprovedProducts.take(8).toList();
        await _autoApproveProducts(productsToApprove);
        result['fixes'].add('Auto-approved ${productsToApprove.length} products');
        result['approvedProductCount'] = approvedCount + productsToApprove.length;
        result['hasApprovedProducts'] = true;
      }

      // Check sections
      final sectionsSnapshot = await _firestore
          .collection(AppConstants.productSectionsCollection)
          .get();
      
      result['sectionCount'] = sectionsSnapshot.docs.length;
      result['hasSections'] = sectionsSnapshot.docs.isNotEmpty;

      int validCount = 0;
      for (final doc in sectionsSnapshot.docs) {
        final data = doc.data();
        if (data['isActive'] == true && 
            data['productIds'] != null && 
            (data['productIds'] as List).isNotEmpty) {
          validCount++;
        }
      }

      result['validSectionCount'] = validCount;
      result['hasValidSections'] = validCount > 0;

      // Create demo data if needed (skip if we just created basic test data)
      if (!result['hasValidSections'] && result['hasApprovedProducts'] && result['productCount'] > 4) {
        try {
          await createDemoProductSections();
          result['fixes'].add('Created demo product sections');
          result['hasSections'] = true;
          result['hasValidSections'] = true;
          result['sectionCount'] = 4;
          result['validSectionCount'] = 4;
        } catch (e) {
          result['errors'].add('Failed to create demo sections: $e');
        }
      }
      
      // If we created basic test data, we already have a section
      if (result['productCount'] == 4 && result['fixes'].contains('Created basic test data (4 products + 1 section)')) {
        result['sectionCount'] = 1;
        result['validSectionCount'] = 1;
        result['hasSections'] = true;
        result['hasValidSections'] = true;
      }

    } catch (e) {
      result['errors'].add('Error checking data: $e');
    }

    return result;
  }

  /// Auto-approve products for demo purposes
  Future<void> _autoApproveProducts(List<String> productIds) async {
    try {
      final batch = _firestore.batch();
      
      for (final productId in productIds) {
        final docRef = _firestore
            .collection(AppConstants.productsCollection)
            .doc(productId);
        
        batch.update(docRef, {
          'isApproved': true,
          'isActive': true,
          'updatedAt': Timestamp.now(),
        });
      }
      
      await batch.commit();
      print('DEBUG: Auto-approved ${productIds.length} products');
    } catch (e) {
      print('ERROR: Failed to auto-approve products: $e');
      throw Exception('Failed to auto-approve products: $e');
    }
  }

  /// Check and fix data issues automatically
  Future<String> checkAndFixData() async {
    final buffer = StringBuffer();
    buffer.writeln('🔧 AUTO-FIX RESULTS:');
    buffer.writeln('─' * 50);
    
    try {
      final result = await ensureDataExists();
      
      if (result['hasValidSections']) {
        buffer.writeln('✅ Data is properly configured!');
        buffer.writeln('   • Products: ${result['approvedProductCount']}');
        buffer.writeln('   • Sections: ${result['validSectionCount']}');
      } else {
        buffer.writeln('🔧 Applied fixes:');
        for (final fix in result['fixes']) {
          buffer.writeln('   ✅ $fix');
        }
        
        if (result['errors'].isNotEmpty) {
          buffer.writeln('\n❌ Remaining issues:');
          for (final error in result['errors']) {
            buffer.writeln('   • $error');
          }
        }
      }
      
    } catch (e) {
      buffer.writeln('❌ Auto-fix failed: $e');
    }
    
    return buffer.toString();
  }

  /// Create basic test data if none exists
  Future<void> createBasicTestData() async {
    try {
      print('DEBUG: Creating basic test data...');
      
      // Create a few basic products
      final testProducts = [
        {
          'id': '', // Will be set by Firestore
          'name': 'Wireless Bluetooth Headphones',
          'description': 'High-quality wireless headphones with noise cancellation',
          'price': 2999.0,
          'originalPrice': 4999.0,
          'currency': 'INR',
          'category': 'Electronics',
          'subcategory': 'Audio',
          'brand': 'TechBrand',
          'sku': 'WBH001',
          'stockQuantity': 50,
          'tags': ['wireless', 'bluetooth', 'headphones', 'audio'],
          'imageUrls': ['https://via.placeholder.com/300x300?text=Headphones'],
          'thumbnailUrl': 'https://via.placeholder.com/150x150?text=Headphones',
          'specifications': {
            'Battery Life': '30 hours',
            'Connectivity': 'Bluetooth 5.0',
            'Color': 'Black'
          },
          'features': ['Noise Cancellation', 'Fast Charging', 'Lightweight'],
          'colors': ['Black', 'White', 'Blue'],
          'sizes': [],
          'vendorId': 'demo_vendor',
          'vendorName': 'Demo Electronics Store',
          'rating': 4.5,
          'reviewCount': 128,
          'isActive': true,
          'isApproved': true,
          'isFeatured': true,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'id': '',
          'name': 'Smartphone Case',
          'description': 'Protective case for smartphones with anti-shock design',
          'price': 499.0,
          'originalPrice': 799.0,
          'currency': 'INR',
          'category': 'Electronics',
          'subcategory': 'Accessories',
          'brand': 'ProtectBrand',
          'sku': 'SC001',
          'stockQuantity': 100,
          'tags': ['case', 'protection', 'smartphone', 'accessories'],
          'imageUrls': ['https://via.placeholder.com/300x300?text=Phone+Case'],
          'thumbnailUrl': 'https://via.placeholder.com/150x150?text=Phone+Case',
          'specifications': {
            'Material': 'TPU + PC',
            'Compatibility': 'Universal',
            'Color': 'Transparent'
          },
          'features': ['Anti-Shock', 'Transparent', 'Easy Installation'],
          'colors': ['Clear', 'Black', 'Blue'],
          'sizes': [],
          'vendorId': 'demo_vendor',
          'vendorName': 'Demo Electronics Store',
          'rating': 4.2,
          'reviewCount': 89,
          'isActive': true,
          'isApproved': true,
          'isFeatured': false,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'id': '',
          'name': 'Cotton T-Shirt',
          'description': 'Comfortable cotton t-shirt for everyday wear',
          'price': 799.0,
          'originalPrice': 1299.0,
          'currency': 'INR',
          'category': 'Fashion',
          'subcategory': 'Clothing',
          'brand': 'ComfortWear',
          'sku': 'CT001',
          'stockQuantity': 75,
          'tags': ['t-shirt', 'cotton', 'casual', 'fashion'],
          'imageUrls': ['https://via.placeholder.com/300x300?text=T-Shirt'],
          'thumbnailUrl': 'https://via.placeholder.com/150x150?text=T-Shirt',
          'specifications': {
            'Material': '100% Cotton',
            'Fit': 'Regular',
            'Fabric': 'Cotton'
          },
          'features': ['Breathable', 'Comfortable', 'Easy Care'],
          'colors': ['White', 'Black', 'Navy', 'Red'],
          'sizes': ['S', 'M', 'L', 'XL'],
          'vendorId': 'demo_vendor',
          'vendorName': 'Demo Fashion Store',
          'rating': 4.3,
          'reviewCount': 156,
          'isActive': true,
          'isApproved': true,
          'isFeatured': false,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'id': '',
          'name': 'Coffee Mug',
          'description': 'Ceramic coffee mug perfect for your morning coffee',
          'price': 299.0,
          'originalPrice': 499.0,
          'currency': 'INR',
          'category': 'Home & Kitchen',
          'subcategory': 'Drinkware',
          'brand': 'HomeBrand',
          'sku': 'CM001',
          'stockQuantity': 200,
          'tags': ['mug', 'coffee', 'ceramic', 'kitchen'],
          'imageUrls': ['https://via.placeholder.com/300x300?text=Coffee+Mug'],
          'thumbnailUrl': 'https://via.placeholder.com/150x150?text=Coffee+Mug',
          'specifications': {
            'Material': 'Ceramic',
            'Capacity': '300ml',
            'Color': 'White'
          },
          'features': ['Microwave Safe', 'Dishwasher Safe', 'Durable'],
          'colors': ['White', 'Black', 'Blue'],
          'sizes': [],
          'vendorId': 'demo_vendor',
          'vendorName': 'Demo Home Store',
          'rating': 4.1,
          'reviewCount': 67,
          'isActive': true,
          'isApproved': true,
          'isFeatured': false,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
      ];

      final productIds = <String>[];
      
      // Add each product to Firestore
      for (final productData in testProducts) {
        final docRef = await _firestore
            .collection(AppConstants.productsCollection)
            .add(productData);
        
        // Update with the generated ID
        await docRef.update({'id': docRef.id});
        productIds.add(docRef.id);
        
        print('DEBUG: Created test product: ${productData['name']} with ID: ${docRef.id}');
      }

      print('DEBUG: Created ${productIds.length} test products');
      
      // Now create a test section with these products
      final testSection = {
        'title': 'Featured Products | Great Deals',
        'subtitle': 'Hand-picked products just for you',
        'productIds': productIds,
        'seeMoreText': 'See all products',
        'seeMoreRoute': '/home/category/featured',
        'displayCount': 4,
        'order': 0,
        'isActive': true,
        'createdAt': Timestamp.now(),
        'metadata': {
          'backgroundColor': '#ffffff',
          'textColor': '#000000',
        },
      };

      final sectionRef = await _firestore
          .collection(AppConstants.productSectionsCollection)
          .add(testSection);
      
      await sectionRef.update({'id': sectionRef.id});
      
      print('DEBUG: Created test section: ${testSection['title']} with ID: ${sectionRef.id}');
      
    } catch (e) {
      print('ERROR: Failed to create basic test data: $e');
      throw Exception('Failed to create basic test data: $e');
    }
  }

  /// Get active banners stream
  Stream<List<BannerModel>> getBanners() {
    return _firestore
        .collection('banners')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BannerModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get categories stream for homepage
  Stream<List<CategoryModel>> getCategoriesStream() {
    return _firestore
        .collection(AppConstants.categoriesCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CategoryModel.fromJson({...doc.data(), 'id': doc.id}))
            .where((category) => category.isActive)
            .toList()
            ..sort((a, b) => a.order.compareTo(b.order)));
  }

  /// Get deals stream for homepage
  Stream<List<DealModel>> getDealsStream() {
    return _firestore
        .collection('deals')
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DealModel.fromJson({...doc.data(), 'id': doc.id}))
            .where((deal) => deal.isActive && deal.isCurrentlyActive)
            .toList()
            ..sort((a, b) => b.startDate.compareTo(a.startDate))
            ..take(20).toList());
  }

  /// Get search suggestions based on query
  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      final lowerQuery = query.toLowerCase();
      
      // Search in product names
      final productQuery = await _firestore
          .collection(AppConstants.productsCollection)
          .where('name', isGreaterThanOrEqualTo: lowerQuery)
          .where('name', isLessThan: lowerQuery + 'z')
          .limit(10)
          .get();
      
      final productSuggestions = productQuery.docs
          .map((doc) => doc.data()['name'] as String)
          .toList();
      
      // Search in categories
      final categoryQuery = await _firestore
          .collection(AppConstants.categoriesCollection)
          .where('name', isGreaterThanOrEqualTo: lowerQuery)
          .where('name', isLessThan: lowerQuery + 'z')
          .limit(5)
          .get();
      
      final categorySuggestions = categoryQuery.docs
          .map((doc) => doc.data()['name'] as String)
          .toList();
      
      // Combine and return unique suggestions
      final allSuggestions = [...productSuggestions, ...categorySuggestions];
      return allSuggestions.toSet().take(10).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get cart item count stream for a user
  Stream<int> getCartItemCountStream(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection('cart')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Search products by query string and optional category
  Future<List<ProductModel>> searchProducts({
    required String query,
    String? category,
  }) async {
    try {
      Query productsQuery = _firestore
          .collection(AppConstants.productsCollection)
          .where('isApproved', isEqualTo: true);

      // Add category filter if specified
      if (category != null && category != 'All') {
        productsQuery = productsQuery.where('category', isEqualTo: category);
      }

      // Convert query to lowercase for case-insensitive search
      final searchQuery = query.toLowerCase();

      // Get all products that match the filters
      final querySnapshot = await productsQuery.get();

      // Filter and map products based on search query
      return querySnapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data() as Map<String, dynamic>))
          .where((product) {
            final name = product.name.toLowerCase();
            final description = product.description.toLowerCase();
            
            // Check if product name or description contains the search query
            return name.contains(searchQuery) || 
                   description.contains(searchQuery);
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  /// Create comprehensive demo data for testing the dynamic homepage
  Future<void> createDemoHomeData() async {
    try {
      print('DEBUG: Starting comprehensive demo data creation...');
      
      // 1. Create demo banners
      await _createDemoBanners();
      
      // 2. Create demo categories
      await _createDemoCategories();
      
      // 3. Create demo deals
      await _createDemoDeals();
      
      // 4. Create demo products and sections (existing functionality)
      await createBasicTestData();
      
      print('DEBUG: ✅ All demo data created successfully!');
    } catch (e) {
      print('ERROR: Failed to create demo home data: $e');
      throw Exception('Failed to create demo home data: $e');
    }
  }

  /// Create demo banners
  Future<void> _createDemoBanners() async {
    final demoBanners = [
      {
        'title': 'Summer Sale 2024',
        'description': 'Up to 70% off on electronics, fashion & more',
        'imageUrl': 'https://via.placeholder.com/1200x400/FF6B35/FFFFFF?text=Summer+Sale+2024',
        'actionText': 'Shop Now',
        'actionRoute': '/home/deals',
        'isActive': true,
        'order': 0,
        'startDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
        'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        'backgroundColor': '#FF6B35',
        'textColor': '#FFFFFF',
        'metadata': {
          'priority': 'high',
          'category': 'promotion'
        }
      },
      {
        'title': 'Free Shipping Weekend',
        'description': 'Free delivery on orders above ₹499',
        'imageUrl': 'https://via.placeholder.com/1200x400/2ECC71/FFFFFF?text=Free+Shipping',
        'actionText': 'Explore',
        'actionRoute': '/home/products',
        'isActive': true,
        'order': 1,
        'startDate': Timestamp.fromDate(DateTime.now()),
        'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))),
        'backgroundColor': '#2ECC71',
        'textColor': '#FFFFFF',
        'metadata': {
          'priority': 'medium',
          'category': 'shipping'
        }
      },
      {
        'title': 'New Arrivals',
        'description': 'Discover the latest trends in fashion',
        'imageUrl': 'https://via.placeholder.com/1200x400/9B59B6/FFFFFF?text=New+Arrivals',
        'actionText': 'Browse',
        'actionRoute': '/home/category/fashion',
        'isActive': true,
        'order': 2,
        'startDate': Timestamp.fromDate(DateTime.now()),
        'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 15))),
        'backgroundColor': '#9B59B6',
        'textColor': '#FFFFFF',
        'metadata': {
          'priority': 'low',
          'category': 'new'
        }
      }
    ];

    for (final banner in demoBanners) {
      final docRef = await _firestore
          .collection(AppConstants.bannersCollection)
          .add(banner);
      await docRef.update({'id': docRef.id});
      print('DEBUG: Created banner: ${banner['title']}');
    }
  }

  /// Create demo categories  
  Future<void> _createDemoCategories() async {
    final demoCategories = [
      {
        'name': 'Electronics',
        'description': 'Latest gadgets and electronics',
        'iconData': 'phone_android',
        'imageUrl': 'https://via.placeholder.com/200x200/3498DB/FFFFFF?text=Electronics',
        'color': '#3498DB',
        'subcategories': ['Smartphones', 'Laptops', 'Headphones', 'Smart Watches'],
        'isActive': true,
        'order': 0,
        'productCount': 150,
        'metadata': {
          'featured': true,
          'trending': true
        }
      },
      {
        'name': 'Fashion',
        'description': 'Trendy clothing and accessories',
        'iconData': 'checkroom',
        'imageUrl': 'https://via.placeholder.com/200x200/E74C3C/FFFFFF?text=Fashion',
        'color': '#E74C3C',
        'subcategories': ['Men\'s Clothing', 'Women\'s Clothing', 'Shoes', 'Accessories'],
        'isActive': true,
        'order': 1,
        'productCount': 89,
        'metadata': {
          'featured': true,
          'seasonal': true
        }
      },
      {
        'name': 'Home & Kitchen',
        'description': 'Everything for your home',
        'iconData': 'home',
        'imageUrl': 'https://via.placeholder.com/200x200/27AE60/FFFFFF?text=Home',
        'color': '#27AE60',
        'subcategories': ['Furniture', 'Kitchen Appliances', 'Home Decor', 'Garden'],
        'isActive': true,
        'order': 2,
        'productCount': 67,
        'metadata': {
          'featured': false,
          'essential': true
        }
      },
      {
        'name': 'Books',
        'description': 'Books, e-books and audiobooks',
        'iconData': 'menu_book',
        'imageUrl': 'https://via.placeholder.com/200x200/F39C12/FFFFFF?text=Books',
        'color': '#F39C12',
        'subcategories': ['Fiction', 'Non-Fiction', 'Educational', 'Comics'],
        'isActive': true,
        'order': 3,
        'productCount': 234,
        'metadata': {
          'featured': false,
          'knowledge': true
        }
      },
      {
        'name': 'Sports & Fitness',
        'description': 'Sports equipment and fitness gear',
        'iconData': 'fitness_center',
        'imageUrl': 'https://via.placeholder.com/200x200/9B59B6/FFFFFF?text=Sports',
        'color': '#9B59B6',
        'subcategories': ['Gym Equipment', 'Outdoor Sports', 'Yoga & Fitness', 'Team Sports'],
        'isActive': true,
        'order': 4,
        'productCount': 45,
        'metadata': {
          'featured': false,
          'health': true
        }
      }
    ];

    for (final category in demoCategories) {
      final docRef = await _firestore
          .collection(AppConstants.categoriesCollection)
          .add(category);
      await docRef.update({'id': docRef.id});
      print('DEBUG: Created category: ${category['name']}');
    }
  }

  /// Create demo deals
  Future<void> _createDemoDeals() async {
    final demoDeals = [
      {
        'title': 'Flash Sale: Smartphones',
        'description': 'Up to 40% off on premium smartphones',
        'imageUrl': 'https://via.placeholder.com/300x200/E74C3C/FFFFFF?text=Smartphone+Deal',
        'discountPercentage': 40.0,
        'originalPrice': 25000.0,
        'salePrice': 15000.0,
        'productId': 'phone_deal_001',
        'category': 'Electronics',
        'isActive': true,
        'startDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
        'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 2))),
        'stockLimit': 50,
        'soldCount': 23,
        'metadata': {
          'priority': 'high',
          'badge': 'Limited Time'
        }
      },
      {
        'title': 'Fashion Week Special',
        'description': 'Designer clothing at unbeatable prices',
        'imageUrl': 'https://via.placeholder.com/300x200/9B59B6/FFFFFF?text=Fashion+Deal',
        'discountPercentage': 60.0,
        'originalPrice': 2999.0,
        'salePrice': 1199.0,
        'productId': 'fashion_deal_001',
        'category': 'Fashion',
        'isActive': true,
        'startDate': Timestamp.fromDate(DateTime.now()),
        'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 5))),
        'stockLimit': 100,
        'soldCount': 67,
        'metadata': {
          'priority': 'medium',
          'badge': 'Best Seller'
        }
      },
      {
        'title': 'Home Makeover Sale',
        'description': 'Transform your home with our collection',
        'imageUrl': 'https://via.placeholder.com/300x200/27AE60/FFFFFF?text=Home+Deal',
        'discountPercentage': 35.0,
        'originalPrice': 4999.0,
        'salePrice': 3249.0,
        'productId': 'home_deal_001',
        'category': 'Home & Kitchen',
        'isActive': true,
        'startDate': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 1))),
        'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
        'stockLimit': 75,
        'soldCount': 12,
        'metadata': {
          'priority': 'low',
          'badge': 'New Arrival'
        }
      }
    ];

    for (final deal in demoDeals) {
      final docRef = await _firestore
          .collection('deals')
          .add(deal);
      await docRef.update({'id': docRef.id});
      print('DEBUG: Created deal: ${deal['title']}');
    }
  }
} 