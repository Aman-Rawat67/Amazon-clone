import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/deal_model.dart';
import '../../models/product_model.dart';
import '../../services/emi_service.dart';
import '../../services/firestore_service.dart';
import '../../constants/app_constants.dart';
import '../../constants/filter_constants.dart';
import '../../providers/product_provider.dart';

/// Comprehensive offers screen showing all available deals and promotions
class AllOffersScreen extends ConsumerStatefulWidget {
  const AllOffersScreen({super.key});

  @override
  ConsumerState<AllOffersScreen> createState() => _AllOffersScreenState();
}

class _AllOffersScreenState extends ConsumerState<AllOffersScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<ProductModel> _flashDealProducts = [];
  bool _isLoadingFlashDeals = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadFlashDealProducts();
  }

  /// Load products with discounts for flash deals
  Future<void> _loadFlashDealProducts() async {
    try {
      setState(() => _isLoadingFlashDeals = true);
      
      final firestoreService = ref.read(firestoreServiceProvider);
      
      // Get products with discounts - we'll fetch all products and filter by discount
      final allProducts = await firestoreService.getProducts(
        limit: 50,
        isApproved: true,
        sortBy: SortOption.newest,
      );
      
      // Filter products that have discounts and are in stock
      final discountedProducts = allProducts
          .where((product) => product.hasDiscount && product.isInStock)
          .take(8)
          .toList();
      
      setState(() {
        _flashDealProducts = discountedProducts;
        _isLoadingFlashDeals = false;
      });
    } catch (e) {
      print('Error loading flash deal products: $e');
      setState(() => _isLoadingFlashDeals = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFlashDealsTab(),
                _buildBankOffersTab(),
                _buildCashbackTab(),
                _buildSpecialOffersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build app bar with gradient background
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: const Text(
        'All Offers & Deals',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () => context.push('/search'),
        ),
        IconButton(
          icon: const Icon(Icons.shopping_cart, color: Colors.white),
          onPressed: () => context.push('/cart'),
        ),
      ],
    );
  }

  /// Build tab bar for different offer categories
  Widget _buildTabBar() {
    return Container(
      color: AppColors.primary,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        tabs: const [
          Tab(text: 'Flash Deals'),
          Tab(text: 'Bank Offers'),
          Tab(text: 'Cashback'),
          Tab(text: 'Special Offers'),
        ],
      ),
    );
  }

  /// Build flash deals tab
  Widget _buildFlashDealsTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadFlashDealProducts();
        ref.refresh(productProvider);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Lightning Deals',
              'Limited time offers',
              Icons.flash_on,
              Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildFlashDealsGrid(),
            const SizedBox(height: 24),
            _buildSectionHeader(
              'Deal of the Day',
              'Best value for today',
              Icons.today,
              Colors.green,
            ),
            const SizedBox(height: 16),
            _buildDealOfTheDay(),
            const SizedBox(height: 24),
            _buildSectionHeader(
              'Trending Deals',
              'What everyone is buying',
              Icons.trending_up,
              Colors.purple,
            ),
            const SizedBox(height: 16),
            _buildTrendingDeals(),
          ],
        ),
      ),
    );
  }

  /// Build bank offers tab
  Widget _buildBankOffersTab() {
    final bankOffers = EMIService.getBankOffers();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Credit Card Offers',
            'Save with your credit cards',
            Icons.credit_card,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          ...bankOffers.map((offer) => _buildBankOfferCard(offer)),
          const SizedBox(height: 24),
          _buildSectionHeader(
            'Debit Card Offers',
            'Instant discounts',
            Icons.payment,
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildDebitCardOffers(),
        ],
      ),
    );
  }

  /// Build cashback tab
  Widget _buildCashbackTab() {
    final cashbackOffer = EMIService.getCashbackOffers();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'UPI Cashback',
            'Pay with UPI and earn cashback',
            Icons.account_balance_wallet,
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildCashbackOfferCard(cashbackOffer),
          const SizedBox(height: 24),
          _buildSectionHeader(
            'Wallet Offers',
            'Additional savings',
            Icons.wallet,
            Colors.purple,
          ),
          const SizedBox(height: 16),
          _buildWalletOffers(),
          const SizedBox(height: 24),
          _buildSectionHeader(
            'Loyalty Rewards',
            'Earn points on every purchase',
            Icons.star,
            Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildLoyaltyRewards(),
        ],
      ),
    );
  }

  /// Build special offers tab
  Widget _buildSpecialOffersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Festive Offers',
            'Celebrate with great deals',
            Icons.celebration,
            Colors.red,
          ),
          const SizedBox(height: 16),
          _buildFestiveOffers(),
          const SizedBox(height: 24),
          _buildSectionHeader(
            'Combo Deals',
            'Buy more, save more',
            Icons.shopping_bag,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildComboDeals(),
          const SizedBox(height: 24),
          _buildSectionHeader(
            'New User Offers',
            'Special discounts for first-time buyers',
            Icons.new_releases,
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildNewUserOffers(),
        ],
      ),
    );
  }

  /// Build section header with icon and description
  Widget _buildSectionHeader(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build flash deals grid
  Widget _buildFlashDealsGrid() {
    if (_isLoadingFlashDeals) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_flashDealProducts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No flash deals available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check back later for amazing deals!',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive grid based on screen width
        int crossAxisCount = 2;
        if (constraints.maxWidth > 800) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 3;
        }
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.75, // More compact cards
          ),
          itemCount: _flashDealProducts.length,
          itemBuilder: (context, index) => _buildFlashDealCard(
            _flashDealProducts[index], 
            index,
          ),
        );
      },
    );
  }

  /// Build individual flash deal card
  Widget _buildFlashDealCard(ProductModel? product, int index) {
    return GestureDetector(
      onTap: () {
        if (product != null) {
          context.go('/product/${product.id}');
        }
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.all(2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Expanded(
              flex: 3,
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: product?.imageUrls.isNotEmpty == true
                          ? ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: product!.imageUrls.first,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Icon(
                                  Icons.image,
                                  size: 32,
                                  color: Colors.grey,
                                ),
                                errorWidget: (context, url, error) => const Icon(
                                  Icons.image,
                                  size: 32,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.image,
                              size: 32,
                              color: Colors.grey,
                            ),
                    ),
                    // Discount badge
                    if (product?.hasDiscount == true)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '${product!.discountPercentage.toInt()}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Content section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        product?.name ?? 'Product ${index + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '₹${product?.price.toInt() ?? 1999}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                        if (product?.originalPrice != null) ...[
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '₹${product!.originalPrice!.toInt()}',
                              style: const TextStyle(
                                fontSize: 10,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Rating or stock info
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 10,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            '${product?.rating.toStringAsFixed(1) ?? '4.0'} (${product?.reviewCount ?? 100})',
                            style: const TextStyle(
                              fontSize: 8,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build deal of the day
  Widget _buildDealOfTheDay() {
    // Get the best deal from flash deals or use default
    final bestDeal = _flashDealProducts.isNotEmpty 
        ? _flashDealProducts.reduce((a, b) => 
            a.discountPercentage > b.discountPercentage ? a : b)
        : null;
    
    return GestureDetector(
      onTap: () {
        if (bestDeal != null) {
          context.go('/product/${bestDeal.id}');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange[100]!, Colors.red[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[300]!),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: bestDeal?.imageUrls.isNotEmpty == true
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: bestDeal!.imageUrls.first,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Icon(
                          Icons.local_offer,
                          size: 24,
                          color: Colors.orange,
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.local_offer,
                          size: 24,
                          color: Colors.orange,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.local_offer,
                      size: 24,
                      color: Colors.orange,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bestDeal?.name ?? 'Daily Special Deal',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '₹${bestDeal?.price.toInt() ?? 4999}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      if (bestDeal?.originalPrice != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '₹${bestDeal!.originalPrice!.toInt()}',
                          style: const TextStyle(
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.orange[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Limited time offer',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build trending deals
  Widget _buildTrendingDeals() {
    // Use a subset of flash deals for trending or all if less than 6
    final trendingProducts = _flashDealProducts.length > 6 
        ? _flashDealProducts.sublist(0, 6)
        : _flashDealProducts;
    
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: trendingProducts.isNotEmpty ? trendingProducts.length : 3,
        itemBuilder: (context, index) {
          final product = trendingProducts.isNotEmpty 
              ? trendingProducts[index] 
              : null;
          
          return GestureDetector(
            onTap: () {
              if (product != null) {
                context.go('/product/${product.id}');
              }
            },
            child: Container(
              width: 120,
              margin: const EdgeInsets.only(right: 8),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                        child: product?.imageUrls.isNotEmpty == true
                            ? ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: product!.imageUrls.first,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Icon(
                                    Icons.trending_up,
                                    size: 24,
                                    color: Colors.grey,
                                  ),
                                  errorWidget: (context, url, error) => const Icon(
                                    Icons.trending_up,
                                    size: 24,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.trending_up,
                                size: 24,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Text(
                                product?.name ?? 'Trending Product ${index + 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${product?.price.toInt() ?? (1999 + index * 500)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build bank offer card
  Widget _buildBankOfferCard(Map<String, dynamic> offer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(Icons.credit_card, color: Colors.blue[700], size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer['bank'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  offer['description'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Save up to ₹${offer['discount']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }

  /// Build debit card offers
  Widget _buildDebitCardOffers() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[100]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: Colors.green[700], size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Instant 5% discount on all debit card transactions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Valid on minimum purchase of ₹2,000',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Build cashback offer card
  Widget _buildCashbackOfferCard(Map<String, dynamic> offer) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50]!, Colors.green[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[600],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Get ₹${offer['amount']} Cashback',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      offer['description'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Text(
              offer['terms'] as String,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Build wallet offers
  Widget _buildWalletOffers() {
    final wallets = ['Amazon Pay', 'Paytm', 'PhonePe', 'Google Pay'];
    
    return Column(
      children: wallets.map((wallet) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple[100]!),
        ),
        child: Row(
          children: [
            Icon(Icons.wallet, color: Colors.purple[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$wallet - Get 2% extra cashback',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      )).toList(),
    );
  }

  /// Build loyalty rewards
  Widget _buildLoyaltyRewards() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[50]!, Colors.yellow[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.orange[600], size: 24),
              const SizedBox(width: 12),
              const Text(
                'Amazon Rewards',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Earn 1 point for every ₹100 spent. Redeem 100 points = ₹1',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// Build festive offers
  Widget _buildFestiveOffers() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[50]!, Colors.pink[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.celebration, color: Colors.red[600], size: 28),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Festival Sale - Up to 70% OFF',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Celebrate this festive season with amazing discounts on electronics, fashion, home & kitchen, and more!',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Shop Now'),
          ),
        ],
      ),
    );
  }

  /// Build combo deals
  Widget _buildComboDeals() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.shopping_bag, color: Colors.blue[600], size: 24),
              const SizedBox(width: 12),
              const Text(
                'Combo Offers',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Buy 2 Get 1 Free on selected items\nBuy 3 Get 25% OFF on fashion',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// Build new user offers
  Widget _buildNewUserOffers() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50]!, Colors.blue[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.new_releases, color: Colors.green[600], size: 28),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Welcome Offer - 20% OFF',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'First-time users get 20% discount on their first purchase. Minimum order value ₹1,000.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Use Code: WELCOME20',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 