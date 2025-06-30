import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import '../../providers/product_provider.dart';
import '../../constants/filter_constants.dart';
import '../../widgets/home/product_card.dart';
import '../../widgets/home/top_nav_bar.dart';

/// Screen that displays products for a specific category with filtering and sorting
class CategoryProductsScreen extends ConsumerStatefulWidget {
  final String category;
  final String? subcategory;

  const CategoryProductsScreen({
    super.key,
    required this.category,
    this.subcategory,
  });

  @override
  ConsumerState<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends ConsumerState<CategoryProductsScreen> {
  late String decodedCategory;
  late String? decodedSubcategory;
  bool isLoading = true;
  String? error;
  List<ProductModel> products = [];

  @override
  void initState() {
    super.initState();
    decodedCategory = Uri.decodeComponent(widget.category);
    decodedSubcategory = widget.subcategory != null 
        ? Uri.decodeComponent(widget.subcategory!)
        : null;
    
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Build base query
      Query query = FirebaseFirestore.instance.collection('products');
      
      // Add filters one by one
      query = query.where('category', isEqualTo: decodedCategory);
      
      if (decodedSubcategory != null && decodedSubcategory!.isNotEmpty) {
        query = query.where('subcategory', isEqualTo: decodedSubcategory);
      }
      
      // Add active and approved filters
      query = query.where('isActive', isEqualTo: true);
      query = query.where('isApproved', isEqualTo: true);
      
      // Add sorting
      query = query.orderBy('createdAt', descending: true);

      // Execute query
      final querySnapshot = await query.get();
      
      // Convert to products
      final loadedProducts = querySnapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      setState(() {
        products = loadedProducts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
      debugPrint('Error loading products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Top navigation bar
          const TopNavBar(),
          
          // Breadcrumb navigation
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  decodedCategory,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (decodedSubcategory != null) ...[
                  const Icon(Icons.chevron_right),
                  Text(
                    decodedSubcategory!,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ],
            ),
          ),

          // Main content
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(child: Text('Error: $error'))
                    : products.isEmpty
                        ? const Center(child: Text('No products found'))
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              return ProductCard(product: products[index]);
                            },
                          ),
          ),
        ],
      ),
    );
  }
} 