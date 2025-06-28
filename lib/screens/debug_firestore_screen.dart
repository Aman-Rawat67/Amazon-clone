import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

/// Debug screen to analyze Firestore data structure
class DebugFirestoreScreen extends StatefulWidget {
  const DebugFirestoreScreen({super.key});

  @override
  State<DebugFirestoreScreen> createState() => _DebugFirestoreScreenState();
}

class _DebugFirestoreScreenState extends State<DebugFirestoreScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _debugOutput = 'Loading...';

  @override
  void initState() {
    super.initState();
    _analyzeFirestoreData();
  }

  Future<void> _analyzeFirestoreData() async {
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════════════════════');
    buffer.writeln('🔍 FIRESTORE DATA ANALYSIS REPORT');
    buffer.writeln('═══════════════════════════════════════════════════════\n');

    try {
      // Check product sections collection
      buffer.writeln('📁 PRODUCT SECTIONS COLLECTION:');
      buffer.writeln('─────────────────────────────────────────────────────');
      final sectionsSnapshot = await _firestore
          .collection(AppConstants.productSectionsCollection)
          .get();

      buffer.writeln('📊 Total documents: ${sectionsSnapshot.docs.length}');

      if (sectionsSnapshot.docs.isEmpty) {
        buffer.writeln('\n❌ CRITICAL: No product sections found!');
        buffer.writeln('💡 SOLUTION: Create product sections first.');
        buffer.writeln('   Use the "Create Sample Data" button below.\n');
      } else {
        int validSections = 0;
        buffer.writeln('\n📋 SECTION DETAILS:');
        
        for (int i = 0; i < sectionsSnapshot.docs.length; i++) {
          final doc = sectionsSnapshot.docs[i];
          final data = doc.data();
          
          buffer.writeln('\n┌─ Section ${i + 1}: ${doc.id}');
          buffer.writeln('├─ Title: "${data['title'] ?? 'MISSING'}"');
          buffer.writeln('├─ Active: ${data['isActive'] == true ? '✅ Yes' : '❌ No'}');
          buffer.writeln('├─ Order: ${data['order'] ?? 'MISSING'}');
          
          final productIds = data['productIds'];
          if (productIds == null) {
            buffer.writeln('└─ ProductIds: ❌ MISSING FIELD!');
          } else if (productIds is List && productIds.isEmpty) {
            buffer.writeln('└─ ProductIds: ❌ EMPTY ARRAY!');
          } else if (productIds is List) {
            buffer.writeln('└─ ProductIds: ✅ ${productIds.length} products');
            if (data['isActive'] == true) validSections++;
          } else {
            buffer.writeln('└─ ProductIds: ❌ INVALID FORMAT!');
          }
        }
        
        buffer.writeln('\n📈 Valid sections: $validSections/${sectionsSnapshot.docs.length}');
      }

      // Check products collection
      buffer.writeln('\n\n📁 PRODUCTS COLLECTION:');
      buffer.writeln('─────────────────────────────────────────────────────');
      final productsSnapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .get();

      buffer.writeln('📊 Total documents: ${productsSnapshot.docs.length}');

      if (productsSnapshot.docs.isEmpty) {
        buffer.writeln('\n❌ CRITICAL: No products found!');
        buffer.writeln('💡 SOLUTION: Create products first.');
        buffer.writeln('   Use the "Create Sample Data" button below.\n');
      } else {
        int activeCount = 0;
        int approvedCount = 0;
        int activeApprovedCount = 0;
        
        for (final doc in productsSnapshot.docs) {
          final data = doc.data();
          final isActive = data['isActive'] == true;
          final isApproved = data['isApproved'] == true;
          
          if (isActive) activeCount++;
          if (isApproved) approvedCount++;
          if (isActive && isApproved) activeApprovedCount++;
        }
        
        buffer.writeln('\n📈 PRODUCT STATISTICS:');
        buffer.writeln('├─ Active products: $activeCount');
        buffer.writeln('├─ Approved products: $approvedCount');
        buffer.writeln('└─ Active & Approved: $activeApprovedCount');
        
        if (activeApprovedCount == 0) {
          buffer.writeln('\n❌ CRITICAL: No products are both active AND approved!');
          buffer.writeln('💡 SOLUTION: Set isActive=true AND isApproved=true');
        }
        
        // Show sample products
        buffer.writeln('\n📋 SAMPLE PRODUCTS:');
        final sampleCount = productsSnapshot.docs.length > 3 ? 3 : productsSnapshot.docs.length;
        for (int i = 0; i < sampleCount; i++) {
          final doc = productsSnapshot.docs[i];
          final data = doc.data();
          
          buffer.writeln('\n┌─ Product ${i + 1}: ${doc.id}');
          buffer.writeln('├─ Name: "${data['name'] ?? 'MISSING'}"');
          buffer.writeln('├─ Active: ${data['isActive'] == true ? '✅ Yes' : '❌ No'}');
          buffer.writeln('└─ Approved: ${data['isApproved'] == true ? '✅ Yes' : '❌ No'}');
        }
      }

      // Final diagnosis
      buffer.writeln('\n\n🎯 DIAGNOSIS & SOLUTIONS:');
      buffer.writeln('═══════════════════════════════════════════════════════');
      
      if (sectionsSnapshot.docs.isEmpty) {
        buffer.writeln('🚨 PRIMARY ISSUE: No product sections exist');
        buffer.writeln('✅ FIX: Click "Create Sample Data" button');
      } else if (productsSnapshot.docs.isEmpty) {
        buffer.writeln('🚨 PRIMARY ISSUE: No products exist');
        buffer.writeln('✅ FIX: Click "Create Sample Data" button');
      } else {
        bool hasValidSections = false;
        int activeApprovedProducts = 0;
        
        // Count valid sections
        for (final doc in sectionsSnapshot.docs) {
          final data = doc.data();
          if (data['isActive'] == true && 
              data['productIds'] != null && 
              (data['productIds'] as List).isNotEmpty) {
            hasValidSections = true;
            break;
          }
        }
        
        // Count active+approved products
        for (final doc in productsSnapshot.docs) {
          final data = doc.data();
          if (data['isActive'] == true && data['isApproved'] == true) {
            activeApprovedProducts++;
          }
        }
        
        if (!hasValidSections) {
          buffer.writeln('🚨 PRIMARY ISSUE: No valid product sections');
          buffer.writeln('✅ FIX: Set isActive=true and add productIds array');
        } else if (activeApprovedProducts == 0) {
          buffer.writeln('🚨 PRIMARY ISSUE: No approved products');
          buffer.writeln('✅ FIX: Set isActive=true AND isApproved=true on products');
        } else {
          buffer.writeln('✅ Data structure looks correct!');
          buffer.writeln('💡 If still not working, check product ID references');
        }
      }
      
      buffer.writeln('\n💡 TIP: Use "Create Sample Data" for working examples');
      buffer.writeln('═══════════════════════════════════════════════════════');

    } catch (e) {
      buffer.writeln('❌ ERROR: Failed to analyze data');
      buffer.writeln('Details: $e');
      buffer.writeln('\n💡 Check your Firebase configuration and permissions');
    }

    setState(() {
      _debugOutput = buffer.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Firestore Data'),
        backgroundColor: const Color(0xFF232F3E),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _analyzeFirestoreData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh Analysis'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF232F3E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _createSampleData,
                            icon: const Icon(Icons.add_circle),
                            label: const Text('Create Sample Data'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _quickStart,
                      icon: const Icon(Icons.rocket_launch),
                      label: const Text('🚀 Quick Start - Create Everything!'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                elevation: 4,
                margin: EdgeInsets.zero,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _debugOutput,
                      style: TextStyle(
                        fontFamily: 'Courier New',
                        fontSize: 14,
                        height: 1.5,
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createSampleData() async {
    try {
      // Create sample products first
      final productIds = <String>[];
      
      final sampleProducts = [
        {
          'name': 'Wireless Headphones',
          'description': 'Premium wireless headphones',
          'price': 2999,
          'category': 'Electronics',
          'subcategory': 'Audio',
          'imageUrls': ['https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500&h=500&fit=crop'],
          'vendorId': 'vendor_1',
          'vendorName': 'TechStore',
          'stockQuantity': 50,
          'isActive': true,
          'isApproved': true,
          'rating': 4.5,
          'reviewCount': 100,
          'specifications': {},
          'tags': ['wireless', 'audio'],
          'createdAt': Timestamp.now(),
          'colors': [],
          'sizes': [],
        },
        {
          'name': 'Smart Watch',
          'description': 'Fitness tracking smartwatch',
          'price': 4999,
          'category': 'Electronics',
          'subcategory': 'Wearables',
          'imageUrls': ['https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=500&h=500&fit=crop'],
          'vendorId': 'vendor_1',
          'vendorName': 'TechStore',
          'stockQuantity': 30,
          'isActive': true,
          'isApproved': true,
          'rating': 4.2,
          'reviewCount': 75,
          'specifications': {},
          'tags': ['smartwatch', 'fitness'],
          'createdAt': Timestamp.now(),
          'colors': [],
          'sizes': [],
        },
      ];

      for (final productData in sampleProducts) {
        final docRef = await _firestore
            .collection(AppConstants.productsCollection)
            .add(productData);
        await docRef.update({'id': docRef.id});
        productIds.add(docRef.id);
      }

      // Create sample product section
      await _firestore
          .collection(AppConstants.productSectionsCollection)
          .add({
        'title': 'Starting ₹2999 | Electronics',
        'subtitle': 'Best deals on electronics',
        'productIds': productIds,
        'seeMoreText': 'See all offers',
        'seeMoreRoute': '/electronics',
        'displayCount': 4,
        'isActive': true,
        'order': 0,
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Sample data created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh analysis
      _analyzeFirestoreData();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error creating sample data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _quickStart() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚀 Creating complete system with auto-linked products...'),
          backgroundColor: Colors.purple,
          duration: Duration(seconds: 2),
        ),
      );

      // Create comprehensive demo products with auto-linking
      final productCategories = [
        {
          'category': 'Electronics',
          'products': [
            {
              'name': 'Wireless Bluetooth Headphones',
              'description': 'Premium quality wireless headphones with noise cancellation and 30-hour battery life',
              'price': 2999,
              'originalPrice': 3999,
              'imageUrls': ['https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500&h=500&fit=crop'],
            },
            {
              'name': 'Smart Fitness Watch',
              'description': 'Advanced fitness tracking with heart rate monitor, GPS, and waterproof design',
              'price': 4999,
              'originalPrice': 6999,
              'imageUrls': ['https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=500&h=500&fit=crop'],
            },
            {
              'name': 'Wireless Charging Pad',
              'description': 'Fast wireless charging for all Qi-compatible devices with LED indicator',
              'price': 1499,
              'originalPrice': 1999,
              'imageUrls': ['https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=500&h=500&fit=crop'],
            },
            {
              'name': 'Portable Bluetooth Speaker',
              'description': 'Compact speaker with powerful bass, waterproof design, and 12-hour battery',
              'price': 3499,
              'imageUrls': ['https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?w=500&h=500&fit=crop'],
            },
          ]
        },
        {
          'category': 'Fashion',
          'products': [
            {
              'name': 'Cotton Casual T-Shirt',
              'description': 'Comfortable 100% cotton t-shirt perfect for everyday wear in premium quality fabric',
              'price': 599,
              'originalPrice': 899,
              'imageUrls': ['https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=500&h=500&fit=crop'],
            },
            {
              'name': 'Premium Denim Jeans',
              'description': 'Classic fit denim jeans with premium quality fabric and comfortable design',
              'price': 1999,
              'originalPrice': 2999,
              'imageUrls': ['https://images.unsplash.com/photo-1542272604-787c3835535d?w=500&h=500&fit=crop'],
            },
            {
              'name': 'Elegant Summer Dress',
              'description': 'Beautiful summer dress perfect for special occasions with elegant design',
              'price': 2499,
              'originalPrice': 3499,
              'imageUrls': ['https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=500&h=500&fit=crop'],
            },
            {
              'name': 'Comfortable Running Shoes',
              'description': 'Lightweight running shoes with excellent cushioning and breathable material',
              'price': 3999,
              'imageUrls': ['https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=500&h=500&fit=crop'],
            },
          ]
        }
      ];

      // Create all products and let the auto-assignment handle sections
      for (final categoryData in productCategories) {
        for (final productData in categoryData['products'] as List) {
          final docRef = await _firestore
              .collection(AppConstants.productsCollection)
              .add({
            'name': productData['name'],
            'description': productData['description'],
            'price': productData['price'],
            'originalPrice': productData['originalPrice'],
            'category': categoryData['category'],
            'subcategory': 'General',
            'imageUrls': productData['imageUrls'],
            'vendorId': 'quick_start_vendor',
            'vendorName': 'Quick Start Store',
            'stockQuantity': 50,
            'isActive': true,
            'isApproved': true, // Auto-approved for quick start
            'rating': 4.0 + (DateTime.now().millisecond % 10) / 10,
            'reviewCount': 50 + (DateTime.now().millisecond % 100),
            'specifications': {'brand': 'Quick Start', 'warranty': '1 year'},
            'tags': ['bestseller', 'quickstart'],
            'createdAt': Timestamp.now(),
            'colors': [],
            'sizes': [],
          });
          
          // Update with generated ID
          await docRef.update({'id': docRef.id});
          
          // Auto-assign to section will happen via the updated addProduct logic
          await _autoAssignProductToSection(docRef.id, categoryData['category'] as String);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Complete system created! Go to homepage to see your products!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Refresh analysis
      _analyzeFirestoreData();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error in quick start: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Auto-assign product to section (copied from firestore service)
  Future<void> _autoAssignProductToSection(String productId, String category) async {
    try {
      // Find existing section for this category
      final sectionsQuery = await _firestore
          .collection(AppConstants.productSectionsCollection)
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (sectionsQuery.docs.isNotEmpty) {
        // Add to existing section
        final sectionDoc = sectionsQuery.docs.first;
        final currentProductIds = List<String>.from(sectionDoc.data()['productIds'] ?? []);
        
        if (!currentProductIds.contains(productId)) {
          currentProductIds.add(productId);
          await sectionDoc.reference.update({
            'productIds': currentProductIds,
            'updatedAt': Timestamp.now(),
          });
        }
      } else {
        // Create new section for this category
        final sectionTitle = _generateSectionTitle(category);
        
        await _firestore
            .collection(AppConstants.productSectionsCollection)
            .add({
          'title': sectionTitle,
          'subtitle': 'Best deals on $category',
          'category': category,
          'productIds': [productId],
          'seeMoreText': 'See all offers',
          'seeMoreRoute': '/category/$category',
          'displayCount': 4,
          'isActive': true,
          'order': await _getNextSectionOrder(),
          'createdAt': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Warning: Could not auto-assign product to section: $e');
    }
  }

  /// Generate section title based on category
  String _generateSectionTitle(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return 'Starting ₹999 | Electronics';
      case 'fashion':
        return 'Starting ₹299 | Fashion';
      case 'home & kitchen':
        return 'Starting ₹199 | Home & Kitchen';
      case 'books':
        return 'Starting ₹99 | Books';
      case 'sports':
        return 'Starting ₹499 | Sports';
      default:
        return 'Great deals on $category';
    }
  }

  /// Get next section order number
  Future<int> _getNextSectionOrder() async {
    try {
      final sectionsQuery = await _firestore
          .collection(AppConstants.productSectionsCollection)
          .orderBy('order', descending: true)
          .limit(1)
          .get();

      if (sectionsQuery.docs.isNotEmpty) {
        final lastOrder = sectionsQuery.docs.first.data()['order'] as int? ?? 0;
        return lastOrder + 1;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
} 