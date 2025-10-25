import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kl_recycling_app/config/theme.dart';
import 'package:kl_recycling_app/services/analytics_service.dart';
import 'package:kl_recycling_app/widgets/common/custom_card.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize analytics service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsService>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Analytics'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await context.read<AnalyticsService>().initialize();
              setState(() {});
            },
            tooltip: 'Refresh Analytics',
          ),
        ],
      ),
      body: Consumer<AnalyticsService>(
        builder: (context, analytics, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Business Intelligence Dashboard',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Real-time insights from customer behavior and operations',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),

                // Business Metrics Cards
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Total Estimates',
                        value: analytics.currentMetrics.totalPhotoEstimates.toString(),
                        icon: Icons.photo_camera,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: 'Active Customers',
                        value: analytics.currentMetrics.totalCustomers.toString(),
                        icon: Icons.people,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Avg Value/Estimate',
                        value: '\$${analytics.currentMetrics.averageValuePerEstimate.toStringAsFixed(0)}',
                        icon: Icons.attach_money,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: 'Top Material',
                        value: analytics.currentMetrics.topMaterial ?? 'None',
                        icon: Icons.category,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Material Distribution
                CustomCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.pie_chart, color: AppColors.primary, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Material Distribution',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (analytics.currentMetrics.materialDistribution.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'No data available yet.\nStart by taking some photo estimates!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        Column(
                          children: analytics.currentMetrics.materialDistribution.entries
                            .map((entry) => _MaterialDistributionItem(
                              material: entry.key,
                              count: entry.value,
                              percentage: (entry.value / analytics.currentMetrics.materialDistribution.values.reduce((a, b) => a + b)) * 100,
                            ))
                            .toList(),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Top Customers
                CustomCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: AppColors.primary, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Top Customers',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (analytics.customerProfiles.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'No customer data yet.\nCustomer profiles will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        Column(
                          children: analytics.getTopCustomers(limit: 5)
                            .map((profile) => _TopCustomerItem(
                              profile: profile,
                              lifetimeValue: analytics.getCustomerLifetimeValue(profile.id),
                              tier: analytics.getCustomerTier(profile.id),
                            ))
                            .toList(),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Customer Insights
                CustomCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.insights, color: AppColors.primary, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Business Insights',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInsightsList(analytics),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Export Data Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final data = await analytics.exportAnalyticsData();
                        // For now, just show success - in real implementation,
                        // this would save to file or send to backend
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Analytics data exported successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Export failed: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Export Business Report'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInsightsList(AnalyticsService analytics) {
    final insights = <String>[];

    if (analytics.currentMetrics.totalPhotoEstimates > 0) {
      final avgValue = analytics.currentMetrics.averageValuePerEstimate;
      if (avgValue > 100) {
        insights.add('💰 High-value customers: Average estimate value is \$${avgValue.toStringAsFixed(0)}');
      }

      if (analytics.currentMetrics.materialDistribution.length > 3) {
        insights.add('📊 Diverse business: ${analytics.currentMetrics.materialDistribution.length} different materials processed');
      }

      if (analytics.customerProfiles.isNotEmpty) {
        final avgPhotosPerCustomer = analytics.currentMetrics.totalPhotoEstimates / analytics.customerProfiles.length;
        insights.add('👥 Customer engagement: Average ${avgPhotosPerCustomer.toStringAsFixed(1)} estimates per customer');
      }
    }

    if (insights.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Collect more data to see business insights.\nTake more photo estimates to unlock analytics!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: insights.map((insight) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                insight,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MaterialDistributionItem extends StatelessWidget {
  final String material;
  final int count;
  final double percentage;

  const _MaterialDistributionItem({
    required this.material,
    required this.count,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${material.toUpperCase()} ($count estimates)',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _TopCustomerItem extends StatelessWidget {
  final CustomerProfile profile;
  final double lifetimeValue;
  final CustomerTier tier;

  const _TopCustomerItem({
    required this.profile,
    required this.lifetimeValue,
    required this.tier,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tier.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tier.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tier.color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.star,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${tier.displayName} Customer',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: tier.color,
                  ),
                ),
                Text(
                  '${profile.photoEstimateCount} estimates • \$${lifetimeValue.toStringAsFixed(0)} value',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${profile.materialBreakdown.length} materials',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
