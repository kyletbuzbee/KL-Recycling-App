import 'package:flutter/material.dart';
import 'package:kl_recycling_app/config/constants.dart';
import 'package:kl_recycling_app/config/animations.dart';
import 'package:kl_recycling_app/config/theme.dart';
import 'package:kl_recycling_app/widgets/common/custom_card.dart';
import 'package:kl_recycling_app/screens/forms/container_quote_form.dart';
import 'package:kl_recycling_app/screens/forms/scrap_pickup_form.dart';
import 'package:kl_recycling_app/screens/forms/container_service_form.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Our Services',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.onPrimary,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
          ),
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(
                  child: Text(
                    'General',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Tab(
                  child: Text(
                    'Specialized',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Tab(
                  child: Text(
                    'Equipment',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.onSurfaceSecondary,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ),
      ),
      body: Container(
        color: AppColors.surface,
        child: TabBarView(
          controller: _tabController,
          children: const [
            GeneralServicesTab(),
            SpecializedServicesTab(),
            EquipmentServicesTab(),
          ],
        ),
      ),
    );
  }
}

class GeneralServicesTab extends StatelessWidget {
  const GeneralServicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final generalServices = AppConstants.services.where((service) => service['category'] == 'general').toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppAnimations.fadeIn(
                  Text(
                    'General Recycling Services',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.onSurface,
                    ),
                  ),
                  delay: const Duration(milliseconds: 100),
                ),
                const SizedBox(height: 12),
                AppAnimations.slideUp(
                  Text(
                    'Flexible solutions for residential and commercial scrap metal recycling',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.onSurfaceSecondary,
                      height: 1.6,
                    ),
                  ),
                  delay: const Duration(milliseconds: 150),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              childCount: generalServices.length,
              (context, index) {
                return AppAnimations.slideUp(
                  ServiceCard(service: generalServices[index]),
                  delay: Duration(milliseconds: 200 + (index * 100)),
                );
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class SpecializedServicesTab extends StatelessWidget {
  const SpecializedServicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Specialized Services',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Expert handling of specific materials and equipment',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),
        ...AppConstants.services.where((service) => service['category'] != 'general' && service['category'] != 'equipment').map((service) => ServiceCard(service: service)),
      ],
    );
  }
}

class EquipmentServicesTab extends StatelessWidget {
  const EquipmentServicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Equipment Rentals',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Heavy equipment and containers for large-scale projects',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),
        ...AppConstants.services.where((service) => service['category'] == 'equipment').map((service) => ServiceCard(service: service)),
      ],
    );
  }
}

class ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final Duration animationDelay;

  const ServiceCard({
    super.key,
    required this.service,
    this.animationDelay = Duration.zero
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      animationDelay: animationDelay,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Image Banner
          AppAnimations.fadeIn(
            ClipRRect(
              borderRadius: AppBorderRadius.mediumBorder,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.2),
                      Theme.of(context).primaryColor.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppBorderRadius.mediumBorder,
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.9),
                          borderRadius: AppBorderRadius.largeBorder,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          _getServiceIcon(service['icon'].toString()),
                          size: 48,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        service['name'].toString(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            delay: const Duration(milliseconds: 100),
          ),

          const SizedBox(height: 20),

          // Service Description
          AppAnimations.slideUp(
            Text(
              service['description'].toString(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurfaceSecondary,
                height: 1.6,
              ),
            ),
            delay: const Duration(milliseconds: 200),
          ),

          const SizedBox(height: 20),

          // Features list
          if (service['features'] != null) ...[
            AppAnimations.fadeIn(
              Text(
                'Features:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              delay: const Duration(milliseconds: 300),
            ),
            const SizedBox(height: 12),
            AppAnimations.slideUp(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (service['features'] as List<dynamic>).asMap().entries.map((entry) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value.toString(),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).toList(),
              ),
              delay: const Duration(milliseconds: 350),
            ),
          ],

          // Sizes list (for container services)
          if (service['sizes'] != null) ...[
            const SizedBox(height: 16),
            AppAnimations.fadeIn(
              Text(
                'Available Sizes:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              delay: const Duration(milliseconds: 400),
            ),
            const SizedBox(height: 12),
            AppAnimations.scaleIn(
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: (service['sizes'] as List<dynamic>).map((size) =>
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: AppBorderRadius.smallBorder,
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      size.toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ).toList(),
              ),
              delay: const Duration(milliseconds: 450),
            ),
          ],

          const SizedBox(height: 24),

          // Action Button
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
                  onPressed: () => _handleServiceAction(context, service),
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
                  child: Text(
                    service['cta']?.toString() ?? 'Learn More',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            delay: const Duration(milliseconds: 500),
          ),
        ],
      ),
    );
  }

  IconData _getServiceIcon(String iconName) {
    switch (iconName) {
      case 'truck':
        return Icons.local_shipping;
      case 'recycle':
        return Icons.recycling;
      case 'container':
        return Icons.inventory_2;
      default:
        return Icons.build;
    }
  }

  void _handleServiceAction(BuildContext context, Map<String, dynamic> service) {
    // Handle different service actions based on service type
    final serviceName = service['name'].toString();
    final serviceId = service['id'].toString();

    if (serviceId == 'roll-off-containers') {
      // Navigate to container quote form
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ContainerQuoteForm(containerType: serviceName),
        ),
      );
    } else if (serviceId == 'scrap-metal-pickup') {
      // Navigate to scrap pickup form
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ScrapPickupForm(),
        ),
      );
    } else if (serviceId == 'container-service') {
      // Navigate to container service form
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ContainerServiceForm(serviceType: serviceName),
        ),
      );
    } else {
      // Fallback for other services
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Service inquiry for $serviceName coming soon!')),
      );
    }
  }
}
