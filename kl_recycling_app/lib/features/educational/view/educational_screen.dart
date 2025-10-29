import 'package:flutter/material.dart';
import 'package:kl_recycling_app/core/theme.dart';
import 'package:kl_recycling_app/core/animations.dart';
import 'package:kl_recycling_app/core/widgets/common/custom_card.dart';

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
        title: const Text('Metal Recycling Facts'),
        backgroundColor: AppColors.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
          tabs: const [
            Tab(
              text: 'Metal Facts',
              icon: Icon(Icons.precision_manufacturing),
            ),
            Tab(
              text: 'Industry Insights',
              icon: Icon(Icons.business),
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
                'Amazing Metal Recycling Facts',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 8),
            AppAnimations.fadeIn(
              Text(
                'Discover the incredible environmental and economic benefits of metal recycling',
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
                    'Steel Recycling Superpower',
                    'Recycling steel conserves enough energy to power Los Angeles for 10 days with the steel recycled in just one year. Steel can be recycled infinitely without quality loss.',
                    Icons.precision_manufacturing,
                    AppColors.warning,
                  ),
                  _buildFunFactCard(
                    'Aluminum Energy Giant',
                    'Recycled aluminum saves 95% of the energy required to make new aluminum from raw materials. One recycled can saves enough energy to run a TV for 3 hours.',
                    Icons.build,
                    AppColors.success,
                  ),
                  _buildFunFactCard(
                    'Copper Forever',
                    'Copper is 100% recyclable and maintains its properties forever. 40% of all copper consumed worldwide comes from recycled sources. Mining one ton of new copper requires 700 tons of waste material.',
                    Icons.electrical_services,
                    Colors.brown,
                  ),
                  _buildFunFactCard(
                    'Iron & Steel Industry Backbone',
                    'The steel industry recycles more than 400 million tons of iron ore annually. Recycling one ton of steel saves 1,000 pounds of iron ore, 400 pounds of coke, and 120 pounds of limestone.',
                    Icons.factory,
                    AppColors.primary,
                  ),
                  _buildFunFactCard(
                    'Metal Mining Impact',
                    'Metal mining generates 20 billion tons of waste annually. Recycling just one ton of aluminum eliminates nearly 20 tons of mining waste from the environment.',
                    Icons.terrain,
                    Colors.deepOrange,
                  ),
                  _buildFunFactCard(
                    'Car Crushing Facts',
                    'An average car contains about 2,400 pounds of steel and iron. Recycling an end-of-life vehicle recovers 92% of the vehicle by weight, diverting it from landfills.',
                    Icons.directions_car,
                    Colors.indigo,
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
        color: color.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
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
                'Metal Recycling Insights',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 8),
            AppAnimations.fadeIn(
              Text(
                'Deep dives into the metal recycling industry and sustainable practices',
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
                    'Understanding Scrap Metal Grades',
                    'Learn the different grades of scrap metal and how they affect pricing and recycling value.',
                    Icons.scale,
                    AppColors.primary,
                    'Scrap metal is categorized into different grades that determine its value and recycling potential. Ferrous metals (containing iron) are divided into grades from #1 to #5, with #1 being the highest quality clean steel. Non-ferrous metals like aluminum, copper, and brass have their own grading systems based on purity and condition. Understanding these grades helps maximize the value you get for your scrap. Factors like contamination, size, and coating significantly affect grading. Professional metal recyclers use sophisticated separation techniques to ensure accurate grading and maximize recycling efficiency.',
                  ),
                  _buildArticleCard(
                    'Mobile Car Crushing Technology',
                    'How modern car crushers are revolutionizing the end-of-life vehicle recycling industry.',
                    Icons.directions_car,
                    Colors.indigo,
                    'Mobile car crushing technology has transformed automotive recycling with advanced hydraulic systems capable of crushing vehicles in under 90 seconds. Modern crushers achieve up to 95% volume reduction, making transportation efficient and environmentally friendly. These portable units bring the recycling process directly to the vehicle location, eliminating transportation costs and carbon emissions. Advanced crushers are equipped with fluid collection systems to prevent environmental contamination, and sophisticated cutting systems separate high-value metals from other materials. This technology has dramatically improved the efficiency of end-of-life vehicle processing.',
                  ),
                  _buildArticleCard(
                    'The Oil & Gas Equipment Challenge',
                    'Tackling the complex recycling and disposal of oilfield equipment and facility components.',
                    Icons.oil_barrel,
                    Colors.brown,
                    'Oil and gas equipment recycling presents unique challenges due to hazardous materials, massive scale, and specialized metallurgy. Derrick removals require careful disassembly and material separation, with focus on recovering high-value alloys and properly disposing of contaminated components. Many oilfield structures contain exotic metals and composites that require specialized recycling processes. Environmental considerations are paramount, with regulations requiring the proper handling of drilling mud, hydraulic fluids, and asbestos-containing materials. Reputable recyclers specialize in oilfield equipment, maintaining certifications like ISN certification for handling hazardous waste.',
                  ),
                  _buildArticleCard(
                    'Container Services and Industrial Metal Collection',
                    'Strategic waste management solutions for construction, demolition, and industrial operations.',
                    Icons.inventory_2,
                    AppColors.success,
                    'Roll-off containers provide flexible waste management solutions for metal-intensive industries. Contractors can separate metal wastes at the source, maximizing recycling value and reducing landfill contamination. Different container sizes accommodate various project scales, from small renovation projects to large industrial cleanouts. Advanced container design includes weather-proofing and secure locking systems. GPS tracking enables efficient route planning and inventory management. The roll-off container business model supports the circular economy by keeping valuable metals in productive use rather than allowing them to accumulate in landfills.',
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
          color: color.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
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
                  color: AppColors.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
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
                          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.1)],
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
