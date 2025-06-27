import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../constants/app_constants.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _currentImageIndex = 0;
  int _selectedQuantity = 1;
  String _selectedColor = 'Glossy Black';
  bool _isAddingToCart = false;

  // Dummy product data based on the Amazon screenshot
  late Map<String, dynamic> _productData;

  @override
  void initState() {
    super.initState();
    _initializeProductData();
  }

  void _initializeProductData() {
    _productData = {
      'name':
          'Ampere Powered by Greaves Electric Mobility Magnus Neo City Speed Electric Scooter Galactic Grey with Portable Charger Booking for Ex-Showroom (GLOSSY BLACK)',
      'brand': 'Ampere By Happy eCom',
      'rating': 4.4,
      'totalRatings': 20,
      'price': 84999.0,
      'originalPrice': 94999.0,
      'discount': '₹64,99,900 /100 g)',
      'delivery': 'FREE delivery 11 - 12 July.',
      'deliveryTime': 'Order within 12 hrs 29 mins.',
      'location': 'Delivering to Aligarh 202001',
      'soldBy': 'Ampere By Happy eCom',
      'colors': [
        'Glossy Black',
        'Galactic Grey',
        'Pearl White',
        'Crimson Red',
        'Ocean Blue',
      ],
      'images': [
        'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&h=600&fit=crop&crop=center',
        'https://images.unsplash.com/photo-1571068316344-75bc76f77890?w=600&h=600&fit=crop&crop=center',
        'https://images.unsplash.com/photo-1568772585407-9361f9bf3a87?w=600&h=600&fit=crop&crop=center',
        'https://images.unsplash.com/photo-1609630875171-b1321377ee65?w=600&h=600&fit=crop&crop=center',
        'https://images.unsplash.com/photo-1547036967-23d11aacaee0?w=600&h=600&fit=crop&crop=center',
      ],
      'offers': [
        {
          'type': 'Bank Offer',
          'title': 'Upto ₹6,000.00 discount on select Credit Cards, HDFC...',
          'count': '36 offers',
        },
        {
          'type': 'Cashback',
          'title': 'Upto ₹2,549.00 cashback as Amazon Pay Balance when...',
          'count': '1 offer',
        },
        {
          'type': 'No Cost EMI',
          'title': 'Upto ₹3,27,39 EMI interest savings on Amazon Pay ICICI...',
          'count': '1 offer',
        },
        {
          'type': 'Partner Offers',
          'title': 'Get GST invoice and save up to 28% on business purchase',
          'count': '1 offer',
        },
      ],
      'features': [
        'Free Delivery',
        'Non-Returnable',
        '3 Year Warranty',
        'Secure transaction',
      ],
      'specifications': [
        {'key': 'Battery Type', 'value': 'Lithium-ion'},
        {'key': 'Motor Power', 'value': '1200W BLDC'},
        {'key': 'Top Speed', 'value': '55 km/h'},
        {'key': 'Range', 'value': '100 km per charge'},
        {'key': 'Charging Time', 'value': '4-5 hours'},
        {'key': 'Weight', 'value': '85 kg'},
      ],
      'description': '''
The Ampere Magnus Neo is a cutting-edge electric scooter designed for modern urban mobility. With its sleek design and advanced features, it offers an eco-friendly transportation solution without compromising on style or performance.

Key Features:
• High-performance 1200W BLDC motor
• Long-lasting lithium-ion battery
• Smart connectivity features
• LED headlamps and tail lights
• Digital instrument cluster
• Mobile charging port
• Anti-theft alarm system
• Regenerative braking system

This electric scooter is perfect for daily commuting, offering zero emissions and low maintenance costs. The portable charger allows you to charge the vehicle anywhere, making it convenient for urban lifestyle.
      ''',
    };
  }

  /// Creates a ProductModel from the current product data
  ProductModel _createProductModel() {
    return ProductModel(
      id: widget.productId,
      name: _productData['name'] as String,
      description: _productData['description'] as String,
      price: (_productData['price'] as double),
      originalPrice: (_productData['originalPrice'] as double),
      category: 'Sports, Fitness & Outdoors',
      subcategory: 'Electric Scooters',
      imageUrls: List<String>.from(_productData['images']),
      vendorId: 'vendor_1',
      vendorName: _productData['soldBy'] as String,
      stockQuantity: 50, // Default stock
      isActive: true,
      isApproved: true,
      rating: (_productData['rating'] as num).toDouble(),
      reviewCount: _productData['totalRatings'] as int,
      specifications: Map<String, dynamic>.fromEntries(
        (_productData['specifications'] as List).map(
          (spec) => MapEntry(spec['key'] as String, spec['value']),
        ),
      ),
      tags: ['electric', 'scooter', 'eco-friendly', 'urban mobility'],
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      colors: List<String>.from(_productData['colors']),
      sizes: [],
      shippingInfo: {
        'freeDelivery': true,
        'deliveryTime': _productData['deliveryTime'],
        'location': _productData['location'],
      },
    );
  }

  /// Handles adding product to cart
  Future<void> _handleAddToCart() async {
    if (_isAddingToCart) return;

    setState(() {
      _isAddingToCart = true;
    });

    try {
      final cartNotifier = ref.read(cartProvider.notifier);
      final product = _createProductModel();

      await cartNotifier.addToCart(
        product: product,
        quantity: _selectedQuantity,
        selectedColor: _selectedColor,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Added ${_selectedQuantity} item${_selectedQuantity > 1 ? 's' : ''} to cart',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'View Cart',
              textColor: Colors.white,
              onPressed: () {
                context.push('/cart');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to add to cart: ${e.toString()}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBreadcrumb(),
            _buildMainContent(),
            const SizedBox(height: 40),
            _buildBuyItWithSection(),
            const SizedBox(height: 40),
            _buildRelatedProductsSection(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF131921),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Container(
        height: 40,
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search Amazon.in',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            suffixIcon: Container(
              width: 45,
              decoration: const BoxDecoration(
                color: Color(0xFFFF9900),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: const Icon(Icons.search, color: Colors.black),
            ),
          ),
        ),
      ),
      actions: [
        Consumer(
          builder: (context, ref, child) {
            final cartItemCount = ref.watch(cartItemCountProvider);
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart, color: Colors.white),
                  onPressed: () {
                    context.push('/cart');
                  },
                ),
                if (cartItemCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9900),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        cartItemCount.toString(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
      child: const Text(
        'Sports, Fitness & Outdoors › Skates, Skateboards & Scooters › Scooters & Equipment › Scooters › Electric Scooters',
        style: TextStyle(
          fontSize: 12,
          color: Color(0xFF007185),
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - Images
          Expanded(flex: 2, child: _buildImageSection()),
          const SizedBox(width: 24),
          // Middle - Product details
          Expanded(flex: 3, child: _buildProductDetails()),
          const SizedBox(width: 24),
          // Right side - Purchase section
          Container(width: 300, child: _buildPurchaseSection()),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        // Main image
        Container(
          height: 400,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              _productData['images'][_currentImageIndex],
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Thumbnail images
        Row(
          children: [
            // Thumbnail list
            Expanded(
              child: SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _productData['images'].length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      child: Container(
                        width: 70,
                        height: 70,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _currentImageIndex == index
                                ? const Color(0xFF007185)
                                : Colors.grey[300]!,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            _productData['images'][index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Click to see full view
        TextButton(
          onPressed: () {},
          child: const Text(
            'Click to see full view',
            style: TextStyle(color: Color(0xFF007185)),
          ),
        ),
      ],
    );
  }

  Widget _buildProductDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product title
        Text(
          _productData['name'],
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            height: 1.3,
            color: Color(0xFF0F1111),
          ),
        ),
        const SizedBox(height: 8),

        // Brand link
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
          ),
          child: Text(
            'Visit the ${_productData['brand']} Store',
            style: const TextStyle(
              color: Color(0xFF007185),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),

        // Rating
        Row(
          children: [
            Text(
              _productData['rating'].toString(),
              style: const TextStyle(
                color: Color(0xFF007185),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 4),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < _productData['rating'].floor()
                      ? Icons.star
                      : Icons.star_border,
                  color: Color(0xFFFF9900),
                  size: 16,
                );
              }),
            ),
            const SizedBox(width: 8),
            Text(
              '${_productData['totalRatings']} ratings',
              style: const TextStyle(
                color: Color(0xFF007185),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Price section
        _buildPriceSection(),

        const SizedBox(height: 16),

        // Offers section
        _buildOffersSection(),

        const SizedBox(height: 16),

        // Color selection
        _buildColorSelection(),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '₹',
              style: TextStyle(fontSize: 14, color: Color(0xFF0F1111)),
            ),
            Text(
              _productData['price'].toInt().toString().replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (Match m) => '${m[1]},',
              ),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w400,
                color: Color(0xFF0F1111),
              ),
            ),
            const Text(
              '00',
              style: TextStyle(fontSize: 14, color: Color(0xFF0F1111)),
            ),
            const SizedBox(width: 8),
            Text(
              '(₹${_productData['originalPrice'].toInt()}.00)',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF565959),
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _productData['discount'],
          style: const TextStyle(fontSize: 14, color: Color(0xFF565959)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Inclusive of all taxes',
          style: TextStyle(fontSize: 14, color: Color(0xFF565959)),
        ),
        const SizedBox(height: 4),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 14, color: Color(0xFF0F1111)),
            children: [
              TextSpan(text: 'EMI starts at ₹4,121. '),
              TextSpan(
                text: 'No Cost EMI available',
                style: TextStyle(
                  color: Color(0xFF007185),
                  fontWeight: FontWeight.w400,
                ),
              ),
              TextSpan(text: ' '),
              TextSpan(
                text: 'EMI options',
                style: TextStyle(
                  color: Color(0xFF007185),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOffersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.local_offer, size: 16, color: Color(0xFF565959)),
            SizedBox(width: 4),
            Text(
              'Offers',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F1111),
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...(_productData['offers'] as List).map((offer) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCC0C39),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    offer['type'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer['title'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF0F1111),
                        ),
                      ),
                      Text(
                        offer['count'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF007185),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildColorSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Colour: $_selectedColor',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F1111),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: (_productData['colors'] as List<String>).map((color) {
            final isSelected = _selectedColor == color;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                });
              },
              child: Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF007185)
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      child: Image.network(
                        _productData['images'][0],
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${_productData['price'].toInt()}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF0F1111),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Delivery info
        Row(
          children: [
            const Icon(
              Icons.local_shipping,
              size: 16,
              color: Color(0xFF565959),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _productData['delivery'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F1111),
                    fontSize: 14,
                  ),
                ),
                Text(
                  _productData['deliveryTime'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0F1111),
                  ),
                ),
                Text(
                  _productData['location'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF007185),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Sold by
        Row(
          children: [
            const Text(
              'Ships from',
              style: TextStyle(color: Color(0xFF0F1111), fontSize: 14),
            ),
            const SizedBox(width: 8),
            Text(
              _productData['soldBy'],
              style: const TextStyle(
                color: Color(0xFF007185),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        Row(
          children: [
            const Text(
              'Sold by',
              style: TextStyle(color: Color(0xFF0F1111), fontSize: 14),
            ),
            const SizedBox(width: 8),
            Text(
              _productData['soldBy'],
              style: const TextStyle(
                color: Color(0xFF007185),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Payment
        Row(
          children: [
            const Text(
              'Payment',
              style: TextStyle(color: Color(0xFF0F1111), fontSize: 14),
            ),
            const SizedBox(width: 8),
            const Text(
              'Secure transaction',
              style: TextStyle(
                color: Color(0xFF007185),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Quantity and buttons
        Row(
          children: [
            const Text(
              'Quantity: ',
              style: TextStyle(
                color: Color(0xFF0F1111),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            _buildQuantityDropdown(),
          ],
        ),

        const SizedBox(height: 16),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isAddingToCart ? null : _handleAddToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9900),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isAddingToCart
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Adding...',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Add to Cart',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9900),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Buy Now',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Add to wish list
        TextButton(
          onPressed: () {},
          child: const Text(
            'Add to Wish List',
            style: TextStyle(
              color: Color(0xFF007185),
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price section
          Row(
            children: [
              const Text(
                '₹',
                style: TextStyle(fontSize: 18, color: Color(0xFF0F1111)),
              ),
              Text(
                _productData['price'].toInt().toString().replaceAllMapped(
                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                  (Match m) => '${m[1]},',
                ),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF0F1111),
                ),
              ),
              const Text(
                '00',
                style: TextStyle(fontSize: 18, color: Color(0xFF0F1111)),
              ),
            ],
          ),
          Text(
            '(₹${_productData['originalPrice'].toInt()}.00 /100 g)',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF565959),
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(height: 16),

          // Delivery info
          Text(
            _productData['delivery'],
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F1111),
              fontSize: 14,
            ),
          ),
          Text(
            _productData['deliveryTime'],
            style: const TextStyle(fontSize: 14, color: Color(0xFF0F1111)),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
            child: const Text(
              'Details',
              style: TextStyle(
                color: Color(0xFF007185),
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Location
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Color(0xFF565959)),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _productData['location'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF007185),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                    child: const Text(
                      'Update location',
                      style: TextStyle(
                        color: Color(0xFF007185),
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Ships from and Sold by
          _buildInfoRow('Ships from', _productData['soldBy']),
          const SizedBox(height: 8),
          _buildInfoRow('Sold by', _productData['soldBy']),
          const SizedBox(height: 8),
          _buildInfoRow('Payment', 'Secure transaction'),

          const SizedBox(height: 20),

          // Protection Plan
          const Text(
            'Add a Protection Plan:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F1111),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: false,
                onChanged: (value) {},
                activeColor: Color(0xFF007185),
              ),
              const Expanded(
                child: Text(
                  '1 Year Fire Protection Plan for ₹99.00',
                  style: TextStyle(
                    color: Color(0xFF007185),
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Quantity selector
          Row(
            children: [
              const Text(
                'Quantity: ',
                style: TextStyle(
                  color: Color(0xFF0F1111),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _buildQuantityDropdown(),
            ],
          ),

          const SizedBox(height: 24),

          // Action buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isAddingToCart ? null : _handleAddToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD814),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: _isAddingToCart
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Adding...',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'Add to Cart',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),

          const SizedBox(width: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9900),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Buy Now',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Add to wish list
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                side: const BorderSide(color: Colors.grey),
              ),
              child: const Text(
                'Add to Wish List',
                style: TextStyle(
                  color: Color(0xFF0F1111),
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF0F1111), fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF007185),
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityDropdown() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD5D9D9), width: 1),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedQuantity,
                isDense: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFF565959),
                  size: 20,
                ),
                style: const TextStyle(
                  color: Color(0xFF0F1111),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                dropdownColor: Colors.white,
                items: List.generate(30, (index) {
                  return DropdownMenuItem(
                    value: index + 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Color(0xFF0F1111),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }),
                onChanged: (value) {
                  setState(() {
                    _selectedQuantity = value!;
                  });
                },
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyItWithSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Buy it with',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F1111),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Main product
              Expanded(
                flex: 3,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: true,
                      onChanged: (value) {},
                      activeColor: const Color(0xFF007185),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(
                              productId: 'main_product_${widget.productId}',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.network(
                            _productData['images'][0],
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                color: Color(0xFF0F1111),
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: 'This item: ',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                TextSpan(
                                  text:
                                      'Ampere Powered by Greaves Electric Mobility Magnus Neo City Speed Electric Scooter...',
                                  style: TextStyle(color: Color(0xFF007185)),
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '₹84,999⁰⁰',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F1111),
                              fontSize: 16,
                            ),
                          ),
                          const Text(
                            '(₹84,99,900.00/100 g)',
                            style: TextStyle(
                              color: Color(0xFF565959),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Plus sign
              const Icon(Icons.add, size: 20, color: Color(0xFF565959)),

              const SizedBox(width: 16),

              // Additional product
              Expanded(
                flex: 3,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: true,
                      onChanged: (value) {},
                      activeColor: const Color(0xFF007185),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(
                              productId: 'additional_product_salt_001',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.network(
                            'https://images.unsplash.com/photo-1586985289688-ca3cf47d3e6e?w=200&h=200&fit=crop&crop=center',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Aashirvaad Salt with 4-Step advantage, 1kg',
                            style: TextStyle(
                              color: Color(0xFF007185),
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '₹40⁰⁰',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F1111),
                              fontSize: 16,
                            ),
                          ),
                          const Text(
                            '(₹4.00/100 g)',
                            style: TextStyle(
                              color: Color(0xFF565959),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Total and button section
              Container(
                width: 250,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Total price: ₹85,039.00',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F1111),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD814),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Add both to Cart',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.info,
                          size: 16,
                          color: Color(0xFF007185),
                        ),
                        const SizedBox(width: 4),
                        const Expanded(
                          child: Text(
                            'Some of these items are dispatched sooner than the others.',
                            style: TextStyle(
                              color: Color(0xFF0F1111),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                      child: const Text(
                        'Show details',
                        style: TextStyle(
                          color: Color(0xFF007185),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedProductsSection() {
    final relatedProducts = [
      {
        'name':
            'WAAREE 450 Watt Mono PERC Solar Panel - High-Efficiency Half-Cut Technology | BIS...',
        'image':
            'https://images.unsplash.com/photo-1509391366360-2e959784a276?w=200&h=200&fit=crop&crop=center',
        'rating': 4.2,
        'reviews': 82,
        'originalPrice': '₹59,999.00',
        'price': '₹20,999⁰⁰',
        'discount': '-65%',
        'prime': true,
      },
      {
        'name':
            'Amazon Brand - Solimo Bike Cover for Honda Activa with Carry Bag | Water Resistant...',
        'image':
            'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=200&h=200&fit=crop&crop=center',
        'rating': 4.1,
        'reviews': 823,
        'originalPrice': '₹999.00',
        'price': '₹309²²',
        'discount': '-69%',
        'prime': true,
      },
      {
        'name':
            'UBOARD X7 Electric Scooter: Max Speed 25 km/h, Range 25 km, 5 Speed Modes, 3-Hour F...',
        'image':
            'https://images.unsplash.com/photo-1571068316344-75bc76f77890?w=200&h=200&fit=crop&crop=center',
        'rating': 4.0,
        'reviews': 53,
        'originalPrice': '₹49,999.00',
        'price': '₹36,499⁰⁰',
        'discount': '-27%',
        'choice': true,
      },
      {
        'name':
            'Crompton PRIMO II | Water Pump | 0.5 HP | Self-Priming | Single Phase | Anti-Jam Wi...',
        'image':
            'https://images.unsplash.com/photo-1581092918056-0c4c3acd3789?w=200&h=200&fit=crop&crop=center',
        'rating': 4.2,
        'reviews': 132,
        'originalPrice': '₹4,175.00',
        'price': '₹2,589⁰⁰',
        'discount': '-38%',
        'prime': true,
      },
      {
        'name':
            'KOUREVON 8" Big Wheels 4 Height Adjustable, Max Load 240 kg Big Scooter...',
        'image':
            'https://images.unsplash.com/photo-1568772585407-9361f9bf3a87?w=200&h=200&fit=crop&crop=center',
        'rating': 4.2,
        'reviews': 28,
        'originalPrice': '₹5,999.00',
        'price': '₹2,999⁰⁰',
        'discount': '-60%',
        'prime': true,
      },
      {
        'name':
            'TVS Ronin Windshield Visor | Stylish Wind Deflectors and Protector, Modern Retro Sts...',
        'image':
            'https://images.unsplash.com/photo-1609630875171-b1321377ee65?w=200&h=200&fit=crop&crop=center',
        'rating': 4.3,
        'reviews': 134,
        'price': '₹1,199⁰⁰',
        'choice': true,
        'prime': true,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Related products with free delivery on eligible orders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F1111),
                ),
              ),
              Row(
                children: [
                  const Text(
                    'Sponsored',
                    style: TextStyle(fontSize: 12, color: Color(0xFF565959)),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.info_outline,
                    size: 12,
                    color: Color(0xFF565959),
                  ),
                  const SizedBox(width: 20),
                  const Text(
                    'Page 1 of 5',
                    style: TextStyle(fontSize: 12, color: Color(0xFF0F1111)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.arrow_back_ios, size: 16),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  shape: const CircleBorder(),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 320,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: relatedProducts.length,
                    itemBuilder: (context, index) {
                      final product = relatedProducts[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(
                                productId: 'related_product_$index',
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product image
                                Container(
                                  height: 120,
                                  width: double.infinity,
                                  child: Image.network(
                                    product['image']! as String,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Product name
                                Text(
                                  product['name']! as String,
                                  style: const TextStyle(
                                    color: Color(0xFF007185),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 8),

                                // Rating
                                Row(
                                  children: [
                                    Row(
                                      children: List.generate(5, (starIndex) {
                                        return Icon(
                                          starIndex <
                                                  (product['rating'] as double)
                                                      .floor()
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: const Color(0xFFFF9900),
                                          size: 14,
                                        );
                                      }),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      (product['reviews']! as int).toString(),
                                      style: const TextStyle(
                                        color: Color(0xFF007185),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // Price and discount
                                if (product['discount'] != null)
                                  Text(
                                    product['discount']! as String,
                                    style: const TextStyle(
                                      color: Color(0xFFCC0C39),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),

                                Text(
                                  product['price']! as String,
                                  style: const TextStyle(
                                    color: Color(0xFF0F1111),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),

                                if (product['originalPrice'] != null)
                                  Text(
                                    'M.R.P: ${product['originalPrice']! as String}',
                                    style: const TextStyle(
                                      color: Color(0xFF565959),
                                      fontSize: 12,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),

                                const SizedBox(height: 8),

                                // Badges
                                if ((product['choice'] as bool?) == true)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF9900),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: const Text(
                                      "Amazon's Choice",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),

                                if ((product['prime'] as bool?) == true)
                                  const Text(
                                    'prime',
                                    style: TextStyle(
                                      color: Color(0xFF007185),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
