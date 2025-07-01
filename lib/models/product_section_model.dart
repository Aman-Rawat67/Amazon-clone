import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

/// Model class representing a product section on the homepage
class ProductSection {
  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? seeMoreText;
  final String? seeMoreRoute;
  final List<ProductModel> products;
  final bool isActive;
  final int order;
  final int displayCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata; // Additional data like colors, styling

  ProductSection({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.seeMoreText,
    this.seeMoreRoute,
    required this.products,
    required this.isActive,
    required this.order,
    required this.displayCount,
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
      imageUrl: json['imageUrl'] as String?,
      seeMoreText: json['seeMoreText'] as String?,
      seeMoreRoute: json['seeMoreRoute'] as String?,
      products: (json['products'] as List<dynamic>?)
              ?.map((productJson) => ProductModel.fromJson(productJson as Map<String, dynamic>))
              .toList() ??
          [],
      isActive: json['isActive'] as bool? ?? true,
      order: json['order'] as int? ?? 0,
      displayCount: json['displayCount'] as int? ?? 4,
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
      'imageUrl': imageUrl,
      'seeMoreText': seeMoreText,
      'seeMoreRoute': seeMoreRoute,
      'products': products.map((product) => product.toJson()).toList(),
      'isActive': isActive,
      'order': order,
      'displayCount': displayCount,
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
    String? imageUrl,
    String? seeMoreText,
    String? seeMoreRoute,
    List<ProductModel>? products,
    bool? isActive,
    int? order,
    int? displayCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ProductSection(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      seeMoreText: seeMoreText ?? this.seeMoreText,
      seeMoreRoute: seeMoreRoute ?? this.seeMoreRoute,
      products: products ?? this.products,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      displayCount: displayCount ?? this.displayCount,
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

  factory ProductSection.empty() {
    return ProductSection(
      id: '',
      title: '',
      subtitle: null,
      imageUrl: null,
      seeMoreText: null,
      seeMoreRoute: null,
      products: [],
      isActive: false,
      order: 0,
      displayCount: 0,
      createdAt: DateTime.now(),
      updatedAt: null,
      metadata: null,
    );
  }

  factory ProductSection.fromMap(Map<String, dynamic> map, String documentId) {
    return ProductSection(
      id: documentId,
      title: map['title'] ?? '',
      subtitle: map['subtitle'] as String?,
      imageUrl: map['imageUrl'] as String?,
      seeMoreText: map['seeMoreText'] as String?,
      seeMoreRoute: map['seeMoreRoute'] as String?,
      products: (map['products'] as List<dynamic>?)
              ?.map((productJson) => ProductModel.fromMap(productJson as Map<String, dynamic>, ''))
              .toList() ??
          [],
      isActive: map['isActive'] ?? false,
      order: map['order'] ?? 0,
      displayCount: map['displayCount'] ?? 4,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'seeMoreText': seeMoreText,
      'seeMoreRoute': seeMoreRoute,
      'products': products.map((product) => product.toMap()).toList(),
      'isActive': isActive,
      'order': order,
      'displayCount': displayCount,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      'metadata': metadata,
    };
  }
} 