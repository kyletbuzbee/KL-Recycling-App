import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kl_recycling_app/core/theme.dart';
import 'package:kl_recycling_app/features/gamification/logic/gamification_provider.dart';
import 'package:kl_recycling_app/core/widgets/common/custom_card.dart';
import 'package:kl_recycling_app/features/gamification/models/gamification.dart' as gamification;

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final gamificationProvider = context.watch<GamificationProvider>();
    final stats = gamificationProvider.stats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Reports'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareImpactReport,
            tooltip: 'Share Impact',
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Environmental Impact Section
            _buildImpactSummary(stats),

            const SizedBox(height: 24),

            // Goals & Progress (Activity Insights - Personal)
            _buildGoalsProgress(stats),

            const SizedBox(height: 24),

            // Environmental Equivalencies
            _buildEnvironmentalEquivalents(stats),

            const SizedBox(height: 24),

            // Material Breakdown (moved to bottom as detailed breakdown)
            _buildMaterialBreakdown(stats),

            const SizedBox(height: 24),

            // Charts section placeholder
            CustomCard(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.bar_chart,
                      size: 48,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Detailed Charts Coming Soon',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Interactive charts showing your weekly and monthly trends',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactSummary(gamification.UserGamificationStats stats) {
    // Simple impact calculation - will be enhanced with proper analytics service
    final totalWeight = stats.totalWeight.toDouble() / 16.0; // Approximate metric conversion
    final estimatedEnergy = totalWeight * 8; // Rough estimate
    final estimatedCO2 = totalWeight * 2.5; // Rough estimate

    return CustomCard(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.eco, color: AppColors.success, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Your Environmental Impact',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _ImpactMetricCard(
                    icon: Icons.monitor_weight,
                    value: '${stats.totalWeight} lbs',
                    label: 'Total Weight',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ImpactMetricCard(
                    icon: Icons.stars,
                    value: '≈${estimatedEnergy.toStringAsFixed(0)} kWh',
                    label: 'Energy Saved',
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ImpactMetricCard(
                    icon: Icons.cloud_off,
                    value: '≈${estimatedCO2.toStringAsFixed(0)} kg',
                    label: 'CO₂ Avoided',
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ImpactMetricCard(
                    icon: Icons.emoji_events,
                    value: '${stats.earnedBadges.length}',
                    label: 'Achievements',
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialBreakdown(gamification.UserGamificationStats stats) {
    if (stats.materialTotals.isEmpty) {
      return CustomCard(
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.inventory, size: 48, color: AppColors.primary),
              const SizedBox(height: 16),
              Text('Material Breakdown',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Start recycling to see your material distribution!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    // Calculate totals
    final totalWeight = stats.materialTotals.values.reduce((a, b) => a + b);
    final sortedMaterials = stats.materialTotals.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return CustomCard(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Material Breakdown',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedMaterials.take(5).map((entry) {
              final percentage = (entry.value / totalWeight * 100).toStringAsFixed(1);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getMaterialColor(entry.key),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getMaterialDisplayName(entry.key),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${entry.value.toStringAsFixed(1)} lbs ($percentage%)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsProgress(gamification.UserGamificationStats stats) {
    // Sample goals - in real app this would be customizable
    const monthlyWeightGoal = 50.0; // lbs per month
    const monthlyItemsGoal = 10; // items per month

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    // Calculate current month progress
    final currentMonthItems = stats.recyclingHistory.where(
      (item) => item.recycledDate.isAfter(monthStart),
    ).toList();

    final currentMonthWeight = currentMonthItems.fold(0.0, (sum, item) => sum + item.weight);
    final currentMonthItemCount = currentMonthItems.length;

    return CustomCard(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Goals',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),

            // Weight Goal
            _buildGoalProgress(
              label: 'Weight Goal',
              current: currentMonthWeight,
              target: monthlyWeightGoal,
              unit: 'lbs',
              color: AppColors.primary,
            ),

            const SizedBox(height: 16),

            // Items Goal
            _buildGoalProgress(
              label: 'Items Goal',
              current: currentMonthItemCount.toDouble(),
              target: monthlyItemsGoal.toDouble(),
              unit: 'items',
              color: AppColors.success,
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: AppBorderRadius.mediumBorder,
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Days left in ${now.month == 1 ? 'January' :
                                  now.month == 2 ? 'February' :
                                  now.month == 3 ? 'March' :
                                  now.month == 4 ? 'April' :
                                  now.month == 5 ? 'May' :
                                  now.month == 6 ? 'June' :
                                  now.month == 7 ? 'July' :
                                  now.month == 8 ? 'August' :
                                  now.month == 9 ? 'September' :
                                  now.month == 10 ? 'October' :
                                  now.month == 11 ? 'November' : 'December'
                                  }: ${DateTime(now.year, now.month + 1, 1).difference(now).inDays}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentalEquivalents(gamification.UserGamificationStats stats) {
    // Simple equivalencies based on total weight
    final totalWeight = stats.totalWeight.toDouble();
    final estimatedCO2 = totalWeight * 2.5; // Rough estimate: 2.5 kg CO2 per lb
    final estimatedEnergy = totalWeight * 8; // Rough estimate: 8 kWh per lb

    final equivalencies = [
      {
        'icon': '🚗',
        'value': (estimatedCO2 / 0.404).toStringAsFixed(0), // kg CO2 per mile
        'label': 'car miles not driven',
      },
      {
        'icon': '⚡',
        'value': (estimatedEnergy / 13).toStringAsFixed(0), // Average home daily usage
        'label': 'days of electricity use',
      },
      {
        'icon': '🚿',
        'value': (totalWeight * 2).toStringAsFixed(0), // Gallons saved * conversion
        'label': '5-minute showers',
      },
    ];

    return CustomCard(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.compare, color: AppColors.secondary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Your Recycling Equals',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...equivalencies.map((equiv) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: AppBorderRadius.mediumBorder,
                    ),
                    child: Text(
                      equiv['icon']!,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          equiv['value']!,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                        ),
                        Text(
                          equiv['label']!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalProgress({
    required String label,
    required double current,
    required double target,
    required String unit,
    required Color color,
  }) {
    final progress = (current / target).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${current.toStringAsFixed(1)} / ${target.toStringAsFixed(1)} $unit',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        const SizedBox(height: 4),
        Text(
          '${(progress * 100).toStringAsFixed(0)}% complete',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.onSurfaceSecondary,
          ),
        ),
      ],
    );
  }

  Color _getMaterialColor(String material) {
    const colors = {
      'aluminum': AppColors.secondary,
      'steel': AppColors.onSurfaceSecondary,
      'paper': AppColors.warning,
      'plastic': AppColors.primary,
      'cardboard': AppColors.warning,
      'glass': AppColors.info,
      'copper': AppColors.secondary,
      'electronics': AppColors.primary,
    };
    return colors[material.toLowerCase()] ?? AppColors.onSurfaceSecondary;
  }

  String _getMaterialDisplayName(String material) {
    return material[0].toUpperCase() + material.substring(1);
  }

  void _shareImpactReport() {
    final gamificationProvider = context.read<GamificationProvider>();
    final stats = gamificationProvider.stats;

    final totalWeight = stats.totalWeight.toDouble();
    final estimatedEnergy = totalWeight * 8; // Rough estimate
    final estimatedCO2 = totalWeight * 2.5; // Rough estimate

    final shareText = '''
🌍 My Recycling Impact with K&L Recycling!

📊 Total Weight Recycled: ${stats.totalWeight} lbs
🏆 Achievements Earned: ${stats.earnedBadges.length}
⚡ Energy Saved: ≈${estimatedEnergy.toStringAsFixed(0)} kWh
🌱 CO₂ Avoided: ≈${estimatedCO2.toStringAsFixed(0)} kg

🚗 That's like not driving ${(estimatedCO2 / 0.404).toStringAsFixed(0)} miles!
💡 Enough electricity for ${estimatedEnergy ~/ 13} days of home use!

Join me in making a difference! Download the K&L Recycling app today.
#KLRecycling #GoGreen #Sustainability
    ''';

    Share.share(shareText.trim());
  }
}

class _ImpactMetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _ImpactMetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppBorderRadius.mediumBorder,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface, // ✅ Dark text for proper contrast
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.onSurfaceSecondary, // ✅ Dark text for proper contrast
            ),
          ),
        ],
      ),
    );
  }
}
