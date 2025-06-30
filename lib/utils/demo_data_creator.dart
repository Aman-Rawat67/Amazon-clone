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
      // Electronics
      ProductModel(
        id: 'demo_1',
        name: 'Wireless Bluetooth Headphones',
        description: 'Premium quality wireless headphones with noise cancellation',
        price: 2999.0,
        originalPrice: 3999.0,
        category: 'Electronics',
        subcategory: 'Audio',
        imageUrls: ['https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500&h=500&fit=crop'],
        vendorId: 'demo_vendor_1',
        vendorName: 'AudioTech',
        stockQuantity: 50,
        isActive: true,
        isApproved: true,
        rating: 4.5,
        reviewCount: 128,
        specifications: {'brand': 'AudioTech', 'battery': '30 hours'},
        tags: ['wireless', 'bluetooth', 'noise-cancellation'],
        createdAt: DateTime.now(),
      ),
      ProductModel(
        id: 'demo_2',
        name: 'Smart Watch Fitness Tracker',
        description: 'Advanced fitness tracking with heart rate monitor',
        price: 4999.0,
        originalPrice: 6999.0,
        category: 'Electronics',
        subcategory: 'Wearables',
        imageUrls: ['https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=500&h=500&fit=crop'],
        vendorId: 'demo_vendor_2',
        vendorName: 'FitGear',
        stockQuantity: 25,
        isActive: true,
        isApproved: true,
        rating: 4.2,
        reviewCount: 89,
        specifications: {'brand': 'FitGear', 'battery': '7 days'},
        tags: ['smartwatch', 'fitness', 'health'],
        createdAt: DateTime.now(),
      ),
      ProductModel(
        id: 'demo_3',
        name: 'Wireless Charging Pad',
        description: 'Fast wireless charging for all compatible devices',
        price: 1499.0,
        originalPrice: 1999.0,
        category: 'Electronics',
        subcategory: 'Accessories',
        imageUrls: ['https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=500&h=500&fit=crop'],
        vendorId: 'demo_vendor_1',
        vendorName: 'AudioTech',
        stockQuantity: 100,
        isActive: true,
        isApproved: true,
        rating: 4.0,
        reviewCount: 45,
        specifications: {'brand': 'AudioTech', 'power': '15W'},
        tags: ['wireless', 'charging', 'fast'],
        createdAt: DateTime.now(),
      ),
      ProductModel(
        id: 'demo_4',
        name: 'Portable Bluetooth Speaker',
        description: 'Compact speaker with powerful bass and long battery life',
        price: 3499.0,
        category: 'Electronics',
        subcategory: 'Audio',
        imageUrls: ['https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?w=500&h=500&fit=crop'],
        vendorId: 'demo_vendor_2',
        vendorName: 'FitGear',
        stockQuantity: 75,
        isActive: true,
        isApproved: true,
        rating: 4.3,
        reviewCount: 67,
        specifications: {'brand': 'FitGear', 'battery': '12 hours'},
        tags: ['bluetooth', 'speaker', 'portable'],
        createdAt: DateTime.now(),
      ),
      
      // Fashion
      ProductModel(
        id: 'demo_5',
        name: 'Cotton Casual T-Shirt',
        description: 'Comfortable cotton t-shirt for everyday wear',
        price: 599.0,
        originalPrice: 899.0,
        category: 'Fashion',
        subcategory: 'Men\'s Clothing',
        imageUrls: ['https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=500&h=500&fit=crop'],
        vendorId: 'demo_vendor_3',
        vendorName: 'StyleHub',
        stockQuantity: 200,
        isActive: true,
        isApproved: true,
        rating: 4.1,
        reviewCount: 156,
        specifications: {'material': '100% Cotton', 'fit': 'Regular'},
        tags: ['cotton', 'casual', 'comfortable'],
        colors: ['White', 'Black', 'Navy', 'Gray'],
        sizes: ['S', 'M', 'L', 'XL'],
        createdAt: DateTime.now(),
      ),
      ProductModel(
        id: 'demo_6',
        name: 'Denim Jeans',
        description: 'Classic fit denim jeans with premium quality',
        price: 1999.0,
        originalPrice: 2999.0,
        category: 'Fashion',
        subcategory: 'Men\'s Clothing',
        imageUrls: ['https://images.unsplash.com/photo-1542272604-787c3835535d?w=500&h=500&fit=crop'],
        vendorId: 'demo_vendor_3',
        vendorName: 'StyleHub',
        stockQuantity: 150,
        isActive: true,
        isApproved: true,
        rating: 4.4,
        reviewCount: 203,
        specifications: {'material': 'Denim', 'fit': 'Slim'},
        tags: ['denim', 'jeans', 'classic'],
        colors: ['Blue', 'Black', 'Gray'],
        sizes: ['28', '30', '32', '34', '36'],
        createdAt: DateTime.now(),
      ),
      ProductModel(
        id: 'demo_7',
        name: 'Women\'s Dress',
        description: 'Elegant dress perfect for special occasions',
        price: 2499.0,
        originalPrice: 3499.0,
        category: 'Fashion',
        subcategory: 'Women\'s Clothing',
        imageUrls: ['https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=500&h=500&fit=crop'],
        vendorId: 'demo_vendor_4',
        vendorName: 'FashionForward',
        stockQuantity: 80,
        isActive: true,
        isApproved: true,
        rating: 4.6,
        reviewCount: 92,
        specifications: {'material': 'Polyester', 'occasion': 'Formal'},
        tags: ['dress', 'elegant', 'formal'],
        colors: ['Black', 'Navy', 'Red'],
        sizes: ['XS', 'S', 'M', 'L'],
        createdAt: DateTime.now(),
      ),
      ProductModel(
        id: 'demo_8',
        name: 'Casual Sneakers',
        description: 'Comfortable sneakers for daily wear',
        price: 3999.0,
        category: 'Fashion',
        subcategory: 'Footwear',
        imageUrls: ['https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=500&h=500&fit=crop'],
        vendorId: 'demo_vendor_4',
        vendorName: 'FashionForward',
        stockQuantity: 120,
        isActive: true,
        isApproved: true,
        rating: 4.2,
        reviewCount: 178,
        specifications: {'material': 'Canvas', 'sole': 'Rubber'},
        tags: ['sneakers', 'casual', 'comfortable'],
        colors: ['White', 'Black', 'Red'],
        sizes: ['6', '7', '8', '9', '10', '11'],
        createdAt: DateTime.now(),
      ),
      
      // Home & Kitchen
      ProductModel(
        id: 'demo_9',
        name: 'Non-Stick Cookware Set',
        description: 'Complete cookware set with non-stick coating',
        price: 4999.0,
        originalPrice: 7999.0,
        category: 'Home & Kitchen',
        subcategory: 'Cookware',
        imageUrls: ['https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=500&h=500&fit=crop'],
        vendorId: 'demo_vendor_5',
        vendorName: 'KitchenPro',
        stockQuantity: 40,
        isActive: true,
        isApproved: true,
        rating: 4.5,
        reviewCount: 134,
        specifications: {'material': 'Aluminum', 'coating': 'Non-stick'},
        tags: ['cookware', 'non-stick', 'kitchen'],
        createdAt: DateTime.now(),
      ),
      ProductModel(
        id: 'demo_10',
        name: 'Coffee Maker',
        description: 'Automatic coffee maker with programmable timer',
        price: 6999.0,
        originalPrice: 8999.0,
        category: 'Home & Kitchen',
        subcategory: 'Appliances',
        imageUrls: ['https://images.unsplash.com/photo-1495774856032-8b90bbb32b32?w=500&h=500&fit=crop'],
        vendorId: 'demo_vendor_5',
        vendorName: 'KitchenPro',
        stockQuantity: 30,
        isActive: true,
        isApproved: true,
        rating: 4.3,
        reviewCount: 87,
        specifications: {'capacity': '12 cups', 'type': 'Drip'},
        tags: ['coffee', 'maker', 'automatic'],
        createdAt: DateTime.now(),
      ),
      ProductModel(
        id: 'demo_11',
        name: 'Decorative Cushions',
        description: 'Set of decorative cushions for living room',
        price: 1999.0,
        category: 'Home & Kitchen',
        subcategory: 'Home Decor',
        imageUrls: ['https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=500&h=500&fit=crop'],
        vendorId: 'demo_vendor_6',
        vendorName: 'HomeStyle',
        stockQuantity: 60,
        isActive: true,
        isApproved: true,
        rating: 4.0,
        reviewCount: 45,
        specifications: {'material': 'Cotton', 'size': '16x16 inches'},
        tags: ['cushions', 'decorative', 'home-decor'],
        colors: ['Blue', 'Green', 'Yellow', 'Pink'],
        createdAt: DateTime.now(),
      ),
      ProductModel(
        id: 'demo_12',
        name: 'Table Lamp',
        description: 'Modern table lamp with adjustable brightness',
        price: 2999.0,
        originalPrice: 3999.0,
        category: 'Home & Kitchen',
        subcategory: 'Lighting',
        imageUrls: ['https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&h=500&fit=crop'],
        vendorId: 'demo_vendor_6',
        vendorName: 'HomeStyle',
        stockQuantity: 35,
        isActive: true,
        isApproved: true,
        rating: 4.4,
        reviewCount: 76,
        specifications: {'material': 'Metal', 'bulb': 'LED'},
        tags: ['lamp', 'table', 'adjustable'],
        createdAt: DateTime.now(),
      ),
      
      // Books
      ProductModel(
        id: 'demo_13',
        name: 'Flutter Development Guide',
        description: 'Complete guide to Flutter app development',
        price: 899.0,
        originalPrice: 1299.0,
        category: 'Books',
        subcategory: 'Technology',
        imageUrls: ['https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=500&h=500&fit=crop'],
        vendorId: 'demo_vendor_7',
        vendorName: 'TechBooks',
        stockQuantity: 200,
        isActive: true,
        isApproved: true,
        rating: 4.7,
        reviewCount: 243,
        specifications: {'pages': '450', 'language': 'English'},
        tags: ['flutter', 'programming', 'development'],
        createdAt: DateTime.now(),
      ),
      ProductModel(
        id: 'demo_14',
        name: 'Design Thinking Book',
        description: 'Learn the principles of design thinking',
        price: 699.0,
        category: 'Books',
        subcategory: 'Design',
        imageUrls: ['https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=500&h=500&fit=crop'],
        vendorId: 'demo_vendor_7',
        vendorName: 'TechBooks',
        stockQuantity: 150,
        isActive: true,
        isApproved: true,
        rating: 4.2,
        reviewCount: 167,
        specifications: {'pages': '320', 'language': 'English'},
        tags: ['design', 'thinking', 'creativity'],
        createdAt: DateTime.now(),
      ),
      ProductModel(
        id: 'demo_15',
        name: 'Cooking Recipe Book',
        description: 'Traditional recipes from around the world',
        price: 599.0,
        originalPrice: 899.0,
        category: 'Books',
        subcategory: 'Cooking',
        imageUrls: ['https://images.unsplash.com/photo-1512820790803-83ca734da794?w=500&h=500&fit=crop'],
        vendorId: 'demo_vendor_8',
        vendorName: 'CookingWorld',
        stockQuantity: 100,
        isActive: true,
        isApproved: true,
        rating: 4.5,
        reviewCount: 89,
        specifications: {'pages': '280', 'recipes': '150+'},
        tags: ['cooking', 'recipes', 'food'],
        createdAt: DateTime.now(),
      ),
      ProductModel(
        id: 'demo_16',
        name: 'Fitness Motivation Book',
        description: 'Guide to staying motivated on your fitness journey',
        price: 799.0,
        category: 'Books',
        subcategory: 'Health',
        imageUrls: ['https://images.unsplash.com/photo-1434394354979-a235cd36269d?w=500&h=500&fit=crop'],
        vendorId: 'demo_vendor_8',
        vendorName: 'CookingWorld',
        stockQuantity: 80,
        isActive: true,
        isApproved: true,
        rating: 4.1,
        reviewCount: 124,
        specifications: {'pages': '200', 'language': 'English'},
        tags: ['fitness', 'motivation', 'health'],
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