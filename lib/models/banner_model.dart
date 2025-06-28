import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class representing a banner for the homepage
class BannerModel {
  final String id;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? actionText;
  final String? actionRoute;
  final String? actionUrl;
  final bool isActive;
  final int order;
  final DateTime startDate;
  final DateTime? endDate;
  final String? targetAudience; // 'all', 'new_users', 'returning_users'
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const BannerModel({
    required this.id,
    required this.title,
    this.subtitle,
    required this.imageUrl,
    this.actionText,
    this.actionRoute,
    this.actionUrl,
    this.isActive = true,
    this.order = 0,
    required this.startDate,
    this.endDate,
    this.targetAudience,
    this.metadata,
    required this.createdAt,
    this.updatedAt,
  });

  /// Creates a BannerModel from JSON data
  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      imageUrl: json['imageUrl'] as String,
      actionText: json['actionText'] as String?,
      actionRoute: json['actionRoute'] as String?,
      actionUrl: json['actionUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      order: json['order'] as int? ?? 0,
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: json['endDate'] != null 
          ? (json['endDate'] as Timestamp).toDate() 
          : null,
      targetAudience: json['targetAudience'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Converts BannerModel to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'actionText': actionText,
      'actionRoute': actionRoute,
      'actionUrl': actionUrl,
      'isActive': isActive,
      'order': order,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'targetAudience': targetAudience,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Check if banner is currently active
  bool get isCurrentlyActive {
    final now = DateTime.now();
    final isInDateRange = now.isAfter(startDate) && 
        (endDate == null || now.isBefore(endDate!));
    return isActive && isInDateRange;
  }

  /// Creates a copy of BannerModel with updated fields
  BannerModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? imageUrl,
    String? actionText,
    String? actionRoute,
    String? actionUrl,
    bool? isActive,
    int? order,
    DateTime? startDate,
    DateTime? endDate,
    String? targetAudience,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BannerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      actionText: actionText ?? this.actionText,
      actionRoute: actionRoute ?? this.actionRoute,
      actionUrl: actionUrl ?? this.actionUrl,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      targetAudience: targetAudience ?? this.targetAudience,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'BannerModel(id: $id, title: $title, isActive: $isCurrentlyActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is BannerModel &&
        other.id == id &&
        other.title == title;
  }

  @override
  int get hashCode => Object.hash(id, title);
} 