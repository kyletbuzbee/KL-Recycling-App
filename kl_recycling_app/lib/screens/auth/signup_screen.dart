import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_card.dart';
import '../../config/theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _firstNameFocusNode = FocusNode();
  final _lastNameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.heroBackground,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Section
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 32),

                // Signup Form
                CustomCard(
                  padding: const EdgeInsets.all(24),
                  borderRadius: AppBorderRadius.largeBorder,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle(),
                      const SizedBox(height: 32),
                      _buildForm(context, authProvider),
                      const SizedBox(height: 24),
                      if (authProvider.errorMessage != null) ...[
                        _buildErrorMessage(authProvider.errorMessage!),
                        const SizedBox(height: 16),
                      ],
                      _buildActions(context),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Social Signup Section
                _buildSocialSignup(context),

                const SizedBox(height: 32),

                // Footer
                _buildFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: AppBorderRadius.largeBorder,
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.business_center,
            size: 48,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Join K&L Recycling',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Account',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your information to get started',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.onSurfaceSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, AuthProvider authProvider) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Name Fields Row
          Row(
            children: [
              // First Name
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  focusNode: _firstNameFocusNode,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    hintText: 'John',
                    prefixIcon: const Icon(Icons.person),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'First name required';
                    }
                    if (value.trim().length < 2) {
                      return 'First name too short';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _lastNameFocusNode.requestFocus(),
                ),
              ),

              const SizedBox(width: 16),

              // Last Name
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  focusNode: _lastNameFocusNode,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    hintText: 'Doe',
                    prefixIcon: const Icon(Icons.person_outlined),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Last name required';
                    }
                    if (value.trim().length < 2) {
                      return 'Last name too short';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Email Field
          TextFormField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'john.doe@example.com',
              prefixIcon: const Icon(Icons.email),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: AppColors.surface,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email required';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                return 'Enter a valid email';
              }
              return null;
            },
            onFieldSubmitted: (_) => _phoneFocusNode.requestFocus(),
          ),

          const SizedBox(height: 20),

          // Phone Field (Optional)
          TextFormField(
            controller: _phoneController,
            focusNode: _phoneFocusNode,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Phone Number (Optional)',
              hintText: '(903) 555-0123',
              prefixIcon: const Icon(Icons.phone),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: AppColors.surface,
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                // Basic phone validation - allow any format for now
                if (value.length < 10) {
                  return 'Phone number too short';
                }
                if (!RegExp(r'^[\d\(\)\-\s\.]+$').hasMatch(value)) {
                  return 'Enter a valid phone number';
                }
              }
              return null;
            },
            onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
          ),

          const SizedBox(height: 20),

          // Password Field
          TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Create a strong password',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: AppColors.surface,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password required';
              }
              if (value.length < 6) {
                return 'Must be at least 6 characters';
              }
              if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
                return 'Include at least one uppercase letter';
              }
              if (!RegExp(r'(?=.*\d)').hasMatch(value)) {
                return 'Include at least one number';
              }
              return null;
            },
            onFieldSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
          ),

          const SizedBox(height: 20),

          // Confirm Password Field
          TextFormField(
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocusNode,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              hintText: 'Re-enter your password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                },
              ),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: AppColors.surface,
            ),
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            onFieldSubmitted: (_) => _submitForm(authProvider),
          ),

          const SizedBox(height: 16),

          // Terms & Conditions Checkbox
          Row(
            children: [
              Checkbox(
                value: _acceptTerms,
                onChanged: (value) {
                  setState(() => _acceptTerms = value ?? false);
                },
                activeColor: AppColors.primary,
              ),
              Expanded(
                child: Text(
                  'I agree to the Terms & Conditions and Privacy Policy',
                  style: TextStyle(
                    color: AppColors.onSurfaceSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          if (!_acceptTerms && _formKey.currentState != null && !_formKey.currentState!.validate()) ...[
            Text(
              'You must accept the terms to continue',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: AppBorderRadius.mediumBorder,
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: AppColors.error,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Column(
      children: [
        // Sign Up Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (authProvider.isLoading || !_acceptTerms)
                ? null
                : () => _submitForm(authProvider),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: AppBorderRadius.mediumBorder,
              ),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
              disabledForegroundColor: Colors.white.withOpacity(0.6),
            ),
            child: authProvider.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Create Account',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
          ),
        ),

        const SizedBox(height: 16),

        // Sign In Link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Already have an account?',
              style: TextStyle(color: AppColors.onSurfaceSecondary),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Sign In',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialSignup(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: Colors.white.withOpacity(0.3),
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or sign up with',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: Colors.white.withOpacity(0.3),
                thickness: 1,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: _buildSocialButton(
                context,
                icon: const Icon(Icons.g_mobiledata, color: Colors.white),
                label: 'Google',
                color: const Color(0xFFDB4437),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Google sign up coming soon!')),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSocialButton(
                context,
                icon: const Icon(Icons.api, color: Colors.white),
                label: 'Apple',
                color: Colors.black,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Apple sign up coming soon!')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton(
    BuildContext context, {
    required Icon icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.mediumBorder,
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Text(
          'By creating an account, you agree to our',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                // TODO: Open terms & conditions
              },
              child: Text(
                'Terms & Conditions',
                style: TextStyle(color: Colors.white),
              ),
            ),
            Text(
              ' and ',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Open privacy policy
              },
              child: Text(
                'Privacy Policy',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _submitForm(AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please accept the terms and conditions to continue'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim();
    final password = _passwordController.text;

    final success = await authProvider.signUp(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }
}
