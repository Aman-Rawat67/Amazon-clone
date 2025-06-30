import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/admin/demo_data_button.dart';
import 'customer/dynamic_home_screen.dart';

/// Test screen for trying out the dynamic homepage
class TestDynamicHomepage extends ConsumerWidget {
  const TestDynamicHomepage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Dynamic Homepage'),
        backgroundColor: const Color(0xFF232F3E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Info Card
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Dynamic Homepage Test',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This screen helps you test the new dynamic Amazon-style homepage.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Steps to test:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '1. Create demo data using the button below\n'
                      '2. Navigate to the dynamic homepage\n'
                      '3. See the beautiful Amazon-style layout',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            
            // Demo Data Creator
            const DemoDataButton(),
            
            // Navigation Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.home),
                    label: const Text('Go to Dynamic Homepage'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF232F3E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.push('/home');
                    },
                    icon: const Icon(Icons.preview),
                    label: const Text('Preview Dynamic Homepage'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
            
            // Features List
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Dynamic Homepage Features',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const _FeatureItem(
                      icon: Icons.stream,
                      title: 'Real-time Updates',
                      description: 'Data updates automatically from Firestore',
                    ),
                    const _FeatureItem(
                      icon: Icons.grid_view,
                      title: '2x2 Product Grid',
                      description: 'Beautiful Amazon-style product layout',
                    ),
                    const _FeatureItem(
                      icon: Icons.devices,
                      title: 'Responsive Design',
                      description: 'Adapts to mobile, tablet, and desktop',
                    ),
                    const _FeatureItem(
                      icon: Icons.image,
                      title: 'Network Images',
                      description: 'Optimized image loading with placeholders',
                    ),
                    const _FeatureItem(
                      icon: Icons.error_outline,
                      title: 'Error Handling',
                      description: 'Graceful loading and error states',
                    ),
                    const _FeatureItem(
                      icon: Icons.touch_app,
                      title: 'See More Links',
                      description: 'Navigate to detailed product listings',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: const DemoDataFAB(),
    );
  }
}

/// Feature item widget
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.green[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
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
} 