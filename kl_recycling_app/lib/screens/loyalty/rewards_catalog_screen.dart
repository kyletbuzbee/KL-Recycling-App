import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kl_recycling_app/providers/loyalty_provider.dart';

class RewardsCatalogScreen extends StatefulWidget {
  const RewardsCatalogScreen({super.key});

  @override
  State<RewardsCatalogScreen> createState() => _RewardsCatalogScreenState();
}

class _RewardsCatalogScreenState extends State<RewardsCatalogScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rewards Catalog')),
      body: Consumer<LoyaltyProvider>(
        builder: (context, provider, child) {
          final rewards = provider.getAvailableRewards();
          return ListView.builder(
            itemCount: rewards.length,
            itemBuilder: (context, index) {
              final reward = rewards[index];
              return ListTile(
                title: Text(reward.title),
                subtitle: Text('${reward.pointsCost} points'),
                trailing: ElevatedButton(
                  onPressed: provider.canAffordReward(reward.id) ? () => _redeemReward(provider, reward.id) : null,
                  child: const Text('Redeem'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _redeemReward(LoyaltyProvider provider, String rewardId) async {
    final result = await provider.redeemReward(rewardId);
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reward redeemed!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Redemption failed: ${result.error}')),
      );
    }
  }
}
