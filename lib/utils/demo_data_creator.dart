import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/product_section_model.dart';
import '../services/firestore_service.dart';
import '../constants/app_constants.dart';

/// Utility class for creating demo data in Firestore
class DemoDataCreator {
  static final FirestoreService _firestoreService = FirestoreService();

  /// Create demo products and product sections for testing
  static Future<void> createDemoData() async {
    try {
      print('🚀 Starting demo data creation...');
      
      // First create demo products
      final productIds = await _createDemoProducts();
      
      if (productIds.length < 16) {
        throw Exception('Need at least 16 products to create demo sections');
      }
      
      // Then create demo product sections
      await _createDemoProductSections(productIds);
      
      print('✅ Demo data created successfully!');
      print('📱 You can now see the dynamic homepage with product sections.');
    } catch (e) {
      print('❌ Error creating demo data: $e');
      rethrow;
    }
  }

  /// Create demo products with realistic data
  static Future<List<String>> _createDemoProducts() async {
    print('📦 Creating demo products...');
    
    final demoProducts = [
      // Clothing
      ProductModel(
        id: 'demo_1',
        name: 'Men\'s Casual Shirt',
        description: 'Comfortable cotton casual shirt for men',
        price: 999.0,
        originalPrice: 1499.0,
        category: 'clothing',
        subcategory: 'men',
        imageUrls: ['https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=500&h=500&fit=crop'],
        vendorId: 'demo_vendor_1',
        vendorName: 'FashionHub',
        stockQuantity: 50,
        isActive: true,
        isApproved: true,
        rating: 4.5,
        reviewCount: 120,
        specifications: {'material': 'Cotton', 'fit': 'Regular'},
        tags: ['shirt', 'casual', 'men'],
        colors: ['Blue', 'White', 'Black'],
        sizes: ['S', 'M', 'L', 'XL'],
        createdAt: DateTime.now(),
      ),
      
      // Electronics
      ProductModel(
        id: 'demo_2',
        name: 'Smartphone X Pro',
        description: 'Latest smartphone with advanced features',
        price: 29999.0,
        originalPrice: 34999.0,
        category: 'electronics',
        subcategory: 'mobile phones',
        imageUrls: ['https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=500&h=500&fit=crop'],
        vendorId: 'demo_vendor_2',
        vendorName: 'TechStore',
        stockQuantity: 30,
        isActive: true,
        isApproved: true,
        rating: 4.7,
        reviewCount: 85,
        specifications: {'processor': 'Snapdragon', 'ram': '8GB'},
        tags: ['smartphone', 'mobile', 'electronics'],
        colors: ['Black', 'Silver'],
        createdAt: DateTime.now(),
      ),

      // Handloom
      ProductModel(
        id: 'demo_3',
        name: 'Cotton Bedsheet Set',
        description: 'Premium quality cotton bedsheet with pillow covers',
        price: 1499.0,
        originalPrice: 1999.0,
        category: 'handloom',
        subcategory: 'bedsheets',
        imageUrls: ['https://images.unsplash.com/photo-1584100936595-c0654b55a2e6?w=500&h=500&fit=crop'],
        vendorId: 'demo_vendor_3',
        vendorName: 'HomeTex',
        stockQuantity: 40,
        isActive: true,
        isApproved: true,
        rating: 4.4,
        reviewCount: 65,
        specifications: {'material': 'Cotton', 'size': 'Double'},
        tags: ['bedsheet', 'cotton', 'home'],
        colors: ['White', 'Blue', 'Pink'],
        createdAt: DateTime.now(),
      ),

      // Automotive
      ProductModel(
        id: 'demo_4',
        name: 'Car Dash Camera',
        description: 'HD dash camera with night vision',
        price: 4999.0,
        originalPrice: 5999.0,
        category: 'automotive',
        subcategory: 'dash cam',
        imageUrls: ['https://images.unsplash.com/photo-1617531653332-bd46c24f2068?w=500&h=500&fit=crop'],
        vendorId: 'demo_vendor_4',
        vendorName: 'AutoTech',
        stockQuantity: 25,
        isActive: true,
        isApproved: true,
        rating: 4.6,
        reviewCount: 45,
        specifications: {'resolution': '1080p', 'storage': '32GB'},
        tags: ['dash cam', 'car', 'camera'],
        createdAt: DateTime.now(),
      ),

      // Home
      ProductModel(
        id: 'demo_5',
        name: 'Modern Coffee Table',
        description: 'Stylish coffee table for living room',
        price: 7999.0,
        originalPrice: 9999.0,
        category: 'home',
        subcategory: 'furniture',
        imageUrls: ['https://images.unsplash.com/photo-1533090481720-856c6e3c1fdc?w=500&h=500&fit=crop'],
        vendorId: 'demo_vendor_5',
        vendorName: 'HomeStyle',
        stockQuantity: 15,
        isActive: true,
        isApproved: true,
        rating: 4.8,
        reviewCount: 35,
        specifications: {'material': 'Wood', 'style': 'Modern'},
        tags: ['furniture', 'table', 'living room'],
        colors: ['Brown', 'White'],
        createdAt: DateTime.now(),
      ),
    ];

    final productIds = <String>[];
    
    for (final product in demoProducts) {
      try {
        final productId = await _firestoreService.addProduct(product);
        productIds.add(productId);
        print('✅ Created product: ${product.name}');
      } catch (e) {
        print('⚠️ Failed to create product ${product.name}: $e');
      }
    }
    
    print('📦 Created ${productIds.length} demo products');
    return productIds;
  }

  /// Create demo product sections using the created products
  static Future<void> _createDemoProductSections(List<String> productIds) async {
    print('🏪 Creating demo product sections...');
    
    final demoSections = [
      {
        'title': 'Electronics & Gadgets | Up to 40% off',
        'subtitle': 'Latest tech at amazing prices',
        'productIds': productIds.take(4).toList(),
        'seeMoreText': 'See all electronics',
        'seeMoreRoute': '/home/category/electronics',
        'displayCount': 4,
        'order': 0,
        'isActive': true,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'metadata': {
          'backgroundColor': '#ffffff',
          'textColor': '#000000',
          'featured': true,
        },
      },
      {
        'title': 'Fashion Trends | Up to 60% off',
        'subtitle': 'Style that speaks to you',
        'productIds': productIds.skip(4).take(4).toList(),
        'seeMoreText': 'Shop fashion',
        'seeMoreRoute': '/home/category/fashion',
        'displayCount': 4,
        'order': 1,
        'isActive': true,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'metadata': {
          'backgroundColor': '#ffffff',
          'textColor': '#000000',
        },
      },
      {
        'title': 'Home & Kitchen Essentials',
        'subtitle': 'Make your home beautiful',
        'productIds': productIds.skip(8).take(4).toList(),
        'seeMoreText': 'Explore home',
        'seeMoreRoute': '/home/category/home-kitchen',
        'displayCount': 4,
        'order': 2,
        'isActive': true,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'metadata': {
          'backgroundColor': '#ffffff',
          'textColor': '#000000',
        },
      },
      {
        'title': 'Books & Learning | Starting ₹599',
        'subtitle': 'Knowledge at your fingertips',
        'productIds': productIds.skip(12).take(4).toList(),
        'seeMoreText': 'Browse books',
        'seeMoreRoute': '/home/category/books',
        'displayCount': 4,
        'order': 3,
        'isActive': true,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'metadata': {
          'backgroundColor': '#ffffff',
          'textColor': '#000000',
        },
      },
    ];

    for (final section in demoSections) {
      try {
        await FirebaseFirestore.instance
            .collection(AppConstants.productSectionsCollection)
            .add(section);
        print('✅ Created section: ${section['title']}');
      } catch (e) {
        print('⚠️ Failed to create section ${section['title']}: $e');
      }
    }
    
    print('🏪 Created ${demoSections.length} demo product sections');
  }

  /// Clear all demo data (useful for testing)
  static Future<void> clearDemoData() async {
    try {
      print('🗑️ Clearing demo data...');
      
      // Clear demo products
      final products = await FirebaseFirestore.instance
          .collection(AppConstants.productsCollection)
          .where('id', whereIn: List.generate(16, (i) => 'demo_${i + 1}'))
          .get();
      
      for (final doc in products.docs) {
        await doc.reference.delete();
      }
      
      // Clear demo product sections
      final sections = await FirebaseFirestore.instance
          .collection(AppConstants.productSectionsCollection)
          .get();
      
      for (final doc in sections.docs) {
        final data = doc.data();
        final title = data['title'] as String?;
        if (title != null && (title.contains('Electronics & Gadgets') ||
            title.contains('Fashion Trends') ||
            title.contains('Home & Kitchen Essentials') ||
            title.contains('Books & Learning'))) {
          await doc.reference.delete();
        }
      }
      
      print('✅ Demo data cleared successfully');
    } catch (e) {
      print('❌ Error clearing demo data: $e');
      rethrow;
    }
  }
} 