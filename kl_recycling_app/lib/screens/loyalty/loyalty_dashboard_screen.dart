import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kl_recycling_app/providers/loyalty_provider.dart';
import 'package:kl_recycling_app/models/loyalty.dart';
import 'package:kl_recycling_app/widgets/common/custom_card.dart';

class LoyaltyDashboardScreen extends StatelessWidget {
  const LoyaltyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loyalty Program'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<LoyaltyProvider>(
        builder: (context, loyaltyProvider, child) {
          if (loyaltyProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(context, loyaltyProvider),
                const SizedBox(height: 20),
                _buildPointsBalanceCard(context, loyaltyProvider),
                const SizedBox(height: 20),
                _buildTierProgressCard(context, loyaltyProvider),
                const SizedBox(height: 20),
                _buildQuickActions(context, loyaltyProvider),
                const SizedBox(height: 20),
                _buildRecentActivity(context, loyaltyProvider),
                const SizedBox(height: 20),
                _buildReferralStatus(context, loyaltyProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, LoyaltyProvider provider) {
    final profile = provider.currentProfile;
    if (profile == null) return const SizedBox.shrink();

    return CustomCard(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  profile.currentTier.icon,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${profile.currentTier.title} Member',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (profile.discountPercentage > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(profile.discountPercentage * 100).toInt()}% Discount on Services',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsBalanceCard(BuildContext context, LoyaltyProvider provider) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Points Balance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPointsColumn('Available', provider.currentPoints, Colors.green),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade300,
                ),
                _buildPointsColumn('Total Earned', provider.totalPoints, Colors.blue),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/rewards');
                    },
                    icon: const Icon(Icons.card_giftcard),
                    label: const Text('Redeem Rewards'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsColumn(String label, int points, Color color) {
    return Column(
      children: [
        Text(
          points.toString(),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildTierProgressCard(BuildContext context, LoyaltyProvider provider) {
    final progress = provider.tierProgressPercentage;
    final progressText = provider.tierProgressText;

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tier Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              progressText,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: LoyaltyTier.values.map((tier) {
                final isActive = provider.currentTier == tier;
                final isCompleted = provider.totalPoints >= tier.pointsRequired;

                return Column(
                  children: [
                    Icon(
                      tier.icon,
                      color: isActive
                          ? Theme.of(context).primaryColor
                          : isCompleted
                              ? Colors.green
                              : Colors.grey.shade400,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tier.title,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive
                            ? Theme.of(context).primaryColor
                            : isCompleted
                                ? Colors.green
                                : Colors.grey.shade600,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, LoyaltyProvider provider) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    'Achievements',
                    Icons.emoji_events,
                    () => Navigator.pushNamed(context, '/achievements'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    'Refer Friends',
                    Icons.group_add,
                    () => Navigator.pushNamed(context, '/referral'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    'Points History',
                    Icons.history,
                    () => _showPointsHistoryDialog(context, provider),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    'Leaderboards',
                    Icons.leaderboard,
                    () => _showLeaderboardDialog(context, provider),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, LoyaltyProvider provider) {
    final recentPoints = provider.pointsHistory.take(5).toList();

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/points-history'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentPoints.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No recent activity',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...recentPoints.map((point) => _buildActivityItem(point)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(LoyaltyPoints point) {
    final isPositive = point.points > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPositive ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPositive ? Icons.add : Icons.remove,
              color: isPositive ? Colors.green : Colors.red,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  point.description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDate(point.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${point.points}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isPositive ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralStatus(BuildContext context, LoyaltyProvider provider) {
    final completed = provider.completedReferrals;
    final pending = provider.pendingReferrals;

    if (completed == 0 && pending == 0) return const SizedBox.shrink();

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Referral Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildReferralStat('Completed', completed, Colors.green),
                if (pending > 0) ...[
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.grey.shade300,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  _buildReferralStat('Pending', pending, Colors.orange),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  void _showPointsHistoryDialog(BuildContext context, LoyaltyProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Points History'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: provider.pointsHistory.length,
            itemBuilder: (context, index) {
              final point = provider.pointsHistory[index];
              return ListTile(
                leading: Icon(
                  point.points > 0 ? Icons.add_circle : Icons.remove_circle,
                  color: point.points > 0 ? Colors.green : Colors.red,
                ),
                title: Text(point.description),
                subtitle: Text(_formatDate(point.createdAt)),
                trailing: Text(
                  '${point.points > 0 ? '+' : ''}${point.points}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: point.points > 0 ? Colors.green : Colors.red,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLeaderboardDialog(BuildContext context, LoyaltyProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Top Point Earners'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: provider.leaderboard.length,
            itemBuilder: (context, index) {
              final entry = provider.leaderboard[index];
              final isCurrentUser = entry.userId == provider.currentUserId;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: index == 0
                      ? Colors.amber
                      : index == 1
                          ? Colors.grey.shade400
                          : index == 2
                              ? Colors.brown.shade300
                              : Colors.grey.shade200,
                  child: Text('${index + 1}'),
                ),
                title: Text(
                  isCurrentUser ? 'You' : 'User ${entry.userId.substring(0, 8)}',
                  style: TextStyle(
                    fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text('${entry.currentTier.title} Tier'),
                trailing: Text(
                  '${entry.totalPoints} pts',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
