import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kl_recycling_app/core/theme.dart';
import 'package:kl_recycling_app/core/animations.dart';
import 'package:kl_recycling_app/features/challenges/logic/challenges_provider.dart';
import 'package:kl_recycling_app/core/widgets/common/custom_card.dart';
import '../models/challenges.dart';

/// Dedicated screen for displaying and managing recycling challenges
class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ChallengesProvider>(
      builder: (context, challengesProvider, child) {
        return AppAnimations.fadeIn(
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                AppAnimations.scaleIn(
                  Text(
                    'Recycling Challenges',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AppAnimations.fadeIn(
                  Text(
                    'Complete challenges to earn bonus points and rewards!',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.onSurfaceSecondary,
                    ),
                  ),
                  delay: const Duration(milliseconds: 200),
                ),
                const SizedBox(height: 24),

                // Filter chips
                AppAnimations.fadeIn(
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Active', ChallengesFilter.active, challengesProvider),
                        const SizedBox(width: 8),
                        _buildFilterChip('Completed', ChallengesFilter.completed, challengesProvider),
                        const SizedBox(width: 8),
                        _buildFilterChip('All', ChallengesFilter.all, challengesProvider),
                      ],
                    ),
                  ),
                  delay: const Duration(milliseconds: 300),
                ),
                const SizedBox(height: 24),

                // Challenges list
                Expanded(
                  child: _buildChallengesList(challengesProvider),
                ),

                const SizedBox(height: 24),

                // Challenge creation button (admin only)
                AppAnimations.fadeIn(
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showCreateChallengeDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Create New Challenge'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  delay: const Duration(milliseconds: 400),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, ChallengesFilter filter, ChallengesProvider provider) {
    final isSelected = provider.currentFilter == filter;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          provider.setFilter(filter);
        }
      },
      backgroundColor: AppColors.surface.withValues(alpha: 0.8),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.onSurfaceSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildChallengesList(ChallengesProvider provider) {
    final challenges = provider.filteredChallengesList;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (challenges.isEmpty) {
      return AppAnimations.fadeIn(
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.flag_outlined,
                size: 80,
                color: AppColors.onSurfaceSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No challenges available',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.onSurfaceSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check back later for new challenges!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        return AppAnimations.slideUp(
          _ChallengeCard(challenge: challenge),
          delay: Duration(milliseconds: 100 * index),
        );
      },
    );
  }

  void _showCreateChallengeDialog(BuildContext context) {
    // For now, just show a placeholder
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Challenge'),
        content: const Text('Challenge creation UI would be implemented here for admin users.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;

  const _ChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final progress = challenge.progressPercentage;
    final isCompleted = challenge.status == ChallengeStatus.completed;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 16),
      color: isCompleted
          ? AppColors.success.withValues(alpha: 0.1)
          : AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Challenge header
            Row(
              children: [
                Icon(
                  _getChallengeIcon(challenge.type),
                  color: isCompleted ? AppColors.success : AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        challenge.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 24,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress bar
            if (!isCompleted) ...[
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: AppColors.surface.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${challenge.currentValue.toStringAsFixed(0)} / ${challenge.targetValue.toStringAsFixed(0)} ${challenge.targetUnit}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceSecondary,
                ),
              ),
            ],

            if (isCompleted) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Completed! +${challenge.rewardPoints} points',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Challenge details
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.onSurfaceSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Ends ${_formatDate(challenge.endDate)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.star,
                  size: 16,
                  color: AppColors.onSurfaceSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${challenge.rewardPoints} points',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getChallengeIcon(ChallengeType type) {
    switch (type) {
      case ChallengeType.daily:
        return Icons.today;
      case ChallengeType.weekly:
        return Icons.calendar_view_week;
      case ChallengeType.monthly:
        return Icons.calendar_month;
      case ChallengeType.special:
        return Icons.star;
      case ChallengeType.streak:
        return Icons.local_fire_department;
      case ChallengeType.materialSpecific:
        return Icons.category;
      case ChallengeType.seasonal:
        return Icons.celebration;
      case ChallengeType.competition:
        return Icons.emoji_events;
      case ChallengeType.team:
        return Icons.group;
      case ChallengeType.adaptive:
        return Icons.adjust;
      case ChallengeType.surprise:
        return Icons.star_outline;
      case ChallengeType.timeLimited:
        return Icons.timer;
      case ChallengeType.community:
        return Icons.location_city;
      case ChallengeType.chain:
        return Icons.share;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'tomorrow';
    } else if (difference.inDays < 0) {
      return 'expired';
    } else if (difference.inDays < 7) {
      return 'in ${difference.inDays} days';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}
