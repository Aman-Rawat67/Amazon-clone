import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_constants.dart';
import '../../utils/validators.dart';
import '../../models/user_model.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_button.dart';
import 'package:flutter/foundation.dart';

/// Login screen for user authentication
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _keepSignedIn = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handle email/password sign in
  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(userProvider.notifier).signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (mounted) {
        // Check if there's a redirect parameter
        final redirectTo = GoRouterState.of(context).uri.queryParameters['redirect'];
        if (redirectTo != null && redirectTo.isNotEmpty) {
          context.go(redirectTo);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// Handle Google sign in
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(userProvider.notifier).signInWithGoogle();
      
      if (mounted) {
        // Check if there's a redirect parameter
        final redirectTo = GoRouterState.of(context).uri.queryParameters['redirect'];
        if (redirectTo != null && redirectTo.isNotEmpty) {
          context.go(redirectTo);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// Handle forgot password
  Future<void> _forgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    try {
      await ref.read(userProvider.notifier).sendPasswordResetEmail(
        _emailController.text.trim(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: SingleChildScrollView(
          child: LayoutBuilder(
            builder: (context, constraints) {
              double cardWidth = 350;
              EdgeInsets cardPadding = const EdgeInsets.symmetric(vertical: 28, horizontal: 28);
              double logoHeight = 48;
              double fontSize = 24;
              if (constraints.maxWidth < 500) {
                cardWidth = constraints.maxWidth * 0.95;
                cardPadding = const EdgeInsets.symmetric(vertical: 18, horizontal: 12);
                logoHeight = 36;
                fontSize = 20;
              } else if (constraints.maxWidth < 900) {
                cardWidth = 400;
                cardPadding = const EdgeInsets.symmetric(vertical: 24, horizontal: 20);
                logoHeight = 44;
                fontSize = 22;
              }
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Amazon logo
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Image.network(
                      'https://via.placeholder.com/200x60/232F3E/FFFFFF?text=Amazon+Clone',
                      height: logoHeight,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: logoHeight,
                          width: 200,
                          decoration: BoxDecoration(
                            color: const Color(0xFF232F3E),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'Amazon Clone',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    width: cardWidth,
                    padding: cardPadding,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFD5D9D9)),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Login',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Email or mobile phone number',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500, 
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _emailController,
                                validator: Validators.validateEmailOrPhone,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(3),
                                    borderSide: const BorderSide(color: Color(0xFFD5D9D9)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(3),
                                    borderSide: const BorderSide(color: Color(0xFFD5D9D9)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(3),
                                    borderSide: const BorderSide(color: Color(0xFFF3A847)),
                                  ),
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Password',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500, 
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: _forgotPassword,
                                      child: Text(
                                        'Forgot Password',
                                        style: TextStyle(
                                          color: const Color(0xFF007185),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                          decoration: kIsWeb ? TextDecoration.underline : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                validator: Validators.validatePassword,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(3),
                                    borderSide: const BorderSide(color: Color(0xFFD5D9D9)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(3),
                                    borderSide: const BorderSide(color: Color(0xFFD5D9D9)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(3),
                                    borderSide: const BorderSide(color: Color(0xFFF3A847)),
                                  ),
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _keepSignedIn,
                                    onChanged: (val) => setState(() => _keepSignedIn = val ?? false),
                                    activeColor: const Color(0xFFF3A847),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  const Text(
                                    'Keep me signed in.', 
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () {},
                                      child: Text(
                                        'Details',
                                        style: TextStyle(
                                          color: const Color(0xFF007185),
                                          fontSize: 13,
                                          decoration: kIsWeb ? TextDecoration.underline : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                height: 38,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _signInWithEmail,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF3A847),
                                    foregroundColor: Colors.black,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                        )
                                      : const Text('Login'),
                                ),
                              ),
                              const SizedBox(height: 18),
                              
                              // Demo Accounts Section
                              _buildDemoAccountsSection(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: cardWidth,
                    child: Column(
                      children: [
                        const Divider(height: 1, color: Color(0xFFD5D9D9)),
                        const SizedBox(height: 18),
                        Center(
                          child: Text(
                            'New to Amazon?',
                            style: TextStyle(color: Colors.black87, fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 38,
                          child: OutlinedButton(
                            onPressed: () => context.go('/register'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFD5D9D9)),
                              backgroundColor: const Color(0xFFF7F8FA),
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                              textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                            ),
                            child: const Text('Create your Amazon account'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {},
                  child: const Text('Conditions of Use', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF007185)),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {},
                  child: const Text('Privacy Notice', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF007185)),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {},
                  child: const Text('Help', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF007185)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              '© 1996-2024, Amazon.com, Inc. or its affiliates',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoAccountsSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: AppDimensions.paddingSmall),
              const Text(
                'Demo Accounts',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          const Text(
            'Use these accounts for testing:',
            style: TextStyle(fontSize: AppDimensions.fontSmall),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          
          _buildDemoAccountButton(
            'Customer Demo',
            'customer@demo.com',
            'password123',
            Icons.shopping_cart,
            Colors.blue,
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          _buildDemoAccountButton(
            'Vendor Demo',
            'vendor@gmail.com',
            '12345678',
            Icons.store,
            Colors.orange,
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          _buildDemoAccountButton(
            'Admin Demo',
            'admin@demo.com',
            'password123',
            Icons.admin_panel_settings,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildDemoAccountButton(
    String title,
    String email,
    String password,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () => _fillDemoCredentials(email, password),
      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingSmall),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppDimensions.paddingSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppDimensions.fontSmall,
                      color: color,
                    ),
                  ),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: AppDimensions.fontSmall,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  void _fillDemoCredentials(String email, String password) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demo credentials filled. Click "Login" to continue.'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }
} 