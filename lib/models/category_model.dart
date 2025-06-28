import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class representing a category tile for the homepage
class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final String iconUrl;
  final String? imageUrl;
  final String route;
  final bool isActive;
  final int order;
  final String? parentCategory;
  final List<String> subcategories;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CategoryModel({
    required this.id,
    required this.name,
    this.description,
    required this.iconUrl,
    this.imageUrl,
    required this.route,
    this.isActive = true,
    this.order = 0,
    this.parentCategory,
    this.subcategories = const [],
    this.metadata,
    required this.createdAt,
    this.updatedAt,
  });

  /// Creates a CategoryModel from JSON data
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconUrl: json['iconUrl'] as String,
      imageUrl: json['imageUrl'] as String?,
      route: json['route'] as String,
      isActive: json['isActive'] as bool? ?? true,
      order: json['order'] as int? ?? 0,
      parentCategory: json['parentCategory'] as String?,
      subcategories: (json['subcategories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Converts CategoryModel to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'imageUrl': imageUrl,
      'route': route,
      'isActive': isActive,
      'order': order,
      'parentCategory': parentCategory,
      'subcategories': subcategories,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Check if category has subcategories
  bool get hasSubcategories => subcategories.isNotEmpty;

  /// Get category color from metadata
  String? get color => metadata?['color'] as String?;

  /// Get category background color from metadata
  String? get backgroundColor => metadata?['backgroundColor'] as String?;

  /// Creates a copy of CategoryModel with updated fields
  CategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    String? iconUrl,
    String? imageUrl,
    String? route,
    bool? isActive,
    int? order,
    String? parentCategory,
    List<String>? subcategories,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      route: route ?? this.route,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      parentCategory: parentCategory ?? this.parentCategory,
      subcategories: subcategories ?? this.subcategories,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, subcategories: ${subcategories.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is CategoryModel &&
        other.id == id &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, name);
} 