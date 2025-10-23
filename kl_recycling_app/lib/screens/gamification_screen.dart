import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kl_recycling_app/config/theme.dart';
import 'package:kl_recycling_app/config/animations.dart';
import 'package:kl_recycling_app/providers/gamification_provider.dart';
import 'package:kl_recycling_app/widgets/common/custom_card.dart';
import 'package:kl_recycling_app/widgets/lottie_animations.dart';
import 'package:kl_recycling_app/screens/notification_settings_screen.dart';
import '../models/gamification.dart' as gamification;

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> with TickerProviderStateMixin {
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
    final gamificationProvider = Provider.of<GamificationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Impact'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
            tooltip: 'Notification Settings',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: const [
            Tab(
              text: 'Dashboard',
              icon: Icon(Icons.dashboard),
            ),
            Tab(
              text: 'History',
              icon: Icon(Icons.history),
            ),
            Tab(
              text: 'Analytics',
              icon: Icon(Icons.analytics),
            ),
          ],
        ),
      ),
      backgroundColor: AppColors.background,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(gamificationProvider),
          _buildHistoryTab(gamificationProvider),
          _buildAnalyticsTab(gamificationProvider),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(GamificationProvider provider) {
    final stats = provider.stats;

    // If no demo data, show call-to-action
    if (stats.totalItems == 0) {
      return AppAnimations.fadeIn(
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppAnimations.scaleIn(
                Icon(
                  Icons.recycling,
                  size: 120,
                  color: AppColors.primary.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              AppAnimations.fadeIn(
                Text(
                  'Start Your Recycling Journey!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                delay: const Duration(milliseconds: 300),
              ),
              const SizedBox(height: 16),
              AppAnimations.fadeIn(
                Text(
                  'Use the camera to start earning points and unlocking badges',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurfaceSecondary,
                  ),
                ),
                delay: const Duration(milliseconds: 500),
              ),
              const SizedBox(height: 32),
              AppAnimations.bounceIn(
                ElevatedButton(
                  onPressed: () async {
                    provider.simulateDemoData();

                    // Show badge unlock animation after a delay
                    await Future.delayed(const Duration(seconds: 1));

                    if (!mounted) return;

                    LottieAnimations.showAchievement(
                      context,
                      title: 'First Recycle!',
                      description: 'Awarded for your first recycling activity',
                      icon: Icons.recycling,
                      color: AppColors.primary,
                    );
                  },
                  child: const Text('View Demo'),
                ),
                delay: const Duration(milliseconds: 700),
              ),
            ],
          ),
        ),
      );
    }

    return AppAnimations.fadeIn(
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Overview
            AppAnimations.scaleIn(
              Text(
                'Your Impact',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppAnimations.slideUp(
                    _StatCard(
                      title: 'Points Earned',
                      value: stats.totalPoints.toString(),
                      icon: Icons.stars,
                      color: AppColors.success,
                    ),
                    delay: const Duration(milliseconds: 200),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppAnimations.slideUp(
                    _StatCard(
                      title: 'Weight Recycled',
                      value: '${stats.totalWeight} lbs',
                      icon: Icons.monitor_weight,
                      color: AppColors.primary,
                    ),
                    delay: const Duration(milliseconds: 300),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppAnimations.slideUp(
                    _StatCard(
                      title: 'Items',
                      value: stats.totalItems.toString(),
                      icon: Icons.inventory,
                      color: AppColors.warning,
                    ),
                    delay: const Duration(milliseconds: 400),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppAnimations.slideUp(
                    _StatCard(
                      title: 'Badges',
                      value: stats.earnedBadges.length.toString(),
                      icon: Icons.emoji_events,
                      color: AppColors.success,
                    ),
                    delay: const Duration(milliseconds: 500),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Badges Section
            AppAnimations.fadeIn(
              Text(
                'Your Badges',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              delay: const Duration(milliseconds: 600),
            ),
            const SizedBox(height: 16),

            // Show all available badges
            Expanded(
              child: AppAnimations.fadeIn(
                GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: gamification.BadgeType.values.length,
                  itemBuilder: (context, index) {
                    final badgeType = gamification.BadgeType.values[index];
                    final isEarned = stats.earnedBadges.any((badge) => badge.type == badgeType);
                    final earnedBadge = stats.earnedBadges.firstWhere(
                      (badge) => badge.type == badgeType,
                      orElse: () => gamification.Badge(id: '', type: badgeType, earnedDate: DateTime.now()),
                    );

                    return AppAnimations.slideUp(
                      _BadgeCard(
                        badgeType: badgeType,
                        isEarned: isEarned,
                        earnedDate: isEarned ? earnedBadge.earnedDate : null,
                      ),
                      delay: Duration(milliseconds: 700 + (index * 100)),
                    );
                  },
                ),
                delay: const Duration(milliseconds: 650),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(GamificationProvider provider) {
    final history = provider.stats.recyclingHistory;

    return AppAnimations.fadeIn(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppAnimations.scaleIn(
              Text(
                'Recycling History',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ),

          if (history.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 80,
                      color: AppColors.onSurfaceSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No recycling history yet',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.onSurfaceSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  return AppAnimations.slideUp(
                    CustomCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: AppColors.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.success.withOpacity(0.2),
                                    AppColors.success.withOpacity(0.1)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: AppBorderRadius.mediumBorder,
                              ),
                              child: Icon(
                                Icons.inventory,
                                size: 24,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item.materialType} - ${item.weight} lbs',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.points} points earned',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatDate(item.recycledDate),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.onSurfaceSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '+${item.points}',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    delay: Duration(milliseconds: 100 * index),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(GamificationProvider provider) {
    final stats = provider.stats;

    return AppAnimations.fadeIn(
      Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              AppAnimations.scaleIn(
                Text(
                  'Detailed Analytics',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.onSurface,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Environmental Impact Section
              CustomCard(
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.eco, color: AppColors.success, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            'Environmental Savings',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Impact metrics
                      if (stats.totalItems > 0) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _AnalyticsMetricCard(
                                title: 'Energy Saved',
                                value: '≈${(stats.totalWeight * 8).toStringAsFixed(0)} kWh',
                                subtitle: 'Equivalent to ~${(stats.totalWeight * 8 / 10).toStringAsFixed(0)} lightbulbs',
                                icon: Icons.flash_on,
                                color: AppColors.warning,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _AnalyticsMetricCard(
                                title: 'CO₂ Reduced',
                                value: '≈${(stats.totalWeight * 2.5).toStringAsFixed(0)} kg',
                                subtitle: 'Equivalent to ~${(stats.totalWeight * 2.5 / 0.2).toStringAsFixed(0)} miles driven',
                                icon: Icons.cloud_off,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _AnalyticsMetricCard(
                          title: 'Trees Saved',
                          value: '≈${(stats.totalItems / 17).toStringAsFixed(1)} trees',
                          subtitle: 'Based on paper and cardboard recycling',
                          icon: Icons.park,
                          color: AppColors.info,
                          isFullWidth: true,
                        ),
                      ] else
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.analytics_outlined,
                                size: 64,
                                color: AppColors.onSurfaceSecondary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Start recycling to see your detailed impact!',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.onSurfaceSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Material Distribution
              if (stats.materialTotals.isNotEmpty) ...[
                CustomCard(
                  color: AppColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Material Distribution',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...stats.materialTotals.entries.map((entry) {
                          final totalWeight = stats.materialTotals.values.reduce((a, b) => a + b);
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
                                    entry.key,
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
                ),

                const SizedBox(height: 24),
              ],

              // Activity Insights
              CustomCard(
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Activity Insights',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (stats.recyclingHistory.isEmpty) ...[
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.insights,
                                size: 48,
                                color: AppColors.onSurfaceSecondary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Your activity patterns will appear here',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.onSurfaceSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: _AnalyticsMetricCard(
                                title: 'Avg Points/Day',
                                value: (stats.totalPoints / _calculateActiveDays(stats.recyclingHistory)).toStringAsFixed(1),
                                subtitle: 'Over ${stats.recyclingHistory.length} activities',
                                icon: Icons.star,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _AnalyticsMetricCard(
                                title: 'Avg Weight/Day',
                                value: '${(stats.totalWeight / _calculateActiveDays(stats.recyclingHistory)).toStringAsFixed(1)} lbs',
                                subtitle: 'Consistent recycling habits',
                                icon: Icons.scale,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _AnalyticsMetricCard(
                          title: 'Most Active Material',
                          value: _getMostActiveMaterial(stats),
                          subtitle: 'Your primary contribution',
                          icon: Icons.leaderboard,
                          color: AppColors.secondary,
                          isFullWidth: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Educational note
              CustomCard(
                color: AppColors.info.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.info,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Environmental estimates are calculated using industry-standard recycling impact factors. Your actions are making a real difference!',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.info,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _calculateActiveDays(List<gamification.RecycledItem> history) {
    if (history.isEmpty) return 1;

    // Get unique dates
    final dates = history.map((item) => item.recycledDate.toIso8601String().split('T')[0]).toSet();
    return dates.length.clamp(1, 999);
  }

  String _getMostActiveMaterial(gamification.UserGamificationStats stats) {
    if (stats.materialTotals.isEmpty) return 'None';

    final entry = stats.materialTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
    return '${entry.key} (${entry.value.toStringAsFixed(1)} lbs)';
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: AppBorderRadius.mediumBorder,
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final gamification.BadgeType badgeType;
  final bool isEarned;
  final DateTime? earnedDate;

  const _BadgeCard({
    required this.badgeType,
    required this.isEarned,
    this.earnedDate,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      child: CustomCard(
        color: isEarned
            ? badgeType.color.withOpacity(0.1)
            : AppColors.surface.withOpacity(0.5),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    badgeType.icon,
                    size: 48,
                    color: isEarned ? badgeType.color : AppColors.onSurfaceSecondary,
                  ),
                  if (!isEarned)
                    Icon(
                      Icons.lock,
                      size: 20,
                      color: AppColors.onSurfaceSecondary.withOpacity(0.7),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                badgeType.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isEarned ? badgeType.color : AppColors.onSurfaceSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  badgeType.description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceSecondary,
                  ),
                ),
              ),
              if (isEarned && earnedDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Earned!',
                    style: TextStyle(
                      color: badgeType.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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

// Helper widgets for analytics
class _AnalyticsMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isFullWidth;

  const _AnalyticsMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppBorderRadius.mediumBorder,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceSecondary,
            ),
          ),
        ],
      ),
    );

    return isFullWidth ? card : ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 120),
      child: card,
    );
  }
}

// Helper animation card for badges
class AnimatedCard extends StatefulWidget {
  final Widget child;
  const AnimatedCard({super.key, required this.child});

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: widget.child,
      ),
    );
  }
}

// Extension to add color property to BadgeType
extension BadgeTypeColor on gamification.BadgeType {
  Color get color {
    switch (this) {
      case gamification.BadgeType.firstRecycle:
        return AppColors.primary;
      case gamification.BadgeType.paperWarrior:
        return AppColors.warning;
      case gamification.BadgeType.metalMaster:
        return AppColors.secondary;
      case gamification.BadgeType.bottleCollector:
        return AppColors.info;
      case gamification.BadgeType.ecoWarrior:
        return AppColors.success;
      case gamification.BadgeType.sustainabilityChampion:
        return AppColors.primary;
    }
  }
}
