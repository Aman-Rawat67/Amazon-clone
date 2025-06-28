import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_model.dart';

/// Model class for individual cart items
class CartItem {
  final String id;
  final String productId;
  final ProductModel product;
  final int quantity;
  final String? selectedColor;
  final String? selectedSize;
  final DateTime addedAt;
  
  const CartItem({
    required this.id,
    required this.productId,
    required this.product,
    required this.quantity,
    this.selectedColor,
    this.selectedSize,
    required this.addedAt,
  });

  /// Creates a CartItem from JSON data
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      productId: json['productId'] as String,
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      selectedColor: json['selectedColor'] as String?,
      selectedSize: json['selectedSize'] as String?,
      addedAt: (json['addedAt'] as Timestamp).toDate(),
    );
  }

  /// Converts CartItem to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'product': product.toJson(),
      'quantity': quantity,
      'selectedColor': selectedColor,
      'selectedSize': selectedSize,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }

  /// Creates a copy of CartItem with updated fields
  CartItem copyWith({
    String? id,
    String? productId,
    ProductModel? product,
    int? quantity,
    String? selectedColor,
    String? selectedSize,
    DateTime? addedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedColor: selectedColor ?? this.selectedColor,
      selectedSize: selectedSize ?? this.selectedSize,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  /// Calculate total price for this cart item
  double get totalPrice => product.price * quantity;

  /// Get product name
  String get productName => product.name;

  /// Get product price
  double get price => product.price;

  /// Get product image URL
  String? get imageUrl => product.imageUrls.isNotEmpty ? product.imageUrls.first : null;

  @override
  String toString() {
    return 'CartItem(id: $id, productId: $productId, quantity: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is CartItem &&
        other.id == id &&
        other.productId == productId &&
        other.quantity == quantity;
  }

  @override
  int get hashCode {
    return id.hashCode ^ productId.hashCode ^ quantity.hashCode;
  }
}

/// Model class for shopping cart
class CartModel {
  final String id;
  final String userId;
  final List<CartItem> items;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  const CartModel({
    required this.id,
    required this.userId,
    this.items = const [],
    required this.createdAt,
    this.updatedAt,
  });

  /// Creates a CartModel from JSON data
  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Converts CartModel to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null 
          ? Timestamp.fromDate(updatedAt!) 
          : null,
    };
  }

  /// Creates a copy of CartModel with updated fields
  CartModel copyWith({
    String? id,
    String? userId,
    List<CartItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CartModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculate total number of items in cart
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  /// Calculate total price of all items in cart (bulletproof calculation)
  double get totalPrice {
    if (items.isEmpty) return 0.0;
    
    return items.fold(0.0, (sum, item) {
      final itemTotal = item.product.price * item.quantity;
      return sum + itemTotal;
    });
  }

  /// Check if cart is empty
  bool get isEmpty => items.isEmpty;

  /// Check if cart has items
  bool get isNotEmpty => items.isNotEmpty;

  /// Get unique product count
  int get uniqueProductCount => items.length;

  /// Calculate subtotal (same as totalPrice for now)
  double get subtotal => totalPrice;

  /// Calculate shipping fee with proper threshold
  double get shipping {
    const double freeShippingThreshold = 100.0;
    const double standardShippingCost = 10.0;
    
    return totalPrice >= freeShippingThreshold ? 0.0 : standardShippingCost;
  }

  /// Calculate total including shipping (robust calculation)
  double get total {
    final cartSubtotal = subtotal;
    final shippingCost = shipping;
    return cartSubtotal + shippingCost;
  }

  /// Get cart summary for debugging
  Map<String, dynamic> get summary => {
    'totalItems': totalItems,
    'uniqueProducts': uniqueProductCount,
    'subtotal': subtotal,
    'shipping': shipping,
    'total': total,
    'isEmpty': isEmpty,
  };

  @override
  String toString() {
    return 'CartModel(id: $id, userId: $userId, itemCount: ${items.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is CartModel &&
        other.id == id &&
        other.userId == userId &&
        other.items.length == items.length;
  }

  @override
  int get hashCode {
    return id.hashCode ^ userId.hashCode ^ items.length.hashCode;
  }
} 