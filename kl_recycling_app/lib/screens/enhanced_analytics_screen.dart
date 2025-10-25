import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kl_recycling_app/config/theme.dart';
import 'package:kl_recycling_app/services/enhanced_analytics_service.dart';
import 'package:kl_recycling_app/models/enhanced_analytics.dart';
import 'package:kl_recycling_app/widgets/common/custom_card.dart';

class EnhancedAnalyticsScreen extends StatefulWidget {
  const EnhancedAnalyticsScreen({super.key});

  @override
  State<EnhancedAnalyticsScreen> createState() => _EnhancedAnalyticsScreenState();
}

class _EnhancedAnalyticsScreenState extends State<EnhancedAnalyticsScreen> {
  TimeRange _selectedTimeRange = TimeRange.last30Days;
  String _selectedTab = 'overview';

  @override
  void initState() {
    super.initState();
    _initializeAnalytics();
  }

  Future<void> _initializeAnalytics() async {
    final analyticsService = context.read<EnhancedAnalyticsService>();
    await analyticsService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final analyticsService = context.watch<EnhancedAnalyticsService>();
    final kpis = analyticsService.getKPIs();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Intelligence'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<TimeRange>(
            icon: const Icon(Icons.date_range),
            onSelected: (TimeRange range) async {
              setState(() => _selectedTimeRange = range);
              await _refreshAnalytics(analyticsService);
            },
            itemBuilder: (BuildContext context) => TimeRange.values.map((range) {
              return PopupMenuItem<TimeRange>(
                value: range,
                child: Text(range.displayName),
              );
            }).toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Time range selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Current Period: ${_selectedTimeRange.displayName}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.onSurfaceSecondary,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _refreshAnalytics(analyticsService),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),

          // KPI Cards
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _KPICard(
                    title: 'Revenue',
                    value: kpis['totalRevenue'] != null
                        ? '\$${kpis['totalRevenue']!.toStringAsFixed(0)}'
                        : 'N/A',
                    icon: Icons.attach_money,
                    trend: '+12.5%',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _KPICard(
                    title: 'Utilization',
                    value: kpis['facilityUtilization'] != null
                        ? '${(kpis['facilityUtilization']! * 100).toStringAsFixed(1)}%'
                        : 'N/A',
                    icon: Icons.factory,
                    trend: kpis['facilityUtilization'] != null && kpis['facilityUtilization']! > 0.8
                        ? 'Peak'
                        : 'Stable',
                    color: kpis['facilityUtilization'] != null && kpis['facilityUtilization']! > 0.9
                        ? Colors.orange
                        : Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _KPICard(
                    title: 'Customers',
                    value: kpis['totalAppointments'] != null
                        ? kpis['totalAppointments']!.toStringAsFixed(0)
                        : 'N/A',
                    icon: Icons.people,
                    trend: '+8.2%',
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _KPICard(
                    title: 'Satisfaction',
                    value: kpis['customerSatisfaction'] != null
                        ? '${(kpis['customerSatisfaction']! * 100).toStringAsFixed(0)}%'
                        : 'N/A',
                    icon: Icons.thumb_up,
                    trend: 'Excellent',
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
          ),

          // Tab selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _TabButton(
                    label: 'Overview',
                    isSelected: _selectedTab == 'overview',
                    onTap: () => setState(() => _selectedTab = 'overview'),
                  ),
                  const SizedBox(width: 8),
                  _TabButton(
                    label: 'Revenue',
                    isSelected: _selectedTab == 'revenue',
                    onTap: () => setState(() => _selectedTab = 'revenue'),
                  ),
                  const SizedBox(width: 8),
                  _TabButton(
                    label: 'Operations',
                    isSelected: _selectedTab == 'operations',
                    onTap: () => setState(() => _selectedTab = 'operations'),
                  ),
                  const SizedBox(width: 8),
                  _TabButton(
                    label: 'Customers',
                    isSelected: _selectedTab == 'customers',
                    onTap: () => setState(() => _selectedTab = 'customers'),
                  ),
                  const SizedBox(width: 8),
                  _TabButton(
                    label: 'Materials',
                    isSelected: _selectedTab == 'materials',
                    onTap: () => setState(() => _selectedTab = 'materials'),
                  ),
                  const SizedBox(width: 8),
                  _TabButton(
                    label: 'Recommendations',
                    isSelected: _selectedTab == 'recommendations',
                    onTap: () => setState(() => _selectedTab = 'recommendations'),
                    badge: analyticsService.recommendations.isNotEmpty ? analyticsService.recommendations.length : null,
                    badgeColor: Colors.red,
                  ),
                ],
              ),
            ),
          ),

          // Content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildTabContent(analyticsService, _selectedTab),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(EnhancedAnalyticsService service, String tab) {
    switch (tab) {
      case 'overview':
        return _buildOverviewTab(service);
      case 'revenue':
        return _buildRevenueTab(service);
      case 'operations':
        return _buildOperationsTab(service);
      case 'customers':
        return _buildCustomersTab(service);
      case 'materials':
        return _buildMaterialsTab(service);
      case 'recommendations':
        return _buildRecommendationsTab(service);
      default:
        return _buildOverviewTab(service);
    }
  }

  Widget _buildOverviewTab(EnhancedAnalyticsService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Revenue Trend Chart
        CustomCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up, color: AppColors.primary, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Revenue Trend',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: RevenueLineChart(data: service.revenueData),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Facility Utilization Chart
        CustomCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.factory, color: AppColors.primary, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Facility Utilization',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: UtilizationBarChart(data: service.facilityMetrics),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Quick Stats
        Row(
          children: [
            Expanded(
              child: CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profit Margin',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      service.getKPIs()['profitMargin'] != null
                          ? '${service.getKPIs()['profitMargin']!.toStringAsFixed(1)}%'
                          : 'N/A',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Retention Rate',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      service.getKPIs()['customerRetention'] != null
                          ? '${service.getKPIs()['customerRetention']!.toStringAsFixed(1)}%'
                          : 'N/A',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Recent Recommendations
        if (service.recommendations.isNotEmpty) ...[
          const Text(
            'Recent Recommendations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...service.recommendations.take(2).map((rec) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                Icons.lightbulb,
                color: rec.priority.color,
              ),
              title: Text(rec.title),
              subtitle: Text('${rec.category} • ${rec.priority.displayName}'),
              trailing: Text('${rec.expectedImpact}%'),
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildRevenueTab(EnhancedAnalyticsService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.attach_money, color: AppColors.primary, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Revenue Analysis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 250,
                child: RevenueLineChart(data: service.revenueData, showArea: true),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        CustomCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Revenue by Material Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: MaterialRevenueChart(revenueData: service.revenueData),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOperationsTab(EnhancedAnalyticsService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.factory, color: AppColors.primary, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Facility Performance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: UtilizationBarChart(data: service.facilityMetrics, showDetails: true),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Avg Appointment Time',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      service.facilityMetrics.isNotEmpty
                          ? '${service.facilityMetrics.last.averageAppointmentTime.toStringAsFixed(0)} min'
                          : 'N/A',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Peak Hour',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      service.facilityMetrics.isNotEmpty
                          ? '${service.facilityMetrics.last.peakHour}:00'
                          : 'N/A',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        CustomCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Equipment Utilization',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...service.facilityMetrics.last.equipmentUtilization.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(entry.key.replaceAll('_', ' ').toUpperCase()),
                          ),
                          Text('${(entry.value * 100).toStringAsFixed(1)}%'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: entry.value / 100,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          entry.value > 80 ? Colors.orange : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomersTab(EnhancedAnalyticsService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.people, color: AppColors.primary, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Customer Analytics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (service.customerAnalytics.isNotEmpty)
                Column(
                  children: [
                    _buildCustomerMetric(
                      'Total Customers',
                      service.customerAnalytics.last.totalCustomers.toString(),
                    ),
                    const Divider(),
                    _buildCustomerMetric(
                      'New Customers',
                      service.customerAnalytics.last.newCustomers.toString(),
                    ),
                    const Divider(),
                    _buildCustomerMetric(
                      'Retention Rate',
                      '${service.customerAnalytics.last.retentionRate.toStringAsFixed(1)}%',
                      color: Colors.green,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Customer Distribution',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: CustomerTierChart(
                        tierDistribution: service.customerAnalytics.last.customerTierDistribution,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialsTab(EnhancedAnalyticsService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.build, color: AppColors.primary, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Material Analytics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (service.materialAnalytics.isNotEmpty)
                Column(
                  children: service.materialAnalytics.map((material) =>
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            material.materialType.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMaterialMetric(
                                  'Total Weight',
                                  '${material.totalWeight.toStringAsFixed(0)} lbs',
                                ),
                              ),
                              Expanded(
                                child: _buildMaterialMetric(
                                  'Avg Price/lb',
                                  '\$${material.averagePricePerLb.toStringAsFixed(2)}',
                                ),
                              ),
                              Expanded(
                                child: _buildMaterialMetric(
                                  'Revenue',
                                  '\$${material.totalRevenue.toStringAsFixed(0)}',
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: material.demandIndex / 100,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              material.demandIndex > 70 ? Colors.green : Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Demand Index: ${material.demandIndex.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsTab(EnhancedAnalyticsService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (service.recommendations.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.check_circle, size: 48, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'All systems operating optimally!',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No action items required at this time.',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ...service.recommendations.map((rec) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: rec.priority.color,
                child: Text(
                  rec.expectedImpact.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              title: Text(rec.title),
              subtitle: Text(
                '${rec.category} • Priority: ${rec.priority.displayName}\n${rec.description}',
                style: const TextStyle(fontSize: 13),
              ),
              isThreeLine: true,
              trailing: ElevatedButton(
                onPressed: rec.isImplemented ? null : () => _implementRecommendation(rec),
                style: ElevatedButton.styleFrom(
                  backgroundColor: rec.isImplemented ? Colors.grey : AppColors.primary,
                ),
                child: Text(rec.isImplemented ? 'Implemented' : 'Implement'),
              ),
            ),
          )),
      ],
    );
  }

  Widget _buildCustomerMetric(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialMetric(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.onSurfaceSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _refreshAnalytics(EnhancedAnalyticsService service) async {
    await service.generateRevenueAnalytics(_selectedTimeRange);
    await service.generateFacilityMetrics(_selectedTimeRange);
    await service.generateCustomerAnalytics(_selectedTimeRange);
    await service.generateMaterialAnalytics(_selectedTimeRange);
  }

  void _implementRecommendation(BusinessRecommendation rec) {
    final service = context.read<EnhancedAnalyticsService>();
    // In a real implementation, this would open a dialog for implementation details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recommendation "${rec.title}" marked as implemented'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Undo implementation
          },
        ),
      ),
    );
  }
}

// Custom KPI Card
class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String trend;
  final Color color;

  const _KPICard({
    required this.title,
    required this.value,
    required this.icon,
    required this.trend,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.onSurfaceSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              trend,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Tab Button
class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badge;
  final Color? badgeColor;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor ?? AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge!.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Revenue Line Chart
class RevenueLineChart extends StatelessWidget {
  final List<RevenueData> data;
  final bool showArea;

  const RevenueLineChart({super.key, required this.data, this.showArea = false});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.totalRevenue);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            belowBarData: showArea ? BarAreaData(
              show: true,
              color: AppColors.primary.withOpacity(0.1),
            ) : BarAreaData(show: false),
            dotData: FlDotData(show: false),
          ),
        ],
        minY: data.map((d) => d.totalRevenue).reduce((a, b) => a < b ? a : b) * 0.9,
      ),
    );
  }
}

// Utilization Bar Chart
class UtilizationBarChart extends StatelessWidget {
  final List<FacilityMetrics> data;
  final bool showDetails;

  const UtilizationBarChart({super.key, required this.data, this.showDetails = false});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No facility data available'));
    }

    final barGroups = data.take(7).map((metric) {
      return BarChartGroupData(
        x: data.indexOf(metric),
        barRods: [
          BarChartRodData(
            toY: metric.utilizationPercentage,
            color: metric.utilizationPercentage > 90 ? Colors.orange : Colors.green,
            width: 12,
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        maxY: 100,
      ),
    );
  }
}

// Material Revenue Pie Chart
class MaterialRevenueChart extends StatelessWidget {
  final List<RevenueData> revenueData;

  const MaterialRevenueChart({super.key, required this.revenueData});

  @override
  Widget build(BuildContext context) {
    if (revenueData.isEmpty) {
      return const Center(child: Text('No revenue data available'));
    }

    // Aggregate material revenue across all periods
    final materialRevenue = <String, double>{};
    for (final data in revenueData) {
      data.materialRevenue.forEach((material, revenue) {
        materialRevenue[material] = (materialRevenue[material] ?? 0) + revenue;
      });
    }

    final sections = materialRevenue.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value,
        title: '${entry.key[0].toUpperCase()}\n\$${entry.value.toStringAsFixed(0)}',
        color: _getMaterialColor(entry.key),
        radius: 50,
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        sectionsSpace: 2,
        centerSpaceRadius: 20,
      ),
    );
  }

  Color _getMaterialColor(String material) {
    switch (material.toLowerCase()) {
      case 'steel': return Colors.grey;
      case 'aluminum': return Colors.blue;
      case 'copper': return Colors.orange;
      case 'brass': return Colors.yellow;
      default: return Colors.green;
    }
  }
}

// Customer Tier Distribution Chart
class CustomerTierChart extends StatelessWidget {
  final Map<String, int> tierDistribution;

  const CustomerTierChart({super.key, required this.tierDistribution});

  @override
  Widget build(BuildContext context) {
    final sections = tierDistribution.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${entry.key}\n${entry.value}',
        color: _getTierColor(entry.key),
        radius: 60,
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        sectionsSpace: 2,
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze': return const Color(0xFFCD7F32);
      case 'silver': return const Color(0xFFC0C0C0);
      case 'gold': return const Color(0xFFFFD700);
      case 'platinum': return const Color(0xFFE5E4E2);
      default: return Colors.blue;
    }
  }
}
