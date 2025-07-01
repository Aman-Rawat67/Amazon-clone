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
import 'package:uuid/uuid.dart';

/// Provider for product categories
final productCategoriesProvider = Provider<List<String>>((ref) {
  return [
    'Clothing',
    'Electronics',
    'Handloom',
    'Automotive',
    'Home',
  ];
});

/// Provider for product subcategories
final productSubcategoriesProvider = Provider<Map<String, List<String>>>((ref) {
  return {
    'Clothing': [
      'Men',
      'Women',
      'Unisex',
      'Boy',
      'Girl',
    ],
    'Electronics': [
      'Mobile Phones',
      'Computers & Laptops',
      'Audio Devices',
      'Home Appliances',
    ],
    'Handloom': [
      'Bedsheets',
      'Curtains',
      'Mattress',
      'Pillow',
    ],
    'Automotive': [
      'Car Perfume',
      'Stereo',
      'Dash Cam',
      'Cameras',
    ],
    'Home': [
      'Kitchen',
      'Gardening',
      'Interior',
      'Furniture',
    ],
  };
});

/// Class to hold color variant data
class ColorVariant {
  final String color;
  final List<String> imageUrls;
  final TextEditingController imageUrlsController;

  ColorVariant({
    required this.color,
    List<String>? imageUrls,
  }) : imageUrls = imageUrls ?? [],
       imageUrlsController = TextEditingController(
         text: imageUrls?.join('\n') ?? ''
       );

  void dispose() {
    imageUrlsController.dispose();
  }

  Map<String, dynamic> toMap() {
    return {
      'color': color,
      'imageUrls': imageUrls,
    };
  }
}

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
  final _colorController = TextEditingController();
  
  String _selectedCategory = '';
  String _selectedSubcategory = '';
  List<String> _tags = [];
  final _tagController = TextEditingController();
  
  // Color variants list
  List<ColorVariant> _colorVariants = [];
  
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
    _colorController.dispose();
    for (final variant in _colorVariants) {
      variant.dispose();
    }
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
              // Product Colors & Images
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
          'Product Colors & Images',
          style: TextStyle(
            fontSize: AppDimensions.fontLarge,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        const Text(
          'Add colors and their corresponding images. Each color should have at least one image.',
          style: TextStyle(
            color: Colors.black87,
            fontSize: AppDimensions.fontSmall,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),

        // Add new color form
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add New Color',
                  style: TextStyle(
                    fontSize: AppDimensions.fontMedium,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingSmall),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _colorController,
                        label: 'Color Name',
                        hint: 'e.g., Red, Blue, Green',
                        style: const TextStyle(color: Colors.black),
                        hintStyle: const TextStyle(color: Colors.black54),
                        labelStyle: const TextStyle(color: Colors.black87),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a color name';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingSmall),
                    ElevatedButton.icon(
                      onPressed: _addColorVariant,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Color'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.paddingMedium,
                          vertical: AppDimensions.paddingSmall,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),

        // Color variants list
        if (_colorVariants.isEmpty)
          Card(
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.palette_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: AppDimensions.paddingSmall),
                  Text(
                    'No Colors Added Yet',
                    style: TextStyle(
                      fontSize: AppDimensions.fontMedium,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingSmall),
                  Text(
                    'Add at least one color variant with images',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _colorVariants.length,
            itemBuilder: (context, index) {
              final variant = _colorVariants[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Color header
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _getColorFromName(variant.color),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.paddingSmall),
                          Text(
                            variant.color,
                            style: const TextStyle(
                              fontSize: AppDimensions.fontMedium,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _removeColorVariant(index),
                            tooltip: 'Remove Color',
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingMedium),
                      
                      // Image URLs
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Images',
                                style: TextStyle(
                                  fontSize: AppDimensions.fontMedium,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: AppDimensions.paddingSmall),
                              Text(
                                '(One URL per line)',
                                style: TextStyle(
                                  fontSize: AppDimensions.fontSmall,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.paddingSmall),
                          CustomTextField(
                            controller: variant.imageUrlsController,
                            label: 'Image URLs for {variant.color}',
                            hint: 'https://example.com/image1.jpg\nhttps://example.com/image2.jpg',
                            maxLines: 3,
                            style: const TextStyle(color: Colors.black),
                            hintStyle: const TextStyle(color: Colors.black54),
                            labelStyle: const TextStyle(color: Colors.black87),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please add at least one image URL';
                              }
                              final urls = value.split('\n')
                                  .where((url) => url.trim().isNotEmpty)
                                  .toList();
                              if (urls.isEmpty) {
                                return 'Please add at least one valid image URL';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      
                      // Image preview
                      const SizedBox(height: AppDimensions.paddingMedium),
                      _buildImagePreview(variant),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildImagePreview(ColorVariant variant) {
    final urls = variant.imageUrlsController.text
        .split('\n')
        .where((url) => url.trim().isNotEmpty)
        .map((url) => url.trim())
        .toList();

    if (urls.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, color: Colors.grey[400]),
            const SizedBox(width: AppDimensions.paddingSmall),
            Text(
              'No images added yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Image Preview',
          style: TextStyle(
            fontSize: AppDimensions.fontMedium,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: urls.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: AppDimensions.paddingSmall),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    urls[index],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey[400],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getColorFromName(String colorName) {
    final normalizedColor = colorName.toLowerCase().trim();
    switch (normalizedColor) {
      case 'red': return Colors.red;
      case 'blue': return Colors.blue;
      case 'green': return Colors.green;
      case 'yellow': return Colors.yellow;
      case 'purple': return Colors.purple;
      case 'orange': return Colors.orange;
      case 'pink': return Colors.pink;
      case 'brown': return Colors.brown;
      case 'grey':
      case 'gray': return Colors.grey;
      case 'black': return Colors.black;
      case 'white': return Colors.white;
      default: return Colors.grey.shade300;
    }
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
              _selectedCategory = value ?? '';
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
                _selectedSubcategory = value ?? '';
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
          controller: _colorController,
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

  void _addColorVariant() {
    final color = _colorController.text.trim();
    if (color.isNotEmpty) {
      setState(() {
        _colorVariants.add(ColorVariant(color: color));
        _colorController.clear();
      });
    }
  }

  void _removeColorVariant(int index) {
    setState(() {
      _colorVariants[index].dispose();
      _colorVariants.removeAt(index);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_colorVariants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one color variant')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(userProvider).value;
      if (user == null) throw Exception('User not found');

      // Process color variants and their images
      final colorVariants = _colorVariants.map((variant) {
        final urls = variant.imageUrlsController.text
            .split('\n')
            .where((url) => url.trim().isNotEmpty)
            .map((url) => url.trim())
            .toList();
        
        if (urls.isEmpty) throw Exception('Please add at least one image for ${variant.color}');
        
        return {
          'color': variant.color,
          'imageUrls': urls,
        };
      }).toList();

      // Get all image URLs across all color variants
      final allImageUrls = colorVariants
          .expand((variant) => variant['imageUrls'] as List<String>)
          .toList();

      if (allImageUrls.isEmpty) {
        throw Exception('Please add at least one image');
      }

      // Get all colors
      final colors = _colorVariants.map((variant) => variant.color).toList();

      // Get sizes
      final sizes = _sizesController.text
          .split(',')
          .map((size) => size.trim())
          .where((size) => size.isNotEmpty)
          .toList();

      // Create normalized category and subcategory
      final normalizedCategory = _selectedCategory.trim();
      final normalizedSubcategory = _selectedSubcategory.trim();

      // Create product model
      final product = ProductModel(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        originalPrice: _originalPriceController.text.isEmpty 
            ? null 
            : double.parse(_originalPriceController.text),
        category: normalizedCategory,
        subcategory: normalizedSubcategory,
        categoryLower: normalizedCategory.toLowerCase(),
        subcategoryLower: normalizedSubcategory.toLowerCase(),
        imageUrls: allImageUrls,
        vendorId: user.id,
        vendorName: user.name,
        stockQuantity: int.parse(_stockController.text),
        isActive: _isActive,
        isApproved: _autoApprove,
        specifications: _getSpecifications(),
        tags: _tags,
        colors: colors,
        sizes: sizes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        // Add color variants as part of specifications
        shippingInfo: {
          'colorVariants': colorVariants,
        },
      );

      // Save to Firestore
      await ref.read(firestoreServiceProvider).addProduct(product);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully')),
        );
        context.go('/vendor/products');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, dynamic> _getSpecifications() {
    final Map<String, dynamic> specifications = {};
    for (int i = 0; i < _specKeyControllers.length; i++) {
      final key = _specKeyControllers[i].text.trim();
      final value = _specValueControllers[i].text.trim();
      if (key.isNotEmpty && value.isNotEmpty) {
        specifications[key] = value;
      }
    }
    return specifications;
  }
} 