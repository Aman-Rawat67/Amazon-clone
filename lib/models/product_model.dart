import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class representing a product in the Amazon clone app
class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice; // For showing discounts
  final String category;
  final String subcategory;
  final String categoryLower;
  final String subcategoryLower;
  final List<String> imageUrls;
  final String vendorId;
  final String vendorName;
  final int stockQuantity;
  final bool isActive;
  final bool isApproved; // Admin approval for vendor products
  final double rating;
  final int reviewCount;
  final Map<String, dynamic> specifications;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? shippingInfo;
  final List<String> colors;
  final List<String> sizes;
  
  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.category,
    required this.subcategory,
    required this.categoryLower,
    required this.subcategoryLower,
    this.imageUrls = const [],
    required this.vendorId,
    required this.vendorName,
    required this.stockQuantity,
    this.isActive = true,
    this.isApproved = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.specifications = const {},
    this.tags = const [],
    required this.createdAt,
    this.updatedAt,
    this.shippingInfo,
    this.colors = const [],
    this.sizes = const [],
  });

  /// Creates a ProductModel from JSON data
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      originalPrice: json['originalPrice'] != null 
          ? (json['originalPrice'] as num).toDouble() 
          : null,
      category: json['category'] as String,
      subcategory: json['subcategory'] as String,
      categoryLower: json['categoryLower'] as String? ?? json['category'].toString().toLowerCase(),
      subcategoryLower: json['subcategoryLower'] as String? ?? json['subcategory'].toString().toLowerCase(),
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      vendorId: json['vendorId'] as String,
      vendorName: json['vendorName'] as String,
      stockQuantity: json['stockQuantity'] as int,
      isActive: json['isActive'] as bool? ?? true,
      isApproved: json['isApproved'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      specifications: Map<String, dynamic>.from(json['specifications'] ?? {}),
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
      shippingInfo: json['shippingInfo'] as Map<String, dynamic>?,
      colors: List<String>.from(json['colors'] ?? []),
      sizes: List<String>.from(json['sizes'] ?? []),
    );
  }

  /// Converts ProductModel to JSON format
  Map<String, dynamic> toJson() {
    final nameNormalized = name.trim().toLowerCase();

    return {
      'id': id,
      'name': name,
      'nameLower': nameNormalized,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'category': category,
      'categoryLower': categoryLower,
      'subcategory': subcategory,
      'subcategoryLower': subcategoryLower,
      'imageUrls': imageUrls,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'stockQuantity': stockQuantity,
      'isActive': isActive,
      'isApproved': isApproved,
      'rating': rating,
      'reviewCount': reviewCount,
      'specifications': specifications,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null 
          ? Timestamp.fromDate(updatedAt!) 
          : null,
      'shippingInfo': shippingInfo,
      'colors': colors,
      'sizes': sizes,
      // Add search keywords for better search functionality
      'searchKeywords': [
        nameNormalized,
        categoryLower,
        subcategoryLower,
        ...tags.map((tag) => tag.toLowerCase()),
      ],
    };
  }

  /// Creates a copy of ProductModel with updated fields
  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? originalPrice,
    String? category,
    String? subcategory,
    String? categoryLower,
    String? subcategoryLower,
    List<String>? imageUrls,
    String? vendorId,
    String? vendorName,
    int? stockQuantity,
    bool? isActive,
    bool? isApproved,
    double? rating,
    int? reviewCount,
    Map<String, dynamic>? specifications,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? shippingInfo,
    List<String>? colors,
    List<String>? sizes,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      categoryLower: categoryLower ?? this.categoryLower,
      subcategoryLower: subcategoryLower ?? this.subcategoryLower,
      imageUrls: imageUrls ?? this.imageUrls,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isActive: isActive ?? this.isActive,
      isApproved: isApproved ?? this.isApproved,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      specifications: specifications ?? this.specifications,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      shippingInfo: shippingInfo ?? this.shippingInfo,
      colors: colors ?? this.colors,
      sizes: sizes ?? this.sizes,
    );
  }

  /// Check if product is in stock
  bool get isInStock => stockQuantity > 0;

  /// Calculate discount percentage
  double get discountPercentage {
    if (originalPrice == null || originalPrice! <= price) return 0.0;
    return ((originalPrice! - price) / originalPrice!) * 100;
  }

  /// Check if product has discount
  bool get hasDiscount => discountPercentage > 0;

  /// Get image URLs (alias for consistency)
  List<String> get images => imageUrls;

  /// Get stock quantity (alias for consistency)
  int get stock => stockQuantity;

  /// Get brand from specifications (if available)
  String? get brand => specifications['brand'] as String?;

  @override
  String toString() {
    return 'ProductModel(id: $id, name: $name, price: $price, vendorId: $vendorId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ProductModel &&
        other.id == id &&
        other.name == name &&
        other.price == price &&
        other.vendorId == vendorId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        price.hashCode ^
        vendorId.hashCode;
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return ProductModel(
      id: id ?? map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      price: (map['price'] as num).toDouble(),
      originalPrice: map['originalPrice'] != null 
          ? (map['originalPrice'] as num).toDouble() 
          : null,
      category: map['category'] as String,
      subcategory: map['subcategory'] as String,
      categoryLower: map['categoryLower'] as String? ?? map['category'].toString().toLowerCase(),
      subcategoryLower: map['subcategoryLower'] as String? ?? map['subcategory'].toString().toLowerCase(),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      vendorId: map['vendorId'] as String,
      vendorName: map['vendorName'] as String,
      stockQuantity: map['stockQuantity'] as int,
      isActive: map['isActive'] as bool? ?? true,
      isApproved: map['isApproved'] as bool? ?? false,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: map['reviewCount'] as int? ?? 0,
      specifications: Map<String, dynamic>.from(map['specifications'] ?? {}),
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      shippingInfo: map['shippingInfo'] as Map<String, dynamic>?,
      colors: List<String>.from(map['colors'] ?? []),
      sizes: List<String>.from(map['sizes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'category': category,
      'categoryLower': categoryLower,
      'subcategory': subcategory,
      'subcategoryLower': subcategoryLower,
      'imageUrls': imageUrls,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'stockQuantity': stockQuantity,
      'isActive': isActive,
      'isApproved': isApproved,
      'rating': rating,
      'reviewCount': reviewCount,
      'specifications': specifications,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null 
          ? Timestamp.fromDate(updatedAt!) 
          : null,
      'shippingInfo': shippingInfo,
      'colors': colors,
      'sizes': sizes,
    };
  }
} 