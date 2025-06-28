import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/cart_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../constants/app_constants.dart';

/// Service class for handling Firestore database operations
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // PRODUCT OPERATIONS

  /// Add a new product
  Future<String> addProduct(ProductModel product) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.productsCollection)
          .add(product.toJson());
      
      // Update product with the generated ID
      await docRef.update({'id': docRef.id});
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add product: ${e.toString()}');
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
  }) async {
    try {
      Query query = _firestore.collection(AppConstants.productsCollection);

      // Add filters
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      if (isApproved != null) {
        query = query.where('isApproved', isEqualTo: isApproved);
      }

      if (vendorId != null && vendorId.isNotEmpty) {
        query = query.where('vendorId', isEqualTo: vendorId);
      }

      // Add search functionality (basic text search)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query
            .where('name', isGreaterThanOrEqualTo: searchQuery)
            .where('name', isLessThan: searchQuery + 'z');
      }

      // Order by creation date
      query = query.orderBy('createdAt', descending: true);

      // Add pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get products: ${e.toString()}');
    }
  }

  /// Get products by category
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .where('category', isEqualTo: category)
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get products by category: ${e.toString()}');
    }
  }

  /// Search products
  Future<List<ProductModel>> searchProducts(String searchQuery) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .get();

      // Filter results based on search query (client-side filtering)
      final products = querySnapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data()))
          .where((product) =>
              product.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              product.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
              product.tags.any((tag) => tag.toLowerCase().contains(searchQuery.toLowerCase())))
          .toList();

      return products;
    } catch (e) {
      throw Exception('Failed to search products: ${e.toString()}');
    }
  }

  // CART OPERATIONS

  /// Add item to cart
  Future<void> addToCart(String userId, CartItem item) async {
    try {
      final cartRef = _firestore
          .collection(AppConstants.cartsCollection)
          .doc(userId);

      final cartDoc = await cartRef.get();

      if (cartDoc.exists) {
        // Update existing cart
        final cart = CartModel.fromJson(cartDoc.data()!);
        final existingItemIndex = cart.items.indexWhere(
          (cartItem) => cartItem.productId == item.productId &&
              cartItem.selectedColor == item.selectedColor &&
              cartItem.selectedSize == item.selectedSize,
        );

        List<CartItem> updatedItems = [...cart.items];

        if (existingItemIndex != -1) {
          // Update quantity of existing item
          updatedItems[existingItemIndex] = updatedItems[existingItemIndex]
              .copyWith(quantity: updatedItems[existingItemIndex].quantity + item.quantity);
        } else {
          // Add new item
          updatedItems.add(item);
        }

        await cartRef.update({
          'items': updatedItems.map((e) => e.toJson()).toList(),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      } else {
        // Create new cart
        final cart = CartModel(
          id: userId,
          userId: userId,
          items: [item],
          createdAt: DateTime.now(),
        );

        await cartRef.set(cart.toJson());
      }
    } catch (e) {
      throw Exception('Failed to add item to cart: ${e.toString()}');
    }
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

  /// Get user orders
  Future<List<OrderModel>> getUserOrders(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.ordersCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => OrderModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user orders: ${e.toString()}');
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
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data()))
          .toList();
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
} 