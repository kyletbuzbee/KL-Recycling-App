import 'package:flutter/material.dart';
import 'package:kl_recycling_app/config/theme.dart';

/// A comprehensive guide showing where static website images should be placed for maximum impact
class ImagePlacementGuide extends StatelessWidget {
  const ImagePlacementGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Integration Guide'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: AppBorderRadius.largeBorder,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🎯 Static Website → App Image Guide',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Add these images from your website for maximum business impact:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Priority 1 - Hero Image
          _buildImagePlacementCard(
            priority: 1,
            title: 'Facility Hero Image',
            description: 'Large hero image of your facility exterior - most impactful placement',
            currentLocation: 'Home screen hero section (replaces gradient)',
            filePath: 'assets/images/hero_facility.jpg',
            impactLevel: '🔥 Very High',
            screenExample: '🏠 Home Screen',
            imageSize: '1200x600px recommended',
          ),

          // Priority 2 - Team Photo
          _buildImagePlacementCard(
            priority: 2,
            title: 'Team/Owner Photo',
            description: 'Professional team photo showing your people',
            currentLocation: 'Contact screen - above certifications',
            filePath: 'assets/images/team.jpg',
            impactLevel: '🔥 Very High',
            screenExample: '📞 Contact Screen',
            imageSize: '800x400px recommended',
          ),

          // Priority 3 - Service Photos
          _buildImagePlacementCard(
            priority: 3,
            title: 'Scrap Metal Samples',
            description: 'Photos of different scrap metal types you accept',
            currentLocation: 'Services screen - scrap pickup service card',
            filePath: 'assets/images/scrap_metal_samples.jpg',
            impactLevel: '🔥 High',
            screenExample: '⚙️ Services Screen',
            imageSize: '600x300px recommended',
          ),

          _buildImagePlacementCard(
            priority: 4,
            title: 'Service Truck',
            description: 'Your fleet trucks showing branding and equipment',
            currentLocation: 'Services screen - container services',
            filePath: 'assets/images/service_truck.jpg',
            impactLevel: '🔥 High',
            screenExample: '⚙️ Services Screen',
            imageSize: '800x400px recommended',
          ),

          _buildImagePlacementCard(
            priority: 5,
            title: 'Container Sizes',
            description: 'Various container sizes you offer',
            currentLocation: 'Quote forms and services details',
            filePath: 'assets/images/container_sizes.jpg',
            impactLevel: '⚡ Medium-High',
            screenExample: '📝 Quote Forms',
            imageSize: '600x400px recommended',
          ),

          // Priority 6 - Process Images
          _buildImagePlacementCard(
            priority: 6,
            title: 'Facility Exterior',
            description: 'Full facility view for locations page',
            currentLocation: 'Locations screen main image',
            filePath: 'assets/images/facility_exterior.jpg',
            impactLevel: '🔥 High',
            screenExample: '📍 Locations Screen',
            imageSize: '1000x500px recommended',
          ),

          _buildImagePlacementCard(
            priority: 7,
            title: 'Process Images',
            description: 'Weighing, sorting, or customer service photos',
            currentLocation: 'About section, trust indicators',
            filePath: 'assets/images/process_weighing.jpg',
            impactLevel: '⚡ Medium',
            screenExample: 'ℹ️ About Section',
            imageSize: '600x300px recommended',
          ),

          _buildImagePlacementCard(
            priority: 8,
            title: 'Environmental Impact',
            description: 'Sustainability/recycling process photos',
            currentLocation: 'Why Choose Us feature cards',
            filePath: 'assets/images/environmental.jpg',
            impactLevel: '⚡ Medium',
            screenExample: '✨ Trust Features',
            imageSize: '600x300px recommended',
          ),

          const SizedBox(height: 24),

          // Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: AppBorderRadius.largeBorder,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📋 Implementation Summary',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSummaryItem(
                  '✅ Already Implemented:',
                  'Certifications, Logo, Service Visuals, Hero Structure'
                ),
                const SizedBox(height: 12),
                _buildSummaryItem(
                  '🎯 Next Step Priority:',
                  'Add hero_facility.jpg to assets/images/ (highest impact)'
                ),
                const SizedBox(height: 12),
                _buildSummaryItem(
                  '📁 Image Format:',
                  'JPG/PNG, high quality but reasonable file sizes'
                ),
                const SizedBox(height: 12),
                _buildSummaryItem(
                  '🎨 Design Tip:',
                  'Use consistent sizing and professional composition'
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: AppBorderRadius.mediumBorder,
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    '💡 Pro Tip: Start with your best facility exterior photo as the hero image - it creates instant credibility and professionalism.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlacementCard({
    required int priority,
    required String title,
    required String description,
    required String currentLocation,
    required String filePath,
    required String impactLevel,
    required String screenExample,
    required String imageSize,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppBorderRadius.mediumBorder,
        boxShadow: [AppShadows.small],
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: priority <= 2 ? AppColors.success.withOpacity(0.2) :
                        priority <= 4 ? AppColors.warning.withOpacity(0.2) :
                        AppColors.info.withOpacity(0.2),
                  borderRadius: AppBorderRadius.smallBorder,
                ),
                child: Text(
                  '#$priority Priority',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: priority <= 2 ? AppColors.success :
                          priority <= 4 ? AppColors.warning :
                          AppColors.info,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                impactLevel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppBorderRadius.smallBorder,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.place, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Placement: $screenExample',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  currentLocation,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.folder, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        filePath,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.photo_size_select_large, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      imageSize,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
