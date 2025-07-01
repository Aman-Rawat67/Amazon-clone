import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class representing a banner for the homepage
class BannerModel {
  final String id;
  final String imageUrl;
  final String? title;
  final String? subtitle;
  final String? actionUrl;
  final bool isActive;
  final int order;
  final DateTime? startDate;
  final DateTime? endDate;

  const BannerModel({
    required this.id,
    required this.imageUrl,
    this.title,
    this.subtitle,
    this.actionUrl,
    required this.isActive,
    required this.order,
    this.startDate,
    this.endDate,
  });

  /// Creates a BannerModel from JSON data
  factory BannerModel.fromMap(Map<String, dynamic> map, String id) {
    return BannerModel(
      id: id,
      imageUrl: map['imageUrl'] as String,
      title: map['title'] as String?,
      subtitle: map['subtitle'] as String?,
      actionUrl: map['actionUrl'] as String?,
      isActive: map['isActive'] as bool,
      order: map['order'] as int,
      startDate: (map['startDate'] as Timestamp?)?.toDate(),
      endDate: (map['endDate'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts BannerModel to JSON format
  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'title': title,
      'subtitle': subtitle,
      'actionUrl': actionUrl,
      'isActive': isActive,
      'order': order,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    };
  }

  /// Check if banner is currently active
  bool get isCurrentlyActive {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  /// Creates a copy of BannerModel with updated fields
  BannerModel copyWith({
    String? id,
    String? imageUrl,
    String? title,
    String? subtitle,
    String? actionUrl,
    bool? isActive,
    int? order,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return BannerModel(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      actionUrl: actionUrl ?? this.actionUrl,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
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