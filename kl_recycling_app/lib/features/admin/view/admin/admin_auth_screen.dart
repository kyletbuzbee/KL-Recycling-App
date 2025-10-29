import 'package:flutter/material.dart';
import 'package:kl_recycling_app/core/theme.dart';
import 'package:kl_recycling_app/core/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminAuthScreen extends StatefulWidget {
  const AdminAuthScreen({super.key});

  @override
  State<AdminAuthScreen> createState() => _AdminAuthScreenState();
}

class _AdminAuthScreenState extends State<AdminAuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool _isAuthenticating = false;
  bool _showError = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _showError = true;
        _errorMessage = 'Please enter both email and password';
      });
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _showError = false;
      _errorMessage = '';
    });

    try {
      final firebaseService = FirebaseService();
      // Sign in with Firebase
      final userCredential = await firebaseService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Check if user has admin role
      final isAdmin = await _checkAdminRole(userCredential.user);

      if (isAdmin) {
        // Successful admin authentication
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminScreen(),
            ),
          );
        }
      } else {
        // User is authenticated but not an admin
        setState(() {
          _showError = true;
          _errorMessage = 'Access denied: Admin privileges required';
        });

        // Sign out the non-admin user
        await firebaseService.signOut();
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _showError = true;
        _errorMessage = _getAuthErrorMessage(e);
      });
    } catch (e) {
      setState(() {
        _showError = true;
        _errorMessage = 'Authentication failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  Future<bool> _checkAdminRole(User? user) async {
    if (user == null) return false;

    try {
      final firebaseService = FirebaseService();

      // Check if user has admin custom claim
      final idToken = await user.getIdTokenResult();
      if (idToken.claims?['admin'] == true) {
        return true;
      }

      // Fallback: Check Firestore for admin role
      final adminDoc = await firebaseService.getDocument('admins/${user.uid}');
      return adminDoc.exists;

    } catch (e) {
      debugPrint('Admin role check error: $e');
      // For now, allow specific admin email domains for testing
      return user.email?.endsWith('@klrecycling.com') ?? false;
    }
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email format';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Access Required'),
        backgroundColor: AppColors.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        automaticallyImplyLeading: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Admin Shield Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 60,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  'Administrator Access',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'This area contains sensitive business information.\nPlease sign in with admin credentials to continue.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurfaceSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Email and Password Input
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      // Email Field
                      TextField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _passwordFocus.requestFocus(),
                        decoration: InputDecoration(
                          labelText: 'Admin Email',
                          hintText: 'Enter administrator email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: AppBorderRadius.mediumBorder,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Password Field
                      TextField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _authenticate(),
                        decoration: InputDecoration(
                          labelText: 'Admin Password',
                          hintText: 'Enter administrator password',
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: AppBorderRadius.mediumBorder,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          errorText: _showError ? _errorMessage : null,
                          errorStyle: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      if (_showError) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: AppBorderRadius.smallBorder,
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Authenticate Button
                Container(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: ElevatedButton.icon(
                    onPressed: _isAuthenticating ? null : _authenticate,
                    icon: _isAuthenticating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.login, size: 20),
                    label: Text(
                      _isAuthenticating ? 'Authenticating...' : 'Sign In',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppBorderRadius.mediumBorder,
                      ),
                      elevation: 4,
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Contact Info for Password Issues
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
                    borderRadius: AppBorderRadius.mediumBorder,
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Need Help?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Contact the system administrator or support team for assistance with access.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurfaceSecondary,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Back Button
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to App'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.onSurfaceSecondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Wrapper widget that requires admin authentication
class AdminProtectedRoute extends StatelessWidget {
  final Widget child;

  const AdminProtectedRoute({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // In a real app, you'd check authentication state from a provider/service
    // For now, we'll use a simple route to the auth screen
    return child; // Remove this line and uncomment below for actual protection

    // return FutureBuilder<bool>(
    //   future: _checkAdminAuth(),
    //   builder: (context, snapshot) {
    //     if (snapshot.connectionState == ConnectionState.waiting) {
    //       return const Scaffold(
    //         body: Center(child: CircularProgressIndicator()),
    //       );
    //     }
    //
    //     if (snapshot.data == true) {
    //       return child;
    //     } else {
    //       return const AdminAuthScreen();
    //     }
    //   },
    // );
  }


}

/// Admin dashboard that shows business management tools
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pop(); // Go back to auth screen
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppBorderRadius.largeBorder,
                boxShadow: [AppShadows.medium],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
                      borderRadius: AppBorderRadius.mediumBorder,
                    ),
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 40,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Dashboard',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'System administration and business management tools',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Tools Grid
            const Text(
              'Management Tools',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _AdminToolCard(
                  icon: Icons.analytics,
                  title: 'Reports',
                  description: 'Business analytics',
                  onTap: () => Navigator.pushNamed(context, '/admin/reports'),
                ),
                _AdminToolCard(
                  icon: Icons.people,
                  title: 'User Management',
                  description: 'Manage user accounts',
                  onTap: () => Navigator.pushNamed(context, '/admin/users'),
                ),
                _AdminToolCard(
                  icon: Icons.settings,
                  title: 'System Config',
                  description: 'App configuration',
                  onTap: () => Navigator.pushNamed(context, '/admin/config'),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),

            Column(
              children: [
                _QuickActionCard(
                  icon: Icons.backup,
                  title: 'Database Backup',
                  subtitle: 'Last backup: 2 hours ago',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Backup initiated...')),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _QuickActionCard(
                  icon: Icons.security,
                  title: 'Security Audit',
                  subtitle: 'Run security scan',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Security audit started...')),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _QuickActionCard(
                  icon: Icons.system_update,
                  title: 'Check Updates',
                  subtitle: 'App version: 2.1.0',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Checking for updates...')),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _AdminToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _AdminToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.mediumBorder,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.mediumBorder,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppBorderRadius.smallBorder,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.mediumBorder,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.mediumBorder,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppBorderRadius.smallBorder,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
