import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../constants/app_constants.dart';
import '../../services/firestore_service.dart';

/// Provider for vendor analytics
final vendorAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final user = ref.watch(userProvider).asData?.value;
  if (user == null) return {};
  
  return FirestoreService().getVendorAnalytics(user.id);
});

class VendorDashboardScreen extends ConsumerWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final analyticsAsync = ref.watch(vendorAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Show notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('Please login to access vendor dashboard'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(vendorAnalyticsProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Icon(
                              Icons.store,
                              color: AppColors.primary,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.paddingMedium),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back, ${user.name}!',
                                  style: const TextStyle(
                                    fontSize: AppDimensions.fontTitle,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppDimensions.paddingSmall),
                                Text(
                                  'Manage your store and track your sales',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: AppDimensions.fontMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingLarge),

                  // Analytics Section
                  analyticsAsync.when(
                    data: (analytics) => _buildAnalyticsSection(analytics),
                    loading: () => _buildAnalyticsLoading(),
                    error: (error, stack) => _buildAnalyticsError(),
                  ),
                  const SizedBox(height: AppDimensions.paddingLarge),

                  // Quick Actions
                  _buildQuickActions(context),
                  const SizedBox(height: AppDimensions.paddingLarge),

                  // Recent Activity
                  _buildRecentActivity(),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      bottomNavigationBar: _buildVendorBottomNav(context),
    );
  }

  Widget _buildAnalyticsSection(Map<String, dynamic> analytics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sales Overview',
          style: TextStyle(
            fontSize: AppDimensions.fontTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        
        // Analytics Cards
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                'Total Sales',
                '${AppConstants.currencySymbol}${analytics['totalSales']?.toStringAsFixed(2) ?? '0.00'}',
                Icons.attach_money,
                Colors.green,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Expanded(
              child: _buildAnalyticsCard(
                'Orders',
                '${analytics['totalOrders'] ?? 0}',
                Icons.shopping_bag,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                'Products',
                '${analytics['totalProducts'] ?? 0}',
                Icons.inventory,
                Colors.orange,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Expanded(
              child: _buildAnalyticsCard(
                'Rating',
                '${analytics['averageRating']?.toStringAsFixed(1) ?? '0.0'} ⭐',
                Icons.star,
                Colors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(Icons.trending_up, color: color, size: 16),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(
              value,
              style: TextStyle(
                fontSize: AppDimensions.fontLarge,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              title,
              style: TextStyle(
                fontSize: AppDimensions.fontSmall,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sales Overview',
          style: TextStyle(
            fontSize: AppDimensions.fontTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        Row(
          children: [
            Expanded(
              child: Card(
                child: Container(
                  height: 100,
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Expanded(
              child: Card(
                child: Container(
                  height: 100,
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsError() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: AppDimensions.paddingMedium),
            const Text('Error loading analytics'),
            const SizedBox(height: AppDimensions.paddingMedium),
            ElevatedButton(
              onPressed: () {
                // Refresh analytics
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: AppDimensions.fontTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Add Product',
                Icons.add_box,
                Colors.green,
                () => context.go('/vendor/add-product'),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Expanded(
              child: _buildQuickActionCard(
                'View Orders',
                Icons.list_alt,
                Colors.blue,
                () => context.go('/vendor/orders'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'My Products',
                Icons.inventory_2,
                Colors.orange,
                () => context.go('/vendor/products'),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Expanded(
              child: _buildQuickActionCard(
                'Analytics',
                Icons.analytics,
                Colors.purple,
                () => _showDetailedAnalytics(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: AppDimensions.fontMedium,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: AppDimensions.fontTitle,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // View all activity
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        
        Card(
          child: Column(
            children: [
              _buildActivityItem(
                'New order received',
                'Order #AB123 - \$25.99',
                Icons.shopping_bag,
                Colors.green,
                '2 hours ago',
              ),
              const Divider(height: 1),
              _buildActivityItem(
                'Product viewed',
                'iPhone 15 Pro - 5 views today',
                Icons.visibility,
                Colors.blue,
                '4 hours ago',
              ),
              const Divider(height: 1),
              _buildActivityItem(
                'Low stock alert',
                'Samsung Galaxy S24 - 2 left',
                Icons.warning,
                Colors.orange,
                '6 hours ago',
              ),
              const Divider(height: 1),
              _buildActivityItem(
                'Product added',
                'MacBook Air M3 successfully added',
                Icons.add_circle,
                Colors.green,
                '1 day ago',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String time,
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle),
      trailing: Text(
        time,
        style: TextStyle(
          fontSize: AppDimensions.fontSmall,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildVendorBottomNav(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      currentIndex: 0,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory),
          label: 'Products',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: 'Analytics',
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            // Already on dashboard
            break;
          case 1:
            context.go('/vendor/products');
            break;
          case 2:
            context.go('/vendor/orders');
            break;
          case 3:
            _showDetailedAnalytics(context);
            break;
        }
      },
    );
  }

  void _showDetailedAnalytics(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Detailed Analytics'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics, size: 100, color: Colors.grey),
                SizedBox(height: AppDimensions.paddingMedium),
                Text('Detailed Analytics'),
                SizedBox(height: AppDimensions.paddingSmall),
                Text('Charts and detailed reports will be displayed here'),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 