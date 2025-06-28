import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_model.dart';

/// Model class representing a product section on the homepage
class ProductSection {
  final String id;
  final String title;
  final String? subtitle;
  final List<ProductModel> products;
  final String? seeMoreText;
  final String? seeMoreRoute;
  final int displayCount; // How many products to show in the grid
  final String? imageUrl; // Optional section banner image
  final bool isActive;
  final int order; // For ordering sections on the homepage
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata; // Additional data like colors, styling

  const ProductSection({
    required this.id,
    required this.title,
    this.subtitle,
    this.products = const [],
    this.seeMoreText,
    this.seeMoreRoute,
    this.displayCount = 4,
    this.imageUrl,
    this.isActive = true,
    this.order = 0,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  /// Creates a ProductSection from JSON data
  factory ProductSection.fromJson(Map<String, dynamic> json) {
    return ProductSection(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      products: (json['products'] as List<dynamic>?)
              ?.map((productJson) => ProductModel.fromJson(productJson as Map<String, dynamic>))
              .toList() ??
          [],
      seeMoreText: json['seeMoreText'] as String?,
      seeMoreRoute: json['seeMoreRoute'] as String?,
      displayCount: json['displayCount'] as int? ?? 4,
      imageUrl: json['imageUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      order: json['order'] as int? ?? 0,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Converts ProductSection to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'products': products.map((product) => product.toJson()).toList(),
      'seeMoreText': seeMoreText,
      'seeMoreRoute': seeMoreRoute,
      'displayCount': displayCount,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null 
          ? Timestamp.fromDate(updatedAt!) 
          : null,
      'metadata': metadata,
    };
  }

  /// Creates a copy of ProductSection with updated fields
  ProductSection copyWith({
    String? id,
    String? title,
    String? subtitle,
    List<ProductModel>? products,
    String? seeMoreText,
    String? seeMoreRoute,
    int? displayCount,
    String? imageUrl,
    bool? isActive,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ProductSection(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      products: products ?? this.products,
      seeMoreText: seeMoreText ?? this.seeMoreText,
      seeMoreRoute: seeMoreRoute ?? this.seeMoreRoute,
      displayCount: displayCount ?? this.displayCount,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get products to display (limited by displayCount)
  List<ProductModel> get displayProducts {
    return products.take(displayCount).toList();
  }

  /// Check if section has products
  bool get hasProducts => products.isNotEmpty;

  /// Get section background color from metadata
  String? get backgroundColor => metadata?['backgroundColor'] as String?;

  /// Get section text color from metadata
  String? get textColor => metadata?['textColor'] as String?;

  @override
  String toString() {
    return 'ProductSection(id: $id, title: $title, productsCount: ${products.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ProductSection &&
        other.id == id &&
        other.title == title &&
        other.order == order;
  }

  @override
  int get hashCode => Object.hash(id, title, order);
} 