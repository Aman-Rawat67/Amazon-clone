import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_model.dart';

/// Enum for order status
enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
  refunded,
  returned
}

/// Enum for payment status
enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded,
  cancelled
}

/// Model class for shipping address
class ShippingAddress {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final bool isDefault;
  final String? deliveryInstructions;
  
  const ShippingAddress({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    this.isDefault = false,
    this.deliveryInstructions,
  });

  /// Creates a ShippingAddress from a pipe-delimited string
  factory ShippingAddress.fromString(String addressString) {
    final parts = addressString.split('|');
    return ShippingAddress(
      id: parts[0],
      name: parts[1],
      phone: parts[2],
      address: parts[3],
      city: parts[4],
      state: parts[5],
      zipCode: parts[6],
      country: parts[7],
      isDefault: parts[8].toLowerCase() == 'true',
      deliveryInstructions: parts.length > 9 ? parts[9] : null,
    );
  }

  /// Creates a ShippingAddress from JSON data
  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      zipCode: json['zipCode'] as String,
      country: json['country'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      deliveryInstructions: json['deliveryInstructions'] as String?,
    );
  }

  /// Converts ShippingAddress to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'isDefault': isDefault,
      'deliveryInstructions': deliveryInstructions,
    };
  }

  /// Get formatted address string
  String get formattedAddress {
    return '$address, $city, $state $zipCode, $country';
  }

  /// Get street address (alias for address)
  String get street => address;

  /// Get phone number (alias for phone)
  String get phoneNumber => phone;

  @override
  String toString() {
    return 'ShippingAddress(id: $id, name: $name, city: $city)';
  }
}

/// Model class for order tracking
class OrderTracking {
  final String status;
  final String description;
  final DateTime timestamp;
  final String? location;
  
  const OrderTracking({
    required this.status,
    required this.description,
    required this.timestamp,
    this.location,
  });

  /// Creates an OrderTracking from JSON data
  factory OrderTracking.fromJson(Map<String, dynamic> json) {
    return OrderTracking(
      status: json['status'] as String,
      description: json['description'] as String,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      location: json['location'] as String?,
    );
  }

  /// Converts OrderTracking to JSON format
  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'location': location,
    };
  }
}

/// Model class for orders
class OrderModel {
  final String id;
  final String userId;
  final String orderNumber;
  final List<CartItem> items;
  final double subtotal;
  final double shippingCost;
  final double tax;
  final double discount;
  final double totalAmount;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final String paymentMethod;
  final String? paymentId;
  final ShippingAddress shippingAddress;
  final List<OrderTracking> tracking;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deliveredAt;
  final String? notes;
  final String? cancellationReason;
  
  const OrderModel({
    required this.id,
    required this.userId,
    required this.orderNumber,
    required this.items,
    required this.subtotal,
    this.shippingCost = 0.0,
    this.tax = 0.0,
    this.discount = 0.0,
    required this.totalAmount,
    this.status = OrderStatus.pending,
    this.paymentStatus = PaymentStatus.pending,
    required this.paymentMethod,
    this.paymentId,
    required this.shippingAddress,
    this.tracking = const [],
    required this.createdAt,
    this.updatedAt,
    this.deliveredAt,
    this.notes,
    this.cancellationReason,
  });

  /// Creates an OrderModel from JSON data
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      orderNumber: json['orderNumber'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      shippingCost: (json['shippingCost'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: OrderStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (status) => status.name == json['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      paymentMethod: json['paymentMethod'] as String,
      paymentId: json['paymentId'] as String?,
      shippingAddress: ShippingAddress.fromJson(
        json['shippingAddress'] as Map<String, dynamic>,
      ),
      tracking: (json['tracking'] as List<dynamic>?)
          ?.map((track) => OrderTracking.fromJson(track as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? (json['deliveredAt'] as Timestamp).toDate()
          : null,
      notes: json['notes'] as String?,
      cancellationReason: json['cancellationReason'] as String?,
    );
  }

  /// Converts OrderModel to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'orderNumber': orderNumber,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'shippingCost': shippingCost,
      'tax': tax,
      'discount': discount,
      'totalAmount': totalAmount,
      'status': status.name,
      'paymentStatus': paymentStatus.name,
      'paymentMethod': paymentMethod,
      'paymentId': paymentId,
      'shippingAddress': shippingAddress.toJson(),
      'tracking': tracking.map((track) => track.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null 
          ? Timestamp.fromDate(updatedAt!) 
          : null,
      'deliveredAt': deliveredAt != null 
          ? Timestamp.fromDate(deliveredAt!) 
          : null,
      'notes': notes,
      'cancellationReason': cancellationReason,
    };
  }

  /// Creates a copy of OrderModel with updated fields
  OrderModel copyWith({
    String? id,
    String? userId,
    String? orderNumber,
    List<CartItem>? items,
    double? subtotal,
    double? shippingCost,
    double? tax,
    double? discount,
    double? totalAmount,
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    String? paymentMethod,
    String? paymentId,
    ShippingAddress? shippingAddress,
    List<OrderTracking>? tracking,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deliveredAt,
    String? notes,
    String? cancellationReason,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      orderNumber: orderNumber ?? this.orderNumber,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      shippingCost: shippingCost ?? this.shippingCost,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentId: paymentId ?? this.paymentId,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      tracking: tracking ?? this.tracking,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      notes: notes ?? this.notes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }

  /// Check if order can be cancelled
  bool get canBeCancelled => 
      status == OrderStatus.pending || 
      status == OrderStatus.confirmed;

  /// Check if order is delivered
  bool get isDelivered => status == OrderStatus.delivered;

  /// Check if order is cancelled
  bool get isCancelled => status == OrderStatus.cancelled;

  /// Get total number of items in order
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  /// Get total amount (alias for totalAmount)
  double get total => totalAmount;

  /// Get shipping cost (alias for shippingCost)
  double get shipping => shippingCost;

  @override
  String toString() {
    return 'OrderModel(id: $id, orderNumber: $orderNumber, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is OrderModel &&
        other.id == id &&
        other.orderNumber == orderNumber &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ orderNumber.hashCode ^ userId.hashCode;
  }
} 