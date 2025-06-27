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
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
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
              LoadingButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _isLoading = true);
                    try {
                      await ref.read(userProvider.notifier).signUpWithEmail(
                        email: _emailController.text,
                        password: _passwordController.text,
                        name: _nameController.text,
                        role: _selectedRole,
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                    setState(() => _isLoading = false);
                  }
                },
                isLoading: _isLoading,
                text: 'Register',
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Already have an account? Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 