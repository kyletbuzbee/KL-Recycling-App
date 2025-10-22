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
    _tabController = TabController(length: 2, vsync: this);
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
          ],
        ),
      ),
      backgroundColor: AppColors.background,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(gamificationProvider),
          _buildHistoryTab(gamificationProvider),
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
                    await provider.simulateDemoData();

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
