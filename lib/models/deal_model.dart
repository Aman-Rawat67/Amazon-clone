import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_model.dart';

/// Model class representing a deal for the homepage
class DealModel {
  final String id;
  final String title;
  final String? description;
  final ProductModel product;
  final double originalPrice;
  final double discountedPrice;
  final double discountPercentage;
  final String? badgeText; // e.g., "Lightning Deal", "Deal of the Day"
  final String? badgeColor;
  final bool isActive;
  final DateTime startDate;
  final DateTime endDate;
  final int? maxQuantity; // Limited quantity deals
  final int? soldQuantity;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const DealModel({
    required this.id,
    required this.title,
    this.description,
    required this.product,
    required this.originalPrice,
    required this.discountedPrice,
    required this.discountPercentage,
    this.badgeText,
    this.badgeColor,
    this.isActive = true,
    required this.startDate,
    required this.endDate,
    this.maxQuantity,
    this.soldQuantity,
    this.metadata,
    required this.createdAt,
    this.updatedAt,
  });

  /// Creates a DealModel from JSON data
  factory DealModel.fromJson(Map<String, dynamic> json) {
    return DealModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      originalPrice: (json['originalPrice'] as num).toDouble(),
      discountedPrice: (json['discountedPrice'] as num).toDouble(),
      discountPercentage: (json['discountPercentage'] as num).toDouble(),
      badgeText: json['badgeText'] as String?,
      badgeColor: json['badgeColor'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: (json['endDate'] as Timestamp).toDate(),
      maxQuantity: json['maxQuantity'] as int?,
      soldQuantity: json['soldQuantity'] as int?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Converts DealModel to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'product': product.toJson(),
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'discountPercentage': discountPercentage,
      'badgeText': badgeText,
      'badgeColor': badgeColor,
      'isActive': isActive,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'maxQuantity': maxQuantity,
      'soldQuantity': soldQuantity,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Check if deal is currently active
  bool get isCurrentlyActive {
    final now = DateTime.now();
    final isInDateRange = now.isAfter(startDate) && now.isBefore(endDate);
    final isAvailable = maxQuantity == null || 
        (soldQuantity ?? 0) < maxQuantity!;
    return isActive && isInDateRange && isAvailable;
  }

  /// Get time remaining for the deal
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return Duration.zero;
    return endDate.difference(now);
  }

  /// Get formatted time remaining string
  String get timeRemainingFormatted {
    final remaining = timeRemaining;
    if (remaining == Duration.zero) return 'Expired';
    
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    
    if (hours > 24) {
      final days = hours ~/ 24;
      return '${days}d ${hours % 24}h';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Get savings amount
  double get savingsAmount => originalPrice - discountedPrice;

  /// Get availability percentage (for limited quantity deals)
  double? get availabilityPercentage {
    if (maxQuantity == null) return null;
    final sold = soldQuantity ?? 0;
    return ((maxQuantity! - sold) / maxQuantity!) * 100;
  }

  /// Creates a copy of DealModel with updated fields
  DealModel copyWith({
    String? id,
    String? title,
    String? description,
    ProductModel? product,
    double? originalPrice,
    double? discountedPrice,
    double? discountPercentage,
    String? badgeText,
    String? badgeColor,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    int? maxQuantity,
    int? soldQuantity,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DealModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      product: product ?? this.product,
      originalPrice: originalPrice ?? this.originalPrice,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      badgeText: badgeText ?? this.badgeText,
      badgeColor: badgeColor ?? this.badgeColor,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      soldQuantity: soldQuantity ?? this.soldQuantity,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'DealModel(id: $id, title: $title, discount: ${discountPercentage}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is DealModel &&
        other.id == id &&
        other.title == title;
  }

  @override
  int get hashCode => Object.hash(id, title);
} 