import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kl_recycling_app/config/theme.dart';
import 'package:kl_recycling_app/config/constants.dart';
import 'package:kl_recycling_app/config/animations.dart';
import 'package:kl_recycling_app/widgets/common/custom_card.dart';
import 'package:kl_recycling_app/providers/loyalty_provider.dart';
import 'package:kl_recycling_app/models/loyalty.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _heroAnimationController;
  late Animation<double> _heroFadeAnimation;
  late Animation<Offset> _heroSlideAnimation;

  @override
  void initState() {
    super.initState();
    _heroAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _heroFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heroAnimationController,
      curve: Curves.easeOut,
    ));

    _heroSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _heroAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _heroAnimationController.forward();
  }

  @override
  void dispose() {
    _heroAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(2),
                  child: Image.asset(
                    AppConstants.logoPath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.white,
                        child: const Icon(
                          Icons.business,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'K&L Recycling',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          Consumer<LoyaltyProvider>(
            builder: (context, loyaltyProvider, child) {
              if (loyaltyProvider.currentTier == LoyaltyTier.bronze && loyaltyProvider.totalPoints == 0) {
                return const SizedBox.shrink(); // Don't show for new users
              }
              return IconButton(
                icon: Icon(
                  loyaltyProvider.currentTier.icon,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.pushNamed(context, '/loyalty'),
                tooltip: '${loyaltyProvider.currentTier.title} - ${loyaltyProvider.currentPoints} points',
              );
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.white),
            onPressed: () => _callBusiness(context),
            tooltip: 'Call Us',
          ),
          const SizedBox(width: 8),
        ],
      ),
      backgroundColor: AppColors.background,
      body: AppAnimations.fadeIn(
        CustomScrollView(
          slivers: [
            // Enhanced Hero Section with Image Background and Animation
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  // Hero Image Background
                  Container(
                    height: 320,
                    decoration: BoxDecoration(
                      gradient: AppGradients.heroBackground,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                      boxShadow: [AppShadows.medium],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                      child: Stack(
                        children: [
                          // Placeholder with icon (can be replaced with real image)
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withOpacity(0.3),
                                  AppColors.primary.withOpacity(0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                          // Overlay pattern/circuit board effect would go here
                          Positioned(
                            right: 20,
                            bottom: 20,
                            child: Icon(
                              Icons.recycling,
                              size: 120,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content Overlay
                  Container(
                    height: 320,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: FadeTransition(
                      opacity: _heroFadeAnimation,
                      child: SlideTransition(
                        position: _heroSlideAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppAnimations.scaleIn(
                              Text(
                                'Welcome to K&L Recycling',
                                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4,
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(1, 1),
                                    ),
                                  ],
                                ),
                              ),
                              delay: const Duration(milliseconds: 300),
                            ),
                            const SizedBox(height: 16),
                            AppAnimations.slideUp(
                              Text(
                                'Leading provider of mobile car crushing, oil & gas demolition, roll-off containers, and public recycling drop-off locations in Texas',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.white.withOpacity(0.95),
                                  height: 1.6,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 3,
                                      color: Colors.black.withOpacity(0.2),
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                              delay: const Duration(milliseconds: 500),
                            ),
                            const SizedBox(height: 32),
                            AppAnimations.bounceIn(
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: AppGradients.buttonGlow,
                                        borderRadius: AppBorderRadius.mediumBorder,
                                        boxShadow: [AppShadows.medium],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () => _navigateToServices(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: AppColors.onPrimary,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          elevation: 0,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: AppBorderRadius.mediumBorder,
                                          ),
                                        ),
                                        child: const Text(
                                          'Explore Services',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                                        borderRadius: AppBorderRadius.mediumBorder,
                                      ),
                                      child: OutlinedButton(
                                        onPressed: () => _navigateToCamera(context),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          side: BorderSide.none,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: AppBorderRadius.mediumBorder,
                                          ),
                                        ),
                                        child: const Text(
                                          'Estimate Weight',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              delay: const Duration(milliseconds: 700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Quick Actions Section
            SliverToBoxAdapter(
              child: AppAnimations.slideUp(
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppAnimations.fadeIn(
                        Text(
                          'Quick Actions',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                        delay: const Duration(milliseconds: 900),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: AppAnimations.rotateIn(
                              _AnimatedQuickActionCard(
                                icon: Icons.camera_alt,
                                label: 'Photo Estimate',
                                backgroundColor: AppColors.info.withOpacity(0.1),
                                iconColor: AppColors.info,
                                onTap: () => _navigateToCamera(context),
                              ),
                              delay: const Duration(milliseconds: 1000),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppAnimations.rotateIn(
                              _AnimatedQuickActionCard(
                                icon: Icons.local_shipping,
                                label: 'Container Quote',
                                backgroundColor: AppColors.success.withOpacity(0.1),
                                iconColor: AppColors.success,
                                onTap: () => _navigateToContainerQuote(context),
                              ),
                              delay: const Duration(milliseconds: 1100),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AppAnimations.rotateIn(
                              _AnimatedQuickActionCard(
                                icon: Icons.phone,
                                label: 'Call Us',
                                backgroundColor: AppColors.primaryLight.withOpacity(0.1),
                                iconColor: AppColors.primary,
                                onTap: () => _callBusiness(context),
                              ),
                              delay: const Duration(milliseconds: 1200),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppAnimations.rotateIn(
                              _AnimatedQuickActionCard(
                                icon: Icons.location_on,
                                label: 'Locations',
                                backgroundColor: AppColors.info.withOpacity(0.1),
                                iconColor: AppColors.info,
                                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Locations screen coming soon')),
                                ),
                              ),
                              delay: const Duration(milliseconds: 1300),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                delay: const Duration(milliseconds: 800),
              ),
            ),

            // Why Choose Us Section
            SliverToBoxAdapter(
              child: AppAnimations.slideUp(
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppAnimations.fadeIn(
                        Text(
                          'Why Choose K&L Recycling?',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                        delay: const Duration(milliseconds: 1400),
                      ),
                      const SizedBox(height: 24),
                      StaggeredAnimationList(
                        children: [
                          _EnhancedFeatureCard(
                            icon: Icons.high_quality,
                            title: 'High-Grade Payments',
                            description: 'Get the best rates for your scrap metal with fair, competitive pricing.',
                            color: AppColors.success,
                            animationDelay: const Duration(milliseconds: 1500),
                          ),
                          _EnhancedFeatureCard(
                            icon: Icons.schedule,
                            title: 'Same-Day Service',
                            description: 'Flexible scheduling with same-day pickup options available.',
                            color: AppColors.info,
                            animationDelay: const Duration(milliseconds: 1600),
                          ),
                          _EnhancedFeatureCard(
                            icon: Icons.verified,
                            title: 'Licensed & Insured',
                            description: 'Fully licensed, insured, and committed to safe, professional service.',
                            color: AppColors.primary,
                            animationDelay: const Duration(milliseconds: 1700),
                          ),
                          _EnhancedFeatureCard(
                            icon: Icons.eco,
                            title: 'Environmental Impact',
                            description: 'Metal recycling reduces landfill waste and conserves natural resources.',
                            color: Colors.green[700]!,
                            animationDelay: const Duration(milliseconds: 1800),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                delay: const Duration(milliseconds: 1350),
              ),
            ),

            // Contact Call-to-Action
            SliverToBoxAdapter(
              child: AppAnimations.fadeIn(
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppGradients.cardDepth,
                    borderRadius: AppBorderRadius.extraLargeBorder,
                    boxShadow: [AppShadows.large],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: AppBorderRadius.extraLargeBorder,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppAnimations.scaleIn(
                          Text(
                            'Ready to Get Started?',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          delay: const Duration(milliseconds: 1900),
                        ),
                        const SizedBox(height: 16),
                        AppAnimations.fadeIn(
                          Text(
                            'Call us today or visit our locations for scrap metal recycling and container services.',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.onSurfaceSecondary,
                              height: 1.6,
                            ),
                          ),
                          delay: const Duration(milliseconds: 2000),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            AppAnimations.slideUp(
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: AppGradients.primary,
                                      borderRadius: AppBorderRadius.mediumBorder,
                                      boxShadow: [AppShadows.small],
                                    ),
                                    child: const Icon(
                                      Icons.phone,
                                      size: 20,
                                      color: AppColors.onPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    AppConstants.phoneNumber,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              delay: const Duration(milliseconds: 2100),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AppAnimations.slideUp(
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: AppGradients.primary,
                                  borderRadius: AppBorderRadius.mediumBorder,
                                  boxShadow: [AppShadows.small],
                                ),
                                child: const Icon(
                                  Icons.email,
                                  size: 20,
                                  color: AppColors.onPrimary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                AppConstants.email,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                          delay: const Duration(milliseconds: 2200),
                        ),
                        const SizedBox(height: 32),
                        AppAnimations.bounceIn(
                          SizedBox(
                            width: double.infinity,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: AppGradients.buttonGlow,
                                borderRadius: AppBorderRadius.mediumBorder,
                                boxShadow: [AppShadows.medium],
                              ),
                              child: ElevatedButton(
                                onPressed: () => _navigateToContact(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: AppColors.onPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppBorderRadius.mediumBorder,
                                  ),
                                ),
                                child: const Text(
                                  'Contact Us',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          delay: const Duration(milliseconds: 2300),
                        ),
                      ],
                    ),
                  ),
                ),
                delay: const Duration(milliseconds: 1850),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  void _navigateToServices(BuildContext context) {
    // Navigate to services tab (index 2 in bottom navigation)
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    // Parent widget's bottom navigation will handle tab switching
  }

  void _navigateToCamera(BuildContext context) {
    // This would switch to the camera tab if in main screen
    // For now, show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Camera feature available in the main app')),
    );
  }

  void _navigateToContainerQuote(BuildContext context) {
    // This would navigate to container quote form
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Container quote available in Services')),
    );
  }



  void _callBusiness(BuildContext context) {
    // For web implementation, show contact info
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Call ${AppConstants.phoneNumber}')),
    );
  }

  void _navigateToContact(BuildContext context) {
    // This would navigate to contact screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact screen coming soon')),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: AppColors.primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
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

class _AnimatedQuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _AnimatedQuickActionCard({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: AppBorderRadius.largeBorder,
          border: Border.all(
            color: iconColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: AppBorderRadius.mediumBorder,
                boxShadow: [AppShadows.small],
              ),
              child: Icon(
                icon,
                size: 32,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EnhancedFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Duration animationDelay;

  const _EnhancedFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.animationDelay,
  });

  @override
  Widget build(BuildContext context) {
    return AppAnimations.slideUp(
      CustomCard(
        animationDelay: animationDelay,
        variant: CardVariant.filled,
        margin: const EdgeInsets.only(bottom: 12),
        color: color.withOpacity(0.05),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppBorderRadius.mediumBorder,
                boxShadow: [AppShadows.small],
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: 28,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: color.withOpacity(0.6),
            ),
          ],
        ),
      ),
      delay: animationDelay,
    );
  }
}
