import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../constants/app_constants.dart';
import '../../models/product_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_button.dart';

/// Provider for product categories
final productCategoriesProvider = Provider<List<String>>((ref) {
  return [
    'Electronics',
    'Clothing',
    'Books',
    'Home & Garden',
    'Sports & Outdoors',
    'Beauty & Personal Care',
    'Toys & Games',
    'Automotive',
    'Health & Wellness',
    'Food & Beverages',
  ];
});

/// Provider for product subcategories
final productSubcategoriesProvider = Provider<Map<String, List<String>>>((ref) {
  return {
    'Electronics': ['Smartphones', 'Laptops', 'Tablets', 'Accessories', 'Audio', 'Cameras'],
    'Clothing': ['Men', 'Women', 'Kids', 'Shoes', 'Accessories', 'Jewelry'],
    'Books': ['Fiction', 'Non-Fiction', 'Educational', 'Children', 'Comics', 'Magazines'],
    'Home & Garden': ['Furniture', 'Decor', 'Kitchen', 'Garden', 'Tools', 'Lighting'],
    'Sports & Outdoors': ['Fitness', 'Outdoor', 'Team Sports', 'Water Sports', 'Camping'],
    'Beauty & Personal Care': ['Skincare', 'Makeup', 'Hair Care', 'Fragrances', 'Bath & Body'],
    'Toys & Games': ['Action Figures', 'Board Games', 'Puzzles', 'Educational', 'Outdoor Toys'],
    'Automotive': ['Parts', 'Accessories', 'Tools', 'Maintenance', 'Electronics'],
    'Health & Wellness': ['Vitamins', 'Supplements', 'Medical Devices', 'Fitness Equipment'],
    'Food & Beverages': ['Snacks', 'Beverages', 'Organic', 'Gourmet', 'Supplements'],
  };
});

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _sizesController = TextEditingController();
  final _colorsController = TextEditingController();
  final _imageUrlsController = TextEditingController();
  
  String _selectedCategory = '';
  String _selectedSubcategory = '';
  List<String> _tags = [];
  final _tagController = TextEditingController();
  
  bool _isLoading = false;
  bool _isActive = true;
  bool _autoApprove = false; // For testing - auto approve products
  
  // Product Specifications controllers
  List<TextEditingController> _specKeyControllers = [];
  List<TextEditingController> _specValueControllers = [];
  
  @override
  void initState() {
    super.initState();
    final categories = ref.read(productCategoriesProvider);
    if (categories.isNotEmpty) {
      _selectedCategory = categories.first;
    }
    // Add one empty specification row by default
    _specKeyControllers.add(TextEditingController());
    _specValueControllers.add(TextEditingController());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    _tagController.dispose();
    _sizesController.dispose();
    _imageUrlsController.dispose();
    _colorsController.dispose();
    for (final c in _specKeyControllers) {
      c.dispose();
    }
    for (final c in _specValueControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(productCategoriesProvider);
    final subcategories = ref.watch(productSubcategoriesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProduct,
            child: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Images
              _buildImageSection(),
              const SizedBox(height: AppDimensions.paddingLarge),
              
              // Basic Information
              _buildBasicInformationSection(),
              const SizedBox(height: AppDimensions.paddingLarge),
              
              // Pricing
              _buildPricingSection(),
              const SizedBox(height: AppDimensions.paddingLarge),
              
              // Category & Tags
              _buildCategorySection(categories, subcategories),
              const SizedBox(height: AppDimensions.paddingLarge),
              
              // Sizes & Colors
              _buildSizesColorsSection(),
              const SizedBox(height: AppDimensions.paddingLarge),
              
              // Tags
              _buildTagsSection(),
              const SizedBox(height: AppDimensions.paddingLarge),

              // Product Specifications Section
              _buildSpecificationsSection(),
              const SizedBox(height: AppDimensions.paddingLarge),
              
              // Status
              _buildStatusSection(),
              const SizedBox(height: AppDimensions.paddingLarge),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: LoadingButton(
                  onPressed: _saveProduct,
                  isLoading: _isLoading,
                  text: 'Add Product',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Image URLs',
          style: TextStyle(
            fontSize: AppDimensions.fontLarge,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        const Text(
          'Enter one or more image URLs (comma separated or one per line). The first image will be the main image.',
          style: TextStyle(
            color: Colors.black87,
            fontSize: AppDimensions.fontSmall,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        CustomTextField(
          controller: _imageUrlsController,
          label: 'Image URLs',
          hint: 'https://example.com/image1.jpg, https://example.com/image2.jpg',
          maxLines: 3,
          style: const TextStyle(color: Colors.black),
          hintStyle: const TextStyle(color: Colors.black54),
          labelStyle: const TextStyle(color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildBasicInformationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Information',
          style: TextStyle(
            fontSize: AppDimensions.fontLarge,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        
        CustomTextField(
          controller: _nameController,
          label: 'Product Name',
          hint: 'Enter product name',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Product name is required';
            }
            return null;
          },
          style: const TextStyle(color: Colors.black),
          hintStyle: const TextStyle(color: Colors.black54),
          labelStyle: const TextStyle(color: Colors.black87),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        
        CustomTextField(
          controller: _descriptionController,
          label: 'Description',
          hint: 'Enter product description',
          maxLines: 4,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Product description is required';
            }
            return null;
          },
          style: const TextStyle(color: Colors.black),
          hintStyle: const TextStyle(color: Colors.black54),
          labelStyle: const TextStyle(color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pricing & Stock',
          style: TextStyle(
            fontSize: AppDimensions.fontLarge,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _priceController,
                label: 'Price',
                hint: '0.00',
                keyboardType: TextInputType.number,
                prefix: const Text(
                  AppConstants.currencySymbol,
                  style: TextStyle(color: Colors.black87),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Price is required';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
                style: const TextStyle(color: Colors.black),
                hintStyle: const TextStyle(color: Colors.black54),
                labelStyle: const TextStyle(color: Colors.black87),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Expanded(
              child: CustomTextField(
                controller: _originalPriceController,
                label: 'Original Price (Optional)',
                hint: '0.00',
                keyboardType: TextInputType.number,
                prefix: const Text(
                  AppConstants.currencySymbol,
                  style: TextStyle(color: Colors.black87),
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Please enter a valid price';
                    }
                    final currentPrice = double.tryParse(_priceController.text) ?? 0;
                    if (price <= currentPrice) {
                      return 'Original price must be higher than current price';
                    }
                  }
                  return null;
                },
                style: const TextStyle(color: Colors.black),
                hintStyle: const TextStyle(color: Colors.black54),
                labelStyle: const TextStyle(color: Colors.black87),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        
        CustomTextField(
          controller: _stockController,
          label: 'Stock Quantity',
          hint: '0',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Stock quantity is required';
            }
            final stock = int.tryParse(value);
            if (stock == null || stock < 0) {
              return 'Please enter a valid stock quantity';
            }
            return null;
          },
          style: const TextStyle(color: Colors.black),
          hintStyle: const TextStyle(color: Colors.black54),
          labelStyle: const TextStyle(color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildCategorySection(List<String> categories, Map<String, List<String>> subcategories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontSize: AppDimensions.fontLarge,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        
        DropdownButtonFormField<String>(
          value: _selectedCategory.isNotEmpty ? _selectedCategory : null,
          decoration: const InputDecoration(
            labelText: 'Category',
            labelStyle: TextStyle(color: Colors.black87),
            border: OutlineInputBorder(),
          ),
          items: categories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(
                category,
                style: const TextStyle(color: Colors.black),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value!;
              _selectedSubcategory = '';
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a category';
            }
            return null;
          },
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        
        if (_selectedCategory.isNotEmpty && subcategories[_selectedCategory] != null)
          DropdownButtonFormField<String>(
            value: _selectedSubcategory.isNotEmpty ? _selectedSubcategory : null,
            decoration: const InputDecoration(
              labelText: 'Subcategory',
              labelStyle: TextStyle(color: Colors.black87),
              border: OutlineInputBorder(),
            ),
            items: subcategories[_selectedCategory]!.map((subcategory) {
              return DropdownMenuItem(
                value: subcategory,
                child: Text(
                  subcategory,
                  style: const TextStyle(color: Colors.black),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSubcategory = value!;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a subcategory';
              }
              return null;
            },
          ),
      ],
    );
  }

  Widget _buildSizesColorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sizes (comma separated)',
          style: TextStyle(
            fontSize: AppDimensions.fontLarge,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        CustomTextField(
          controller: _sizesController,
          label: 'Sizes',
          hint: 'e.g. S, M, L, XL',
          style: const TextStyle(color: Colors.black),
          hintStyle: const TextStyle(color: Colors.black54),
          labelStyle: const TextStyle(color: Colors.black87),
        ),
        const SizedBox(height: AppDimensions.paddingLarge),
        const Text(
          'Colors (comma separated)',
          style: TextStyle(
            fontSize: AppDimensions.fontLarge,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        CustomTextField(
          controller: _colorsController,
          label: 'Colors',
          hint: 'e.g. Red, Blue, Green',
          style: const TextStyle(color: Colors.black),
          hintStyle: const TextStyle(color: Colors.black54),
          labelStyle: const TextStyle(color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(
            fontSize: AppDimensions.fontLarge,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        const Text(
          'Add tags to help customers find your product',
          style: TextStyle(
            color: Colors.black87,
            fontSize: AppDimensions.fontSmall,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _tagController,
                label: 'Add Tag',
                hint: 'Enter a tag and press +',
                onSubmitted: (value) => _addTag(value),
                style: const TextStyle(color: Colors.black),
                hintStyle: const TextStyle(color: Colors.black54),
                labelStyle: const TextStyle(color: Colors.black87),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingSmall),
            IconButton(
              onPressed: () => _addTag(_tagController.text),
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        
        if (_tags.isNotEmpty)
          Wrap(
            spacing: AppDimensions.paddingSmall,
            runSpacing: AppDimensions.paddingSmall,
            children: _tags.map((tag) => _buildTagChip(tag)).toList(),
          ),
      ],
    );
  }

  Widget _buildTagChip(String tag) {
    return Chip(
      label: Text(tag, style: const TextStyle(color: Colors.black)),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: () => _removeTag(tag),
    );
  }

  Widget _buildSpecificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Specifications',
          style: TextStyle(
            fontSize: AppDimensions.fontLarge,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        ...List.generate(_specKeyControllers.length, (i) => Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _specKeyControllers[i],
                label: 'Key',
                hint: 'e.g. Brand',
                style: const TextStyle(color: Colors.black),
                hintStyle: const TextStyle(color: Colors.black54),
                labelStyle: const TextStyle(color: Colors.black87),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CustomTextField(
                controller: _specValueControllers[i],
                label: 'Value',
                hint: 'e.g. Apple',
                style: const TextStyle(color: Colors.black),
                hintStyle: const TextStyle(color: Colors.black54),
                labelStyle: const TextStyle(color: Colors.black87),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: _specKeyControllers.length > 1
                  ? () {
                      setState(() {
                        _specKeyControllers.removeAt(i);
                        _specValueControllers.removeAt(i);
                      });
                    }
                  : null,
            ),
          ],
        )),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _specKeyControllers.add(TextEditingController());
                _specValueControllers.add(TextEditingController());
              });
            },
            icon: const Icon(Icons.add, color: AppColors.primary),
            label: const Text(
              'Add Specification',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(
            fontSize: AppDimensions.fontLarge,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        
        SwitchListTile(
          title: const Text(
            'Active',
            style: TextStyle(color: Colors.black),
          ),
          subtitle: const Text(
            'Make this product visible to customers',
            style: TextStyle(color: Colors.black87),
          ),
          value: _isActive,
          onChanged: (value) {
            setState(() {
              _isActive = value;
            });
          },
        ),
        
        SwitchListTile(
          title: const Text(
            'Auto-Approve (Testing)',
            style: TextStyle(color: Colors.black),
          ),
          subtitle: const Text(
            'Skip admin approval - for testing only',
            style: TextStyle(color: Colors.black87),
          ),
          value: _autoApprove,
          onChanged: (value) {
            setState(() {
              _autoApprove = value;
            });
          },
        ),
      ],
    );
  }

  void _addTag(String tag) {
    if (tag.trim().isNotEmpty && !_tags.contains(tag.trim())) {
      setState(() {
        _tags.add(tag.trim());
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_imageUrlsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one product image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(userProvider).asData?.value;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Parse image URLs
      final imageUrls = _imageUrlsController.text
          .replaceAll('\n', ',')
          .split(',')
          .map((url) => url.trim())
          .where((url) => url.isNotEmpty)
          .toList();

      // Parse sizes/colors
      final sizes = _sizesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      final colors = _colorsController.text.split(',').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();

      // Parse specifications
      final Map<String, String> specifications = {};
      for (int i = 0; i < _specKeyControllers.length; i++) {
        final key = _specKeyControllers[i].text.trim();
        final value = _specValueControllers[i].text.trim();
        if (key.isNotEmpty && value.isNotEmpty) {
          specifications[key] = value;
        }
      }

      // Create product
      final product = ProductModel(
        id: '', // Will be set by Firestore
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        originalPrice: _originalPriceController.text.isNotEmpty 
            ? double.parse(_originalPriceController.text) 
            : null,
        category: _selectedCategory,
        subcategory: _selectedSubcategory,
        imageUrls: imageUrls,
        vendorId: user.id,
        vendorName: user.name,
        stockQuantity: int.parse(_stockController.text),
        isActive: _isActive,
        isApproved: _autoApprove, // Auto-approve if testing flag is enabled
        tags: _tags,
        sizes: sizes,
        colors: colors,
        createdAt: DateTime.now(),
        specifications: specifications,
      );

      await FirestoreService().addProduct(product);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_autoApprove 
                ? 'Product added and auto-approved! Live on homepage now.' 
                : 'Product added successfully! Pending admin approval.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/vendor/products');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 