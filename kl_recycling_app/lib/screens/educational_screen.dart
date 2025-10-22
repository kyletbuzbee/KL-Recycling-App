import 'package:flutter/material.dart';
import 'package:kl_recycling_app/config/theme.dart';
import 'package:kl_recycling_app/config/animations.dart';
import 'package:kl_recycling_app/widgets/common/custom_card.dart';

class EducationalScreen extends StatefulWidget {
  const EducationalScreen({super.key});

  @override
  State<EducationalScreen> createState() => _EducationalScreenState();
}

class _EducationalScreenState extends State<EducationalScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Learn & Save'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: const [
            Tab(
              text: 'Did You Know?',
              icon: Icon(Icons.lightbulb),
            ),
            Tab(
              text: 'Articles',
              icon: Icon(Icons.article),
            ),
          ],
        ),
      ),
      backgroundColor: AppColors.background,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFunFactsTab(),
          _buildArticlesTab(),
        ],
      ),
    );
  }

  Widget _buildFunFactsTab() {
    return AppAnimations.fadeIn(
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppAnimations.scaleIn(
              Text(
                'Fascinating Recycling Facts',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 8),
            AppAnimations.fadeIn(
              Text(
                'Discover interesting facts about recycling and environmental impact',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceSecondary,
                ),
              ),
              delay: const Duration(milliseconds: 200),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _buildFunFactCard(
                    'Paper Recycling Impact',
                    'Recycling one ton of paper can save 17 trees and significantly reduce water and energy consumption in the paper-making process.',
                    Icons.description,
                    AppColors.primary,
                  ),
                  _buildFunFactCard(
                    'Plastic Bottle Facts',
                    'About 480 billion plastic bottles are sold globally each year, with only 29% collected for recycling. Most end up in landfills or oceans.',
                    Icons.local_drink,
                    AppColors.secondary,
                  ),
                  _buildFunFactCard(
                    'Aluminum Recycling',
                    'Recycled aluminum saves 95% of the energy required to make new aluminum from raw materials. One recycled can saves enough energy to run a TV for 3 hours.',
                    Icons.build,
                    AppColors.success,
                  ),
                  _buildFunFactCard(
                    'Steel Recycling Power',
                    'Recycling steel conserves enough energy to power Los Angeles for 10 days with the steel recycled in one year.',
                    Icons.precision_manufacturing,
                    AppColors.warning,
                  ),
                  _buildFunFactCard(
                    'Glass Recycling',
                    'Glass can be recycled endlessly without loss of quality or purity. One glass bottle recycled saves enough energy to power a computer for 25 minutes.',
                    Icons.liquor,
                    AppColors.info,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunFactCard(String title, String content, IconData icon, Color color) {
    return AppAnimations.slideUp(
      CustomCard(
        margin: const EdgeInsets.only(bottom: 12),
        variant: CardVariant.filled,
        color: color.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      content,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArticlesTab() {
    return AppAnimations.fadeIn(
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppAnimations.scaleIn(
              Text(
                'Waste Reduction Articles',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 8),
            AppAnimations.fadeIn(
              Text(
                'Learn how to reduce waste and live more sustainably',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceSecondary,
                ),
              ),
              delay: const Duration(milliseconds: 200),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _buildArticleCard(
                    'Reducing Waste in the Workplace',
                    'Learn practical strategies to minimize waste generation in office environments.',
                    Icons.business,
                    AppColors.primary,
                    'Reducing waste in the workplace benefits both corporate responsibility and the bottom line. Key strategies include going digital to reduce paper usage, implementing double-sided printing, and establishing electronic document workflows. Partner with certified recycling companies for proper waste sorting and educate employees about the importance of waste reduction. Consider sustainable procurement practices with eco-friendly packaging and products made from recycled content.',
                  ),
                  _buildArticleCard(
                    'Home Composting Basics',
                    'Start your composting journey at home and turn kitchen scraps into nutrient-rich soil.',
                    Icons.eco,
                    AppColors.success,
                    'Composting is one of the easiest ways to reduce household waste. Nearly 30% of household waste consists of organic material that could be composted instead of going to landfills. Choose from countertop bins for kitchen scraps, outdoor compost piles, or even worm bins for apartments. Compost fruits, vegetables, coffee grounds, eggshells, and yard trimmings—but avoid meat, dairy, oily foods, pet waste, and plastics. Balance green (nitrogen-rich) and brown (carbon-rich) materials, keep the compost moist but not soggy, and turn it regularly for oxygen.',
                  ),
                  _buildArticleCard(
                    'The Environmental Cost of Fast Fashion',
                    'Understanding how our clothing choices impact the planet.',
                    Icons.checkroom,
                    AppColors.warning,
                    'The fashion industry has a massive environmental footprint, producing 92 million tons of textile waste annually. Fast fashion contributes significantly to this problem. One cotton t-shirt requires 700-2,700 gallons of water to produce, enough for one person to drink for over two years. Textile dyeing uses over 8,000 chemicals annually, and the industry contributes 10% of global carbon emissions. Sustainable solutions include buying less and choosing quality, shopping second-hand, seeking certified organic clothing, and donating or repurposing garments instead of discarding them.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleCard(String title, String summary, IconData icon, Color color, String fullContent) {
    return AppAnimations.slideUp(
      AnimatedCard(
        onTap: () => _showArticleModal(title, fullContent, color, icon),
        child: CustomCard(
          margin: const EdgeInsets.only(bottom: 12),
          variant: CardVariant.filled,
          color: color.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        summary,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Read full article',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: color,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showArticleModal(String title, String content, Color color, IconData icon) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                height: 4,
                width: 32,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                        ),
                        borderRadius: AppBorderRadius.mediumBorder,
                      ),
                      child: Icon(
                        icon,
                        size: 24,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: AppColors.onSurfaceSecondary,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    content,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
