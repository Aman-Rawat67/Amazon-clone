import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_constants.dart';
import '../../utils/validators.dart';
import '../../models/user_model.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  UserRole _selectedRole = UserRole.customer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _nameController,
                label: 'Name',
                hint: 'Enter your name',
                validator: Validators.validateName,
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
              CustomTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'Enter your email',
                validator: Validators.validateEmail,
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
              CustomTextField(
                controller: _passwordController,
                label: 'Password',
                hint: 'Enter your password',
                obscureText: true,
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: AppDimensions.paddingLarge),
              
              // Role Selection
              const Text(
                'Account Type',
                style: TextStyle(
                  fontSize: AppDimensions.fontMedium,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingSmall),
              _buildRoleSelection(),
              const SizedBox(height: AppDimensions.paddingLarge),
              
              // Role-specific information
              if (_selectedRole == UserRole.vendor)
                _buildVendorInfo(),
              
              const SizedBox(height: AppDimensions.paddingLarge),
              SizedBox(
                width: double.infinity,
                child: LoadingButton(
                  onPressed: _register,
                  isLoading: _isLoading,
                  text: 'Create Account',
                ),
              ),
              const SizedBox(height: AppDimensions.paddingLarge),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Already have an account? Sign In'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Column(
      children: [
        _buildRoleCard(
          UserRole.customer,
          'Customer',
          'Shop and buy products',
          Icons.shopping_cart,
          Colors.blue,
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        _buildRoleCard(
          UserRole.vendor,
          'Vendor',
          'Sell your products',
          Icons.store,
          Colors.orange,
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        _buildRoleCard(
          UserRole.admin,
          'Admin',
          'Manage the platform',
          Icons.admin_panel_settings,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildRoleCard(
    UserRole role,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedRole == role;
    
    return Card(
      elevation: isSelected ? AppDimensions.elevationMedium : AppDimensions.elevationLow,
      color: isSelected ? Colors.white : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        side: BorderSide(
          color: isSelected ? color : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedRole = role),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.15) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: AppDimensions.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: AppDimensions.fontMedium,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: AppDimensions.fontSmall,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: color,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVendorInfo() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: Colors.orange, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 20),
              const SizedBox(width: AppDimensions.paddingSmall),
              const Text(
                'Vendor Account',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                  fontSize: AppDimensions.fontMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          const Text(
            'As a vendor, you can:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          _buildVendorFeature('Add and manage your products'),
          _buildVendorFeature('Track orders and sales'),
          _buildVendorFeature('View analytics and reports'),
          _buildVendorFeature('Set your own prices and inventory'),
          const SizedBox(height: AppDimensions.paddingSmall),
          const Text(
            'Note: Your account will need admin approval before you can start selling.',
            style: TextStyle(
              fontSize: AppDimensions.fontSmall,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorFeature(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: AppDimensions.paddingSmall),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(
                fontSize: AppDimensions.fontSmall,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await ref.read(userProvider.notifier).signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        role: _selectedRole,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedRole == UserRole.vendor 
                  ? 'Vendor account created! Please wait for admin approval.'
                  : 'Account created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        print('Registration error: $e'); // Debug print
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
} 