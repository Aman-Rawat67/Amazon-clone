import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/cart_provider.dart';
import '../../models/cart_model.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  Map<String, bool> _checkedItems = {};

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: cartState.when(
        data: (cart) {
          if (cart == null || cart.items.isEmpty) {
            return _buildEmptyCart();
          }
          return _buildCartContent(cart, cartNotifier);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(),
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
                  onPressed: () {},
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

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          const Text(
            'Your Amazon Cart is empty',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F1111),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Shop today\'s deals',
              style: TextStyle(
                color: Color(0xFF007185),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Error loading cart'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.refresh(cartProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(CartModel cart, CartNotifier cartNotifier) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main cart content (left side)
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCartHeader(cart),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    return _buildCartItem(cart.items[index], cartNotifier);
                  },
                ),
              ),
              _buildYourItems(),
            ],
          ),
        ),
        // Right sidebar
        Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          child: _buildCartSummary(cart),
        ),
      ],
    );
  }

  Widget _buildCartHeader(CartModel cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 14, color: Color(0xFF0F1111)),
                  children: [
                    TextSpan(text: 'Part of your order qualifies for '),
                    TextSpan(
                      text: 'FREE Delivery',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: '. Choose '),
                    TextSpan(
                      text: 'FREE Delivery',
                      style: TextStyle(color: Color(0xFF007185)),
                    ),
                    TextSpan(text: ' option at checkout.'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Shopping Cart',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w400,
              color: Color(0xFF0F1111),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
            child: const Text(
              'Deselect all items',
              style: TextStyle(
                color: Color(0xFF007185),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Price',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F1111),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, CartNotifier cartNotifier) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          Checkbox(
            value: _checkedItems[item.id] ?? true,
            onChanged: (value) {
              setState(() {
                _checkedItems[item.id] = value ?? false;
              });
            },
            activeColor: const Color(0xFF007185),
          ),
          const SizedBox(width: 16),
          // Product Image
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.product.imageUrls.isNotEmpty 
                    ? item.product.imageUrls.first 
                    : 'https://via.placeholder.com/180',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                    const Icon(Icons.image, size: 60),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF007185),
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                const Text(
                  'In stock',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Eligible for FREE Shipping',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF0F1111),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF232f3e),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Text(
                    'prime',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (item.selectedColor != null)
                  Text(
                    'Colour: ${item.selectedColor}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                const SizedBox(height: 12),
                // Action buttons row
                Row(
                  children: [
                    // Quantity selector
                    _buildQuantitySelector(item, cartNotifier, _checkedItems[item.id] ?? true),
                    const SizedBox(width: 16),
                    // Save for later
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Save for later',
                        style: TextStyle(
                          color: Color(0xFF007185),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // See more like this
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'See more like this',
                        style: TextStyle(
                          color: Color(0xFF007185),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Share
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Share',
                        style: TextStyle(
                          color: Color(0xFF007185),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Price section
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (item.product.hasDiscount)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCC0C39),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    '${item.product.discountPercentage.toInt()}% off',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text(
                    '₹',
                    style: TextStyle(fontSize: 14, color: Color(0xFF0F1111)),
                  ),
                  Text(
                    item.product.price.toInt().toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]},',
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                  const Text(
                    '00',
                    style: TextStyle(fontSize: 14, color: Color(0xFF0F1111)),
                  ),
                ],
              ),
              if (item.product.hasDiscount)
                Text(
                  'M.R.P: ₹${item.product.originalPrice!.toInt()}.00',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF565959),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYourItems() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Your Items',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: Color(0xFF0F1111),
            ),
          ),
          const SizedBox(height: 16),
          
          // Tab buttons
          Row(
            children: [
              _buildTabButton('Saved for later (4 items)', true),
              const SizedBox(width: 12),
              _buildTabButton('Buy it again', false),
            ],
          ),
          const SizedBox(height: 16),
          
          // Category filter buttons
          Row(
            children: [
              _buildFilterButton('Laptops (1)', true),
              const SizedBox(width: 8),
              _buildFilterButton('Books (2)', false),
            ],
          ),
          const SizedBox(height: 24),
          
          // Items grid
          _buildItemsGrid(),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isSelected ? const Color(0xFF007185) : const Color(0xFFD5D9D9),
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: isSelected ? const Color(0xFF007185) : const Color(0xFF0F1111),
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildFilterButton(String text, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF007185) : Colors.white,
        border: Border.all(color: const Color(0xFFD5D9D9)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : const Color(0xFF0F1111),
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildItemsGrid() {
    final items = [
      {
        'name': 'VIMAL JONNEY Fleece Regular Fit Hooded Neck Olive Men...',
        'image': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=300&h=300&fit=crop',
        'status': 'Currently unavailable.',
        'isUnavailable': true,
      },
      {
        'name': 'HP 15s, 12th Gen Intel Core i5-1215U Laptop (8GB DDR4, 512GB SSD)',
        'image': 'https://images.unsplash.com/photo-1593642702821-c8da6771f0c6?w=300&h=300&fit=crop',
        'price': 34490,
        'originalPrice': null,
        'status': 'In stock',
        'shipping': 'Eligible for FREE Shipping',
        'familiarTag': 'Familiar',
        'colorOptions': 'Colours: Silver, 512GB SSD',
        'isUnavailable': false,
      },
      {
        'name': 'Shrimad Bhagwat Geeta Yatharoop',
        'image': 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=300&h=300&fit=crop',
        'price': 252,
        'originalPrice': null,
        'status': 'In stock',
        'tag': '#1 Best Seller in Hinduism',
        'format': 'Hardcover',
        'isUnavailable': false,
      },
      {
        'name': 'C In Depth by S.K.Srivastava/Deepali Srivastava',
        'image': 'https://images.unsplash.com/photo-1532012197267-da84d127e765?w=300&h=300&fit=crop',
        'price': 463,
        'originalPrice': null,
        'status': 'Paperback',
        'inStock': 'In stock',
        'soldBy': 'Sold by BOOK-AT-U',
        'priceUpdate': 'We updated this item to the best offer currently available at Amazon. The price increased by ₹18.00.',
        'isUnavailable': false,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildYourItemCard(items[index]);
      },
    );
  }

  Widget _buildYourItemCard(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  item['image'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => 
                      Container(color: Colors.grey[200], child: const Icon(Icons.image)),
                ),
              ),
            ),
          ),
          
          // Content
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    item['name'],
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF007185),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Tags
                  if (item['tag'] != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9900),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        item['tag'],
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  
                  if (item['familiarTag'] != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        item['familiarTag'],
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  
                  // Price
                  if (!item['isUnavailable'] && item['price'] != null) ...[
                    Text(
                      '₹${item['price'].toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]},',
                      )}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F1111),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  
                  // Status
                  if (item['isUnavailable']) ...[
                    Text(
                      item['status'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFCC0C39),
                      ),
                    ),
                  ] else ...[
                    if (item['status'] != null)
                      Text(
                        item['status'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0F1111),
                        ),
                      ),
                    if (item['inStock'] != null)
                      Text(
                        item['inStock'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                  ],
                  
                  const Spacer(),
                  
                  // Action buttons
                  if (item['isUnavailable']) ...[
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'See similar items',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF007185),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF007185),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Add to list',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF007185),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 4),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9900),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Move to cart',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF007185),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Add to list',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF007185),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item['priceUpdate'] != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 12,
                            color: Color(0xFF007185),
                          ),
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Learn more',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF007185),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (item['colorOptions'] != null) ...[
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          item['colorOptions'],
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF007185),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartSummary(CartModel cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'This order contains a gift',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F1111),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Subtotal (${cart.totalItems} items): ₹${cart.totalPrice.toInt().toString().replaceAllMapped(
                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                  (Match m) => '${m[1]},',
                )}.00',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F1111),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/checkout');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD814),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Proceed to Buy',
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
                  Checkbox(
                    value: false,
                    onChanged: (value) {},
                    activeColor: const Color(0xFF007185),
                  ),
                  const Expanded(
                    child: Text(
                      'EMI Available',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0F1111),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Customers who bought items section
        const Text(
          'Customers who bought items in your cart also bought',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F1111),
          ),
        ),
        const SizedBox(height: 16),
        // Related products would go here
        _buildRelatedProducts(),
      ],
    );
  }

  Widget _buildRelatedProducts() {
    final relatedProducts = [
      {
        'name': 'HP Victus, 12th Gen...',
        'image': 'https://images.unsplash.com/photo-1593642702821-c8da6771f0c6?w=200&h=200&fit=crop',
        'rating': 4.7,
        'reviews': 47,
        'price': 61990,
        'originalPrice': 79999,
        'discount': 23,
      },
      {
        'name': 'HP 15, AMD Ryzen 5...',
        'image': 'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=200&h=200&fit=crop',
        'rating': 4.1,
        'reviews': 16,
        'price': 35990,
        'originalPrice': 53412,
        'discount': 33,
      },
      {
        'name': 'HP 15, 13th Gen Intel...',
        'image': 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=200&h=200&fit=crop',
        'rating': 4.2,
        'reviews': 126,
        'price': 36440,
        'originalPrice': 58454,
        'discount': 28,
      },
    ];

    return Column(
      children: relatedProducts.map((product) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product['image'] as String,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF007185),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < (product['rating'] as double).floor()
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 12,
                              color: const Color(0xFFFF9900),
                            );
                          }),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${product['reviews']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF007185),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '-${product['discount']}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFCC0C39),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '₹${(product['price'] as int).toString().replaceAllMapped(
                            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                            (Match m) => '${m[1]},',
                          )}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F1111),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'M.R.P ₹${(product['originalPrice'] as int).toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]},',
                      )}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF565959),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9900),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Add to cart',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
             }).toList(),
     );
   }

  Widget _buildQuantitySelector(CartItem item, CartNotifier cartNotifier, bool isChecked) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: isChecked ? const Color(0xFFF0F2F2) : Colors.grey[200],
        border: Border.all(
          color: isChecked ? const Color(0xFFD5D9D9) : Colors.grey[300]!, 
          width: 1
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isChecked ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ] : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Left button (Delete if qty=1, Minus if qty>1)
          GestureDetector(
            onTap: isChecked ? () {
              if (item.quantity == 1) {
                cartNotifier.removeFromCart(item.id);
              } else {
                cartNotifier.updateQuantity(item.id, item.quantity - 1);
              }
            } : null,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.quantity == 1 ? Icons.delete_outline : Icons.remove,
                size: 16,
                color: !isChecked 
                    ? Colors.grey[400]
                    : item.quantity == 1 
                        ? const Color(0xFFCC0C39) 
                        : const Color(0xFF565959),
              ),
            ),
          ),
          // Center quantity display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${item.quantity}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isChecked ? const Color(0xFF0F1111) : Colors.grey[500],
              ),
            ),
          ),
          // Right plus button
          GestureDetector(
            onTap: isChecked ? () {
              cartNotifier.updateQuantity(item.id, item.quantity + 1);
            } : null,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                size: 16,
                color: isChecked ? const Color(0xFF565959) : Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }
 }
