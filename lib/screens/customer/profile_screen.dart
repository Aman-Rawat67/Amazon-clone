import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_constants.dart';
import '../../widgets/common/loading_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_outline, size: 100, color: Colors.grey),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  const Text('Please login to view profile'),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Login'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Column(
              children: [
                // User Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                    child: Column(
                      children: [
                        // Profile Picture
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withOpacity(0.1),
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                          child: user.profileImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: Image.network(
                                    user.profileImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Icon(Icons.person, size: 50, color: AppColors.primary),
                                  ),
                                )
                              : Icon(Icons.person, size: 50, color: AppColors.primary),
                        ),
                        const SizedBox(height: AppDimensions.paddingMedium),
                        
                        // User Name
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: AppDimensions.fontTitle,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.paddingSmall),
                        
                        // User Email
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: AppDimensions.fontMedium,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: AppDimensions.paddingSmall),
                        
                        // User Role
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.paddingMedium,
                            vertical: AppDimensions.paddingSmall,
                          ),
                          decoration: BoxDecoration(
                            color: _getRoleColor(user.role).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                            border: Border.all(color: _getRoleColor(user.role)),
                          ),
                          child: Text(
                            user.role.toString().split('.').last.toUpperCase(),
                            style: TextStyle(
                              color: _getRoleColor(user.role),
                              fontWeight: FontWeight.bold,
                              fontSize: AppDimensions.fontSmall,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingLarge),

                // Profile Options
                _buildProfileOption(
                  context,
                  icon: Icons.edit,
                  title: 'Edit Profile',
                  subtitle: 'Update your personal information',
                  onTap: () => _showEditProfileDialog(context, ref, user),
                ),
                
                _buildProfileOption(
                  context,
                  icon: Icons.location_on,
                  title: 'Addresses',
                  subtitle: 'Manage your delivery addresses',
                  onTap: () => _showAddressesScreen(context),
                ),
                
                _buildProfileOption(
                  context,
                  icon: Icons.payment,
                  title: 'Payment Methods',
                  subtitle: 'Manage your payment options',
                  onTap: () => _showPaymentMethodsScreen(context),
                ),
                
                _buildProfileOption(
                  context,
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: 'Configure your notification preferences',
                  onTap: () => _showNotificationSettings(context),
                ),
                
                _buildProfileOption(
                  context,
                  icon: Icons.help,
                  title: 'Help & Support',
                  subtitle: 'Get help and contact support',
                  onTap: () => _showHelpScreen(context),
                ),
                
                _buildProfileOption(
                  context,
                  icon: Icons.privacy_tip,
                  title: 'Privacy Policy',
                  subtitle: 'Read our privacy policy',
                  onTap: () => _showPrivacyPolicy(context),
                ),
                
                _buildProfileOption(
                  context,
                  icon: Icons.info,
                  title: 'About',
                  subtitle: 'App version and information',
                  onTap: () => _showAboutDialog(context),
                ),

                const SizedBox(height: AppDimensions.paddingLarge),

                // Logout Button
                LoadingButton(
                  onPressed: () => _showLogoutDialog(context, ref),
                  text: 'Logout',
                  isLoading: false,
                  backgroundColor: Colors.red,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: AppDimensions.paddingMedium),
              Text('Error loading profile: $error'),
              const SizedBox(height: AppDimensions.paddingMedium),
              ElevatedButton(
                onPressed: () => ref.refresh(userProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: AppDimensions.fontMedium,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: AppDimensions.fontSmall,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Color _getRoleColor(role) {
    switch (role.toString().split('.').last) {
      case 'admin':
        return Colors.red;
      case 'vendor':
        return Colors.blue;
      case 'customer':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phoneNumber ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                enabled: false,
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Update user profile logic here
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating profile: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddressesScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('My Addresses'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_outlined, size: 100, color: Colors.grey),
                SizedBox(height: AppDimensions.paddingMedium),
                Text('No addresses found'),
                SizedBox(height: AppDimensions.paddingSmall),
                Text('Add an address to get started'),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // Add address logic
            },
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _showPaymentMethodsScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Payment Methods'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment_outlined, size: 100, color: Colors.grey),
                SizedBox(height: AppDimensions.paddingMedium),
                Text('No payment methods found'),
                SizedBox(height: AppDimensions.paddingSmall),
                Text('Add a payment method to get started'),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // Add payment method logic
            },
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Notification Settings'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            children: [
              SwitchListTile(
                title: const Text('Push Notifications'),
                subtitle: const Text('Receive notifications about orders and updates'),
                value: true,
                onChanged: (value) {
                  // Update notification preference
                },
              ),
              SwitchListTile(
                title: const Text('Email Notifications'),
                subtitle: const Text('Receive email updates about your orders'),
                value: true,
                onChanged: (value) {
                  // Update email preference
                },
              ),
              SwitchListTile(
                title: const Text('Promotional Offers'),
                subtitle: const Text('Receive notifications about deals and offers'),
                value: false,
                onChanged: (value) {
                  // Update promotional preference
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Help & Support'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.question_answer),
                  title: const Text('FAQ'),
                  subtitle: const Text('Frequently asked questions'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigate to FAQ
                  },
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.chat),
                  title: const Text('Live Chat'),
                  subtitle: const Text('Chat with our support team'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Start live chat
                  },
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email Support'),
                  subtitle: const Text('Send us an email'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Open email client
                  },
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text('Call Support'),
                  subtitle: const Text('+1 (555) 123-4567'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Make phone call
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Privacy Policy'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: const SingleChildScrollView(
            padding: EdgeInsets.all(AppDimensions.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: AppDimensions.fontTitle,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppDimensions.paddingMedium),
                Text(
                  'Last updated: January 2024',
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: AppDimensions.paddingLarge),
                Text(
                  'Your privacy is important to us. This privacy policy explains how we collect, use, and protect your information when you use our app.',
                  style: TextStyle(height: 1.5),
                ),
                SizedBox(height: AppDimensions.paddingMedium),
                Text(
                  'Information We Collect',
                  style: TextStyle(
                    fontSize: AppDimensions.fontMedium,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppDimensions.paddingSmall),
                Text(
                  '• Personal information (name, email, phone number)\n• Order and purchase history\n• Device information and usage data\n• Location data (with your permission)',
                  style: TextStyle(height: 1.5),
                ),
                // Add more privacy policy content here
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: const Icon(Icons.shopping_bag, color: Colors.white, size: 32),
      ),
      children: [
        const Text('A comprehensive e-commerce app built with Flutter and Firebase.'),
        const SizedBox(height: AppDimensions.paddingMedium),
        const Text('Features:'),
        const Text('• Multi-role user system\n• Product catalog\n• Shopping cart\n• Order management\n• Payment integration'),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(userProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
