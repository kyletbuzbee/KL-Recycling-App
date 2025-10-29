import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kl_recycling_app/core/theme.dart';
import 'package:kl_recycling_app/core/constants.dart';

import 'package:kl_recycling_app/core/animations.dart';
import 'package:kl_recycling_app/core/widgets/common/custom_card.dart';
import 'package:kl_recycling_app/features/loyalty/view/loyalty/loyalty_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _heroAnimationController;
  late Animation<double> _heroFadeAnimation;
  late Animation<Offset> _heroSlideAnimation;

  final ScrollController _scrollController = ScrollController();
  late AnimationController _appBarAnimationController;
  late Animation<double> _appBarOpacityAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize hero animations
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

    // Initialize scroll-aware app bar
    _appBarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _appBarOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _appBarAnimationController,
      curve: Curves.easeInOut,
    ));

    // Listen to scroll changes
    _scrollController.addListener(_onScrollChanged);
  }

  @override
  void dispose() {
    _heroAnimationController.dispose();
    _appBarAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScrollChanged() {
    final offset = _scrollController.offset;
    const threshold = 50.0; // Show app bar when scrolled 50px

    if (offset > threshold && !_appBarAnimationController.isCompleted) {
      _appBarAnimationController.forward();
    } else if (offset <= threshold && !_appBarAnimationController.isDismissed) {
      _appBarAnimationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.background,
      body: AppAnimations.fadeIn(
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Transparent Scrolling AppBar
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              floating: true,
              pinned: true,
              snap: false,
              stretchTriggerOffset: 200,
              onStretchTrigger: () {
                // Could add refresh logic here
                return Future<void>.value();
              },
              expandedHeight: MediaQuery.of(context).size.height * 0.08,
              flexibleSpace: AnimatedBuilder(
                animation: _appBarOpacityAnimation,
                builder: (context, child) => Container(
                  color: AppColors.primary.withValues(alpha: _appBarOpacityAnimation.value),
                  child: child,
                ),
                child: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: _appBarOpacityAnimation.value * 0.95),
                      // Optional glassmorphism effect when scrolled
                      boxShadow: _appBarOpacityAnimation.value > 0.1 ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Container(
                            color: Theme.of(context).colorScheme.surface,
                            padding: const EdgeInsets.all(2),
                            child: Image.asset(
                              AppConstants.logoPath,
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Theme.of(context).colorScheme.surface,
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'K&L Recycling',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.phone, color: Theme.of(context).colorScheme.onPrimary),
                          onPressed: () => _callBusiness(context),
                          tooltip: 'Call Us',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
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
                                  AppColors.primary.withValues(alpha: 0.3),
                                  AppColors.primary.withValues(alpha: 0.1),
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
                              color: Colors.white.withValues(alpha: 0.1),
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
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4,
                                      color: Colors.black.withValues(alpha: 0.3),
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
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.95),
                                  height: 1.6,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 3,
                                      color: Colors.black.withValues(alpha: 0.2),
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
                                        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), width: 2),
                                        borderRadius: AppBorderRadius.mediumBorder,
                                      ),
                                      child: OutlinedButton(
                                        onPressed: () => _navigateToCamera(context),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Theme.of(context).colorScheme.onSurface,
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
                                assetPath: 'assets/icons/loyalty_points_balance.png',
                                label: 'My Loyalty',
                                backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                                iconColor: AppColors.primary,
                                onTap: () => _navigateToLoyalty(context),
                              ),
                              delay: const Duration(milliseconds: 1000),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppAnimations.rotateIn(
                              _AnimatedQuickActionCard(
                                assetPath: 'assets/icons/container_roll_off.png',
                                label: 'Container Quote',
                                backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                                iconColor: AppColors.primary,
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
                                assetPath: 'assets/icons/contact_phone.png',
                                label: 'Call Us',
                                backgroundColor: AppColors.primaryLight.withValues(alpha: 0.1),
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
                                assetPath: 'assets/icons/location_pin_service.png',
                                label: 'Locations',
                                backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                                iconColor: AppColors.primary,
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
                      Column(
                        children: [
                          _EnhancedFeatureCard(
                            assetPath: 'assets/icons/weight_scale_accurate.png',
                            title: 'High-Grade Payments',
                            description: 'Get the best rates for your scrap metal with fair, competitive pricing.',
                            color: AppColors.primary,
                            animationDelay: const Duration(milliseconds: 1500),
                          ),
                          _EnhancedFeatureCard(
                            assetPath: 'assets/icons/pickup_schedule_calendar.png',
                            title: 'Same-Day Service',
                            description: 'Flexible scheduling with same-day pickup options available.',
                            color: AppColors.primary,
                            animationDelay: const Duration(milliseconds: 1600),
                          ),
                          _EnhancedFeatureCard(
                            assetPath: 'assets/icons/quality_control_verified.png',
                            title: 'Licensed & Insured',
                            description: 'Fully licensed, insured, and committed to safe, professional service.',
                            color: AppColors.primary,
                            animationDelay: const Duration(milliseconds: 1700),
                          ),
                          _EnhancedFeatureCard(
                            assetPath: 'assets/icons/environmental_savings.png',
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
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: AppBorderRadius.extraLargeBorder,
                    boxShadow: [AppShadows.large],
                  ),
                  padding: const EdgeInsets.all(24),
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
                      Text(
                        'Call us today or visit our locations for scrap metal recycling and container services.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.onSurfaceSecondary,
                          height: 1.6,
                        ),
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
                                  child: Image.asset(
                                    'assets/icons/contact_phone.png',
                                    width: 28,
                                    height: 28,
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
                                size: 28,
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
                delay: const Duration(milliseconds: 1850),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
        ),
      ),
    );
  }

  void _navigateToServices(BuildContext context) {
    HapticFeedback.lightImpact();
    // Navigate to services tab (index 2 in bottom navigation)
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    // Parent widget's bottom navigation will handle tab switching
  }

  void _navigateToCamera(BuildContext context) {
    HapticFeedback.lightImpact();
    // This would switch to the camera tab if in main screen
    // For now, show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Camera feature available in the main app')),
    );
  }

  void _navigateToContainerQuote(BuildContext context) {
    HapticFeedback.lightImpact();
    // This would navigate to container quote form
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Container quote available in Services')),
    );
  }

  void _callBusiness(BuildContext context) {
    HapticFeedback.lightImpact();
    // For web implementation, show contact info
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Call ${AppConstants.phoneNumber}')),
    );
  }

  void _navigateToContact(BuildContext context) {
    HapticFeedback.lightImpact();
    // This would navigate to contact screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact screen coming soon')),
    );
  }

  void _navigateToLoyalty(BuildContext context) {
    HapticFeedback.lightImpact();
    // Navigate to loyalty dashboard screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoyaltyDashboardScreen(),
      ),
    );
  }
}





class _AnimatedQuickActionCard extends StatefulWidget {
  final IconData? icon;
  final String? assetPath;
  final String label;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _AnimatedQuickActionCard({
    this.icon,
    this.assetPath,
    required this.label,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  }) : assert(icon != null || assetPath != null, 'Either icon or assetPath must be provided');

  @override
  State<_AnimatedQuickActionCard> createState() => _AnimatedQuickActionCardState();
}

class _AnimatedQuickActionCardState extends State<_AnimatedQuickActionCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.3),
            borderRadius: AppBorderRadius.largeBorder,
            border: Border.all(
              color: widget.iconColor.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [AppShadows.small],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: AppBorderRadius.mediumBorder,
                  boxShadow: [AppShadows.small],
                ),
                      child: widget.assetPath != null
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: widget.iconColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        Image.asset(
                          widget.assetPath!,
                          width: 30,
                          height: 30,
                          fit: BoxFit.contain,
                        ),
                      ],
                    )
                  : Icon(
                      widget.icon!,
                      size: 40,
                      color: widget.iconColor,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.label,
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
      ),
    );
  }
}

class _EnhancedFeatureCard extends StatelessWidget {
  final IconData? icon;
  final String? assetPath;
  final String title;
  final String description;
  final Color color;
  final Duration animationDelay;

  const _EnhancedFeatureCard({
    this.icon,
    this.assetPath,
    required this.title,
    required this.description,
    required this.color,
    required this.animationDelay,
  }) : assert(icon != null || assetPath != null, 'Either icon or assetPath must be provided');

  @override
  Widget build(BuildContext context) {
    return AppAnimations.slideUp(
      CustomCard(
        animationDelay: animationDelay,
        variant: CardVariant.filled,
        margin: const EdgeInsets.only(bottom: 12),
        color: color.withValues(alpha: 0.05),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppBorderRadius.mediumBorder,
                boxShadow: [AppShadows.small],
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: assetPath != null
                  ? Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.asset(
                        assetPath!,
                        width: 26,
                        height: 26,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Icon(
                      icon,
                      size: 36,
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
              size: 20,
              color: color.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
      delay: animationDelay,
    );
  }
}
