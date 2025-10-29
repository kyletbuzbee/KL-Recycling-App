import 'package:flutter/material.dart';
import 'package:kl_recycling_app/core/theme.dart';
import 'package:kl_recycling_app/core/constants.dart';

import 'package:kl_recycling_app/core/widgets/common/themed_card.dart';
import 'package:kl_recycling_app/features/contact/view/contact_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationsScreen extends StatelessWidget {
  const LocationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Locations & Service Areas'),
        backgroundColor: AppColors.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Our Locations',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 16),

            // Main Location Card
            ThemedCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.warehouse,
                          size: 32,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Main Office & Yard',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppConstants.address,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Phone
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppConstants.phoneNumber,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Hours
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Business Hours:',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text('Monday - Friday: 7:30 AM - 5:00 PM',
                                style: Theme.of(context).textTheme.bodyMedium),
                            Text('Saturday: 8:00 AM - 12:00 PM',
                                style: Theme.of(context).textTheme.bodyMedium),
                            Text('Sunday: Closed',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _callLocation(context),
                      icon: const Icon(Icons.phone),
                      label: const Text('Call Location'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Service Areas
            Text(
              'Service Areas',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'We provide scrap metal recycling and container services within a ${AppConstants.serviceRadiusMiles}-mile radius of our main yard',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.onSurface.withValues(alpha: 0.8),
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Cities We Serve
            ThemedCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Major Cities & Areas Served',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.onSurface,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _ServiceAreaChip(label: 'Tyler, TX'),
                      _ServiceAreaChip(label: 'Longview, TX'),
                      _ServiceAreaChip(label: 'Kilgore, TX'),
                      _ServiceAreaChip(label: 'Gladewater, TX'),
                      _ServiceAreaChip(label: 'White Oak, TX'),
                      _ServiceAreaChip(label: 'Big Sandy, TX'),
                      _ServiceAreaChip(label: 'Hawkins, TX'),
                      _ServiceAreaChip(label: 'Winona, TX'),
                      _ServiceAreaChip(label: 'Mineola, TX'),
                      _ServiceAreaChip(label: 'Quitman, TX'),
                      _ServiceAreaChip(label: 'Canton, TX'),
                      _ServiceAreaChip(label: 'Grand Saline, TX'),
                      _ServiceAreaChip(label: 'Van, TX'),
                      _ServiceAreaChip(label: 'Chandler, TX'),
                      _ServiceAreaChip(label: 'Bullard, TX'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Additional Information
            ThemedCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Our Core Services',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _InfoRow(
                    icon: Icons.location_city,
                    title: 'Public Drop Off',
                    description:
                        'Convenient drop-off locations for all your scrap metal recycling needs.',
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    icon: Icons.build,
                    title: 'Mobile Car Crushing',
                    description:
                        'Efficient and environmentally friendly on-site car crushing services.',
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    icon: Icons.inventory_2,
                    title: 'Roll-Off Containers',
                    description:
                        'A wide range of container sizes available for commercial and industrial projects.',
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    icon: Icons.construction,
                    title: 'Oil & Gas Demolition',
                    description:
                        'Specialized demolition services for the oil and gas industry, ensuring safety and compliance.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Call to Action
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need Service Outside Our Area?',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Contact us for special arrangements or to discuss services beyond our regular service radius.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                      color: AppColors.onSurface.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _contactForSpecialService(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Contact for Special Service'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _callLocation(BuildContext context) async {
    final phoneUrl = Uri.parse('tel:${AppConstants.phoneNumber}');
    try {
      if (await canLaunchUrl(phoneUrl)) {
        await launchUrl(phoneUrl);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Unable to make phone calls on this device')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error making call: $e')),
      );
    }
  }

  void _contactForSpecialService(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ContactScreen()),
    );
  }
}

class _ServiceAreaChip extends StatelessWidget {
  final String label;

  const _ServiceAreaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showAreaInfo(context, label),
      borderRadius: BorderRadius.circular(16),
      child: Chip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.primary.withValues(alpha: 0.3),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.75)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Future<void> _callLocation(BuildContext context) async {
    final phoneUrl = Uri.parse('tel:${AppConstants.phoneNumber}');
    try {
      if (await canLaunchUrl(phoneUrl)) {
        await launchUrl(phoneUrl);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Unable to make phone calls on this device')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error making call: $e')),
      );
    }
  }

  void _showAreaInfo(BuildContext context, String area) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Service available in $area • Call for pricing & scheduling'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Call Now',
          onPressed: () => _callLocation(context),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
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
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
