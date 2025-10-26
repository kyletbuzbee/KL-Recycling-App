import 'package:flutter/material.dart';
import 'package:kl_recycling_app/config/theme.dart';
import 'package:kl_recycling_app/config/constants.dart';
import 'package:kl_recycling_app/widgets/common/custom_card.dart';
import 'package:kl_recycling_app/screens/contact_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationsScreen extends StatelessWidget {
  const LocationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Locations & Service Areas'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Our Locations',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Main Location Card
            CustomCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.business,
                          size: 32,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Main Office & Yard',
                          style: TextStyle(
                            fontSize: 20,
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
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppConstants.address,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                          ),
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
                        style: const TextStyle(
                          fontSize: 16,
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
                        Icons.schedule,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Business Hours:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text('Monday - Friday: 7:30 AM - 5:00 PM',
                                style: TextStyle(fontSize: 14)),
                            Text('Saturday: 8:00 AM - 12:00 PM',
                                style: TextStyle(fontSize: 14)),
                            Text('Sunday: Closed',
                                style: TextStyle(fontSize: 14)),
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
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Service Areas
            const Text(
              'Service Areas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We provide scrap metal recycling and container services within a ${AppConstants.serviceRadiusMiles}-mile radius of our main yard',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // Cities We Serve
            CustomCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Major Cities & Areas Served',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
            CustomCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transportation & Logistics',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _InfoRow(
                    icon: Icons.local_shipping,
                    title: 'Truck Transportation',
                    description: 'We have multiple trucks for pickup and delivery services throughout our service area.',
                  ),
                  const SizedBox(height: 16),
                  const _InfoRow(
                    icon: Icons.inventory_2,
                    title: 'Container Delivery',
                    description: 'Same-day container delivery available within our local service area.',
                  ),
                  const SizedBox(height: 16),
                  const _InfoRow(
                    icon: Icons.gps_fixed,
                    title: 'GPS Tracking',
                    description: 'All our vehicles and containers are equipped with GPS tracking for real-time updates.',
                  ),
                  const SizedBox(height: 16),
                  const _InfoRow(
                    icon: Icons.timer,
                    title: 'Emergency Service',
                    description: '24/7 emergency container services available for urgent situations.',
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
                  const Text(
                    'Need Service Outside Our Area?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Contact us for special arrangements or to discuss services beyond our regular service radius.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _contactForSpecialService(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to make phone calls on this device')),
        );
      }
    } catch (e) {
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
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to make phone calls on this device')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error making call: $e')),
      );
    }
  }

  void _showAreaInfo(BuildContext context, String area) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Service available in $area • Call for pricing & scheduling'),
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
            color: AppColors.primary.withValues(alpha: 0.1),
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
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
