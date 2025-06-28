import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/home/top_nav_bar.dart';
import '../../widgets/home/category_nav_bar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'product_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 700 && !kIsWeb;

    return Scaffold(
      backgroundColor: const Color(0xFFEAeded),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: TopNavBar()),
          SliverToBoxAdapter(child: CategoryNavBar()),
          SliverPersistentHeader(
            pinned: true,
            delegate: _MenuBarDelegate(child: _AmazonMenuBar()),
          ),
          SliverToBoxAdapter(child: _HeroBanner()),
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
            sliver: SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 4;
                  double cardAspectRatio = 1.1;
                  double gridPadding = 0;
                  if (constraints.maxWidth < 700) {
                    crossAxisCount = 1;
                    cardAspectRatio = 1.2;
                    gridPadding = 8;
                  } else if (constraints.maxWidth < 1100) {
                    crossAxisCount = 2;
                    cardAspectRatio = 1.2;
                    gridPadding = 16;
                  } else if (constraints.maxWidth < 1400) {
                    crossAxisCount = 3;
                    cardAspectRatio = 1.15;
                    gridPadding = 24;
                  } else {
                    gridPadding = 48;
                  }
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: gridPadding),
                    child: GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 32,
                      mainAxisSpacing: 32,
                      childAspectRatio: cardAspectRatio,
                      children: [
                        _CategoryCard(
                          title: 'Appliances for your home | Up to 55% off',
                          items: const [
                            _CategoryItem('Air conditioners', 'https://images-eu.ssl-images-amazon.com/images/G/31/IMG15/Irfan/GATEWAY/MSO/Appliances-QC-PC-186x116--B08RDL6H79._SY116_CB667322346_.jpg', productId: 'ac_001'),
                            _CategoryItem('Refrigerators', 'https://images-eu.ssl-images-amazon.com/images/G/31/IMG15/Irfan/GATEWAY/MSO/Appliances-QC-PC-186x116--B08345R1ZW._SY116_CB667322346_.jpg', productId: 'fridge_001'),
                            _CategoryItem('Microwaves', 'https://images-eu.ssl-images-amazon.com/images/G/31/IMG15/Irfan/GATEWAY/MSO/Appliances-QC-PC-186x116--B07G5J5FYP._SY116_CB667322346_.jpg', productId: 'microwave_001'),
                            _CategoryItem('Washing machines', 'https://images-eu.ssl-images-amazon.com/images/G/31/IMG15/Irfan/GATEWAY/MSO/186x116---wm._SY116_CB667322346_.jpg', productId: 'washing_001'),
                          ],
                          seeMore: 'See more',
                        ),
                        _CategoryCard(
                          title: 'Revamp your home in style',
                          items: const [
                            _CategoryItem('Cushion covers, bedsheets & more', 'https://images-eu.ssl-images-amazon.com/images/G/31/IMG20/Home/2024/Gateway/BTFGW/PCQC/New/1x/final/186x116_Home_furnishings_2._SY116_CB555624324_.jpg', productId: 'bedsheet_001'),
                            _CategoryItem('Figurines, vases & more', 'https://m.media-amazon.com/images/I/91Z1R2lM8lL._AC_SY200_.jpg', productId: 'vase_001'),
                            _CategoryItem('Home storage', 'https://images-eu.ssl-images-amazon.com/images/G/31/IMG20/Home/2024/Gateway/BTFGW/PCQC/New/1x/final/186x116_Home_storage_1._SY116_CB555624324_.jpg', productId: 'storage_001'),
                            _CategoryItem('Lighting solutions', 'https://images-eu.ssl-images-amazon.com/images/G/31/IMG20/Home/2024/Gateway/BTFGW/PCQC/New/1x/final/186x116_Home_lighting_2._SY116_CB555624324_.jpg', productId: 'lighting_001'),
                          ],
                          seeMore: 'Explore all',
                        ),
                        _CategoryCard(
                          title: 'PlayStation 5 Slim & Accessories | No Cost EMI*',
                          items: const [
                            _CategoryItem('PS5 Slim digital edition', 'https://images-eu.ssl-images-amazon.com/images/G/31/img23/VG/Nanditha/BI/QC-4--1x._SY116_CB793233792_.jpg', productId: 'ps5_digital_001'),
                            _CategoryItem('PS5 Slim disc edition', 'https://images-eu.ssl-images-amazon.com/images/G/31/img23/VG/Nanditha/BI/QC-3--1x._SY116_CB793233792_.jpg', productId: 'ps5_disc_001'),
                            _CategoryItem('PS5 Slim Fortnite digital edition', 'https://images-eu.ssl-images-amazon.com/images/G/31/img23/VG/Nanditha/BI/QC-1--1x._SY116_CB793233792_.jpg', productId: 'ps5_fortnite_001'),
                            _CategoryItem('PS5 DualSense Wireless Controller', 'https://images-eu.ssl-images-amazon.com/images/G/31/img23/VG/Nanditha/BI/QC-1--1x._SY116_CB793233792_.jpg', productId: 'ps5_controller_001'),
                          ],
                          seeMore: 'See all deals',
                        ),
                        _CategoryCard(
                          title: 'Starting ₹149 | Headphones',
                          items: const [
                            _CategoryItem('boAt', 'https://images-eu.ssl-images-amazon.com/images/G/31/img21/june/CE/GW/QC/PC/PC_QuadCard_boAt_0.5x._SY116_CB553870684_.jpg', subtext: 'Starting ₹249 | boAt', productId: 'headphone_boat_001'),
                            _CategoryItem('boult', 'https://images-eu.ssl-images-amazon.com/images/G/31/img21/june/CE/GW/QC/PC/PC_QuadCard_Boult_0.5x._SY116_CB553870684_.jpg', subtext: 'Starting ₹349 | boult', productId: 'headphone_boult_001'),
                            _CategoryItem('noise', 'https://images-eu.ssl-images-amazon.com/images/G/31/img21/june/CE/GW/QC/PC/PC_QuadCard_Noise_0.5x._SY116_CB553870684_.jpg', subtext: 'Starting ₹649 | Noise', productId: 'headphone_noise_001'),
                            _CategoryItem('Zebronics', 'https://images-eu.ssl-images-amazon.com/images/G/31/img21/june/CE/MSO/PD3/PC_QuadCard_Zeb_0.5x_1._SY116_CB570220221_.jpg', subtext: 'Starting ₹149 | Zebronics', productId: 'headphone_zebronics_001'),
                          ],
                          seeMore: 'See all offers',
                        ),
                        _CategoryCard(
                          title: 'Under ₹499 | Deals on home improvement essentials',
                          items: const [
                            _CategoryItem('Under ₹199 | Cleaning supplies', 'https://images-eu.ssl-images-amazon.com/images/G/31/img18/HomeImprovement/harsmisc/2025/March/Wipes_low_res_V1._SY116_CB549138744_.jpg', productId: 'cleaning_001'),
                            _CategoryItem('Under ₹399 | Bathroom accessories', 'https://images-eu.ssl-images-amazon.com/images/G/31/img18/HomeImprovement/harsmisc/2025/March/Shower_heads_low_res_V1._SY116_CB549138744_.jpg', productId: 'bathroom_001'),
                            _CategoryItem('Under ₹499 | Home tools', 'https://images-eu.ssl-images-amazon.com/images/G/31/img18/HomeImprovement/harsmisc/2025/March/Tools_low_res_V1._SY116_CB549138744_.jpg', productId: 'tools_001'),
                            _CategoryItem('Under ₹299 | Wallpapers', 'https://images-eu.ssl-images-amazon.com/images/G/31/img18/HomeImprovement/harsmisc/2025/March/Wallpapers_low_res_V1._SY116_CB549138744_.jpg', productId: 'wallpaper_001'),
                          ],
                          seeMore: 'Explore all',
                        ),
                        _CategoryCard(
                          title: 'Automotive essentials | Up to 60% off',
                          items: const [
                            _CategoryItem('Cleaning accessories', 'https://images-eu.ssl-images-amazon.com/images/G/31/img17/Auto/2020/GW/PCQC/Glasscare1X._SY116_CB410830553_.jpg', productId: 'auto_cleaning_001'),
                            _CategoryItem('Tyre & rim care', 'https://images-eu.ssl-images-amazon.com/images/G/31/img17/Auto/2020/GW/PCQC/Rim_tyrecare1x._SY116_CB410830552_.jpg', productId: 'tyre_care_001'),
                            _CategoryItem('Helmets', 'https://images-eu.ssl-images-amazon.com/images/G/31/img17/Auto/2020/GW/PCQC/Vega_helmet_186x116._SY116_CB405090404_.jpg', productId: 'helmet_001'),
                            _CategoryItem('Vacuum cleaner', 'https://images-eu.ssl-images-amazon.com/images/G/31/img17/Auto/2020/GW/PCQC/Vaccum1x._SY116_CB410830552_.jpg', productId: 'vacuum_001'),
                          ],
                          seeMore: 'See more',
                        ),
                        _CategoryCard(
                          title: 'Min. 40% off | Toys & Fun games | Amazon brands',
                          items: const [
                            _CategoryItem('Min. 50% off | Soft toys', 'https://images-eu.ssl-images-amazon.com/images/G/31/img21/AmazonBrands/GW_CPB_/QC_CC/Baby_toys/baby/QC_PC_186x116_9._SY116_CB563558900_.jpg', productId: 'soft_toys_001'),
                            _CategoryItem('Min. 40% off | Indoor games', 'https://images-eu.ssl-images-amazon.com/images/G/31/img21/AmazonBrands/GW_CPB_/QC_CC/Baby_toys/toys/QC_PC_186x116_15._SY116_CB541414575_.jpg', productId: 'indoor_games_001'),
                            _CategoryItem('Min. 40% off | Ride ons', 'https://images-eu.ssl-images-amazon.com/images/G/31/img21/AmazonBrands/GW_CPB_/QC_CC/Baby_toys/toys/QC_PC_186x116_11._SY116_CB541414575_.jpg', productId: 'ride_ons_001'),
                            _CategoryItem('Min. 50% off | Outdoor games', 'https://images-eu.ssl-images-amazon.com/images/G/31/img21/AmazonBrands/GW_CPB_/QC_CC/Baby_toys/toys/QC_PC_186x116_16._SY116_CB541411275_.jpg', productId: 'outdoor_games_001'),
                          ],
                          seeMore: 'See all offers',
                        ),
                        _CategoryCard(
                          title: 'Starting ₹199 | Amazon Brands & more',
                          items: const [
                            _CategoryItem('Starting ₹199 | Bedsheets', 'https://images-eu.ssl-images-amazon.com/images/G/31/img23/PB/March/Bikram/PC_QC_HOME_SIZE_186_2._SY116_CB567468236_.jpg', productId: 'amazon_bedsheets_001'),
                            _CategoryItem('Starting ₹199 | Curtains', 'https://images-eu.ssl-images-amazon.com/images/G/31/img23/PB/March/Bikram/PC_QC_HOME_SIZE_186_3._SY116_CB567468236_.jpg', productId: 'amazon_curtains_001'),
                            _CategoryItem('Minimum 40% off | Ironing board & more', 'https://images-eu.ssl-images-amazon.com/images/G/31/img23/PB/March/Bikram/PC_QC_HOME_SIZE_186_4._SY116_CB567468236_.jpg', productId: 'ironing_board_001'),
                            _CategoryItem('Up to 60% off | Home decor', 'https://images-eu.ssl-images-amazon.com/images/G/31/img23/PB/March/Bikram/PC_QC_HOME_SIZE_186_1._SY116_CB567468236_.jpg', productId: 'home_decor_001'),
                          ],
                          seeMore: 'See more',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(child: _TechDealsSection()),
        ],
      ),
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
                BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Orders'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
              ],
              onTap: (index) {
                switch (index) {
                  case 0:
                    context.go('/home');
                    break;
                  case 1:
                    context.go('/cart');
                    break;
                  case 2:
                    context.go('/orders');
                    break;
                  case 3:
                    context.go('/profile');
                    break;
                }
              },
            )
          : null,
    );
  }
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final bannerHeight = isMobile ? 220.0 : 320.0;
    return Container(
      width: double.infinity,
      height: bannerHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.network(
            'https://images.pexels.com/photos/3259584/pexels-photo-3259584.jpeg?_gl=1*189i9p9*_ga*Mzk2MTI3NDczLjE3NTEwMTY4NzU.*_ga_8JE65Q40S6*czE3NTEwMTY4NzQkbzEkZzEkdDE3NTEwMTY4ODYkajQ4JGwwJGgw',
            fit: BoxFit.cover,
          ),
          // Gradient overlay for readability
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xAAFFFFFF),
                  Color(0x66FFFFFF),
                  Color(0x00FFFFFF),
                ],
              ),
            ),
          ),
          // Main content
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left arrow
              Padding(
                padding: EdgeInsets.only(left: isMobile ? 4 : 24),
                child: Icon(Icons.arrow_back_ios, size: isMobile ? 28 : 36, color: Colors.black54),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Starting ₹149',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: isMobile ? 24 : 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Household,\ncooking needs & more',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: isMobile ? 16 : 22,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _FeatureIcon(
                            icon: Icons.verified,
                            label: 'TOP BRANDS',
                            color: Color(0xFFFFA41C),
                          ),
                          const SizedBox(width: 16),
                          _FeatureIcon(
                            icon: Icons.price_check,
                            label: 'GREAT PRICES',
                            color: Color(0xFFFFA41C),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            'https://m.media-amazon.com/images/I/71h9nOTd93L._AC_UL320_.jpg',
                            height: isMobile ? 60 : 90,
                          ),
                          const SizedBox(width: 12),
                          Image.network(
                            'https://m.media-amazon.com/images/I/81QpkIctqPL._AC_UL320_.jpg',
                            height: isMobile ? 60 : 90,
                          ),
                          const SizedBox(width: 12),
                          Image.network(
                            'https://m.media-amazon.com/images/I/71U3l6l0TJL._AC_UL320_.jpg',
                            height: isMobile ? 60 : 90,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Right arrow
              Padding(
                padding: EdgeInsets.only(right: isMobile ? 4 : 24),
                child: Icon(Icons.arrow_forward_ios, size: isMobile ? 28 : 36, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _FeatureIcon({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final List<_CategoryItem> items;
  final String seeMore;
  const _CategoryCard({required this.title, required this.items, required this.seeMore});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        height: 520, // Keep or adjust as needed
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 10), // Slightly reduced vertical padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: Colors.black)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: items[0]),
                  const SizedBox(width: 10),
                  Expanded(child: items[1]),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: items[2]),
                  const SizedBox(width: 10),
                  Expanded(child: items[3]),
                ],
              ),
              const SizedBox(height: 10), // Instead of Spacer, use fixed space
              GestureDetector(
                onTap: () {
                  // Extract category from title for navigation
                  String category = '';
                  final titleLower = title.toLowerCase();
                  if (titleLower.contains('appliances') || titleLower.contains('home')) {
                    category = 'home & kitchen';
                  } else if (titleLower.contains('electronics') || titleLower.contains('playstation') || titleLower.contains('headphones')) {
                    category = 'electronics';
                  } else if (titleLower.contains('fashion') || titleLower.contains('style')) {
                    category = 'fashion';
                  } else if (titleLower.contains('automotive')) {
                    category = 'automotive';
                  } else if (titleLower.contains('toys') || titleLower.contains('games')) {
                    category = 'toys & games';
                  } else if (titleLower.contains('brands')) {
                    category = 'amazon brands';
                  } else {
                    category = 'all';
                  }
                  
                  if (category.isNotEmpty) {
                    context.push('/category/${Uri.encodeComponent(category)}');
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    seeMore,
                    style: const TextStyle(
                      color: Color(0xFF007185),
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String label;
  final String imageUrl;
  final String? subtext;
  final bool isLogo;
  final String? productId;
  const _CategoryItem(this.label, this.imageUrl, {this.subtext, this.isLogo = false, this.productId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (productId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                productId: productId!,
              ),
            ),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // Center everything
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: 90, // Slightly smaller for more space
              height: 90,
              fit: isLogo ? BoxFit.contain : BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtext ?? label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: subtext != null ? FontWeight.normal : FontWeight.w500,
              color: subtext != null ? Colors.grey[700] : Colors.black,
            ),
            textAlign: TextAlign.center, // Center text
          ),
          if (subtext != null)
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center, // Center text
            ),
        ],
      ),
    );
  }
}

class _TechDealsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Up to 50% Off | Save on tech essentials from stores near you',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          context.push('/category/${Uri.encodeComponent('electronics')}');
                        },
                        child: Text(
                          'See all offers',
                          style: const TextStyle(
                            color: Color(0xFF007185),
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Icon(Icons.arrow_back_ios, size: 14, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _techProducts.length,
                itemBuilder: (context, index) {
                  final product = _techProducts[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(
                            productId: index.toString(),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 140,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[50],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                product['image']!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product['discount']!,
                            style: const TextStyle(
                              color: Color(0xFFCC0C39),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            product['name']!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Tech products data similar to your Amazon screenshot
final List<Map<String, String>> _techProducts = [
  {
    'name': 'Smart Watch with Health Monitoring',
    'image': 'https://images.unsplash.com/photo-1579586337278-3f436f25d4d5?w=300&h=300&fit=crop&crop=center',
    'discount': 'Up to 45% off',
  },
  {
    'name': 'Premium Fitness Tracker',
    'image': 'https://images.unsplash.com/photo-1544117519-31a4b719223d?w=300&h=300&fit=crop&crop=center',
    'discount': 'Up to 50% off',
  },
  {
    'name': 'Sports Watch with GPS',
    'image': 'https://images.unsplash.com/photo-1434493789847-2f02dc6ca35d?w=300&h=300&fit=crop&crop=center',
    'discount': 'Up to 35% off',
  },
  {
    'name': 'Apple Watch Series 9',
    'image': 'https://images.unsplash.com/photo-1551816230-ef5deaed4a26?w=300&h=300&fit=crop&crop=center',
    'discount': 'Up to 25% off',
  },
  {
    'name': 'Samsung Galaxy Watch',
    'image': 'https://images.unsplash.com/photo-1508685096489-7aacd43bd3b1?w=300&h=300&fit=crop&crop=center',
    'discount': 'Up to 40% off',
  },
  {
    'name': 'Garmin Fitness Watch',
    'image': 'https://images.unsplash.com/photo-1508057198894-247b23fe5ade?w=300&h=300&fit=crop&crop=center',
    'discount': 'Up to 30% off',
  },
  {
    'name': 'Hybrid Smart Watch',
    'image': 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=300&h=300&fit=crop&crop=center',
    'discount': 'Up to 55% off',
  },
  {
    'name': 'Luxury Smart Watch',
    'image': 'https://images.unsplash.com/photo-1522312346375-d1a52e2b99b3?w=300&h=300&fit=crop&crop=center',
    'discount': 'Up to 20% off',
  },
];

class _MenuBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _MenuBarDelegate({required this.child});

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

class _AmazonMenuBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF232F3E),
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Row(
            children: [
              Icon(Icons.menu, color: Colors.white, size: 22),
              const SizedBox(width: 6),
              Text('All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              const SizedBox(width: 18),
              _MenuItem('Fresh'),
              _MenuItem('MX Player'),
              _MenuItem('Sell'),
              _MenuItem('Bestsellers'),
              _MenuItem('Prime', hasDropdown: true),
              _MenuItem('Mobiles'),
              _MenuItem("Today's Deals"),
              _MenuItem('Customer Service'),
              _MenuItem('New Releases'),
              _MenuItem('Fashion'),
              _MenuItem('Amazon Pay'),
              _MenuItem('Electronics'),
              _MenuItem('Home & Kitchen'),
              _MenuItem('Computers'),
              _MenuItem('Car & Motorbike'),
              _MenuItem('Books'),
              _MenuItem('Video Games'),
              _MenuItem('Toys & Games'),
              _MenuItem('Home Improvement'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String label;
  final bool hasDropdown;
  const _MenuItem(this.label, {this.hasDropdown = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15),
          ),
          if (hasDropdown)
            const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
        ],
      ),
    );
  }
}
