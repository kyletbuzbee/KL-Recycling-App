import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kl_recycling_app/providers/loyalty_provider.dart';
import 'package:kl_recycling_app/models/loyalty.dart';
import 'package:kl_recycling_app/widgets/common/custom_card.dart';

class AchievementGalleryScreen extends StatelessWidget {
  const AchievementGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievement Gallery'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<LoyaltyProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final unlockedAchievements = provider.getUnlockedAchievements();
          final availableAchievements = provider.achievements.where((a) =>
            !a.isUnlocked && !a.isHidden
          ).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (unlockedAchievements.isNotEmpty) ...[
                const Text(
                  'Unlocked Achievements',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...unlockedAchievements.map((achievement) =>
                  _buildAchievementCard(context, achievement, unlocked: true)
                ),
                const SizedBox(height: 32),
              ],
              if (availableAchievements.isNotEmpty) ...[
                const Text(
                  'Lock Achievements',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...availableAchievements.map((achievement) =>
                  _buildAchievementCard(context, achievement, unlocked: false)
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildAchievementCard(BuildContext context, LoyaltyAchievement achievement, {required bool unlocked}) {
    return CustomCard(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: unlocked ? Colors.amber : Colors.grey.shade300,
          child: Icon(
            achievement.icon,
            color: unlocked ? Colors.white : Colors.grey,
          ),
        ),
        title: Text(
          achievement.title,
          style: TextStyle(
            color: unlocked ? Colors.black : Colors.grey,
            fontWeight: unlocked ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          achievement.description,
          style: TextStyle(
            color: unlocked ? Colors.black87 : Colors.grey,
          ),
        ),
        trailing: unlocked ? const Text(
          '✓',
          style: TextStyle(
            color: Colors.green,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ) : Text(
          '+${achievement.pointsReward} pts',
          style: const TextStyle(color: Colors.green),
        ),
      ),
    );
  }
}
