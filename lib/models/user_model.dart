import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for user roles in the application
enum UserRole { customer, vendor, admin }

/// Model class representing a user in the Amazon clone app
class UserModel {
  final String id;
  final String email;
  final String name;
  final String? phoneNumber;
  final String? profileImageUrl;
  final UserRole role;
  final List<String> addresses;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic>? vendorInfo; // For vendor-specific data
  
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.profileImageUrl,
    required this.role,
    this.addresses = const [],
    this.isVerified = false,
    required this.createdAt,
    this.lastLoginAt,
    this.vendorInfo,
  });

  /// Creates a UserModel from JSON data
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      role: UserRole.values.firstWhere(
        (role) => role.name == json['role'],
        orElse: () => UserRole.customer,
      ),
      addresses: List<String>.from(json['addresses'] ?? []),
      isVerified: json['isVerified'] as bool? ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      lastLoginAt: json['lastLoginAt'] != null
          ? (json['lastLoginAt'] as Timestamp).toDate()
          : null,
      vendorInfo: json['vendorInfo'] as Map<String, dynamic>?,
    );
  }

  /// Converts UserModel to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'role': role.name,
      'addresses': addresses,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null 
          ? Timestamp.fromDate(lastLoginAt!) 
          : null,
      'vendorInfo': vendorInfo,
    };
  }

  /// Creates a copy of UserModel with updated fields
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
    UserRole? role,
    List<String>? addresses,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? vendorInfo,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      addresses: addresses ?? this.addresses,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      vendorInfo: vendorInfo ?? this.vendorInfo,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is UserModel &&
        other.id == id &&
        other.email == email &&
        other.name == name &&
        other.role == role;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        name.hashCode ^
        role.hashCode;
  }
} 