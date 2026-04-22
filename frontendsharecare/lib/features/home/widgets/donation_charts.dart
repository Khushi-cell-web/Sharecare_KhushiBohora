import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/sharecare_api_service.dart';
import '../../../core/utils/network_error_helper.dart';
import '../../../shared/providers/auth_provider.dart';

/// Category colors for pie chart.
final Map<String, Color> _categoryColors = {
  'food': AppTheme.categoryFood,
  'clothes': AppTheme.categoryClothes,
  'funds': AppTheme.categoryFunds,
  'blood': AppTheme.categoryBlood,
  'organ': AppTheme.categoryOrgan,
  'other': AppTheme.impactGreen,
};

/// Fetches real-time stats and displays donation charts.
class DonationChartsSection extends StatefulWidget {
  const DonationChartsSection({super.key});

  @override
  State<DonationChartsSection> createState() => _DonationChartsSectionState();
}

class _DonationChartsSectionState extends State<DonationChartsSection> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats = await ShareCareApiService().getDonationStats(
        auth.authHeaders,
      );
      if (mounted) {
        setState(() {
          _stats = stats;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = NetworkErrorHelper.toUserMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryTeal),
        ),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              _error!,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    final stats = _stats ?? {};
    final donationsByWeek =
        (stats['donations_by_week'] as List<dynamic>?)?.cast<num>() ??
        [0, 0, 0, 0, 0];
    final categoryDist =
        (stats['category_distribution'] as List<dynamic>?) ?? [];
    final requestStatus = (stats['request_status'] as List<dynamic>?) ?? [];
    final weeklyDonors =
        (stats['weekly_donors'] as List<dynamic>?)?.cast<num>() ??
        [0, 0, 0, 0, 0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MonthlyDonationsLineChart(data: donationsByWeek, height: 160),
        const SizedBox(height: 16),
        DonationCategoriesPieChart(data: categoryDist, size: 120),
        const SizedBox(height: 16),
        RequestFulfillmentBarChart(data: requestStatus, height: 150),
        const SizedBox(height: 16),
        DonorParticipationBarChart(data: weeklyDonors, height: 140),
      ],
    );
  }
}

/// Line chart: Monthly Donations Received (real-time from API).
class MonthlyDonationsLineChart extends StatelessWidget {
  const MonthlyDonationsLineChart({
    super.key,
    this.data = const [],
    this.height = 180,
  });

  final List<num> data;
  final double height;

  List<FlSpot> get _spots {
    final list = data.length >= 5 ? data : List<num>.from(data)
      ..addAll(List.filled(5 - data.length, 0));
    return list
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final spots = _spots;
    final maxY = spots.isEmpty
        ? 10.0
        : (spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.2).clamp(
            5.0,
            double.infinity,
          );
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 8),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) =>
                  FlLine(color: Colors.grey.shade200),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (v, meta) => Text(
                    '${v.toInt()}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (v, meta) => Text(
                    'W${v.toInt() + 1}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: 4,
            minY: 0,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppTheme.primaryTeal,
                barWidth: 2.5,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 250),
        ),
      ),
    );
  }
}

/// Pie chart: Donation Categories Distribution (real-time from API).
class DonationCategoriesPieChart extends StatelessWidget {
  const DonationCategoriesPieChart({
    super.key,
    this.data = const [],
    this.size = 140,
  });

  final List<dynamic> data;
  final double size;

  @override
  Widget build(BuildContext context) {
    final sections = data.isNotEmpty
        ? data.map((s) {
            final label = s['label'] as String? ?? '';
            final value = (s['value'] as num?)?.toDouble() ?? 0;
            final color =
                _categoryColors[label.toLowerCase()] ?? AppTheme.primaryTeal;
            return PieChartSectionData(
              value: value > 0 ? value : 1,
              title: value > 0 ? '${value.toInt()}%' : '',
              color: color,
              radius: 28,
              titleStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            );
          }).toList()
        : [
            PieChartSectionData(
              value: 1,
              title: 'No data',
              color: Colors.grey.shade300,
              radius: 28,
            ),
          ];
    return SizedBox(
      height: size + 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 24,
                sections: sections,
              ),
              duration: const Duration(milliseconds: 250),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.map((s) {
                final label = s['label'] as String? ?? '';
                final value = (s['value'] as num?)?.toInt() ?? 0;
                final color =
                    _categoryColors[label.toLowerCase()] ??
                    AppTheme.primaryTeal;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$label: $value%',
                        style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bar chart: Request Fulfillment Status (real-time from API).
class RequestFulfillmentBarChart extends StatelessWidget {
  const RequestFulfillmentBarChart({
    super.key,
    this.data = const [],
    this.height = 160,
  });

  final List<dynamic> data;
  final double height;

  static final List<Color> _statusColors = [
    AppTheme.ctaOrange,
    Colors.amber,
    AppTheme.primaryGreen,
  ];

  @override
  Widget build(BuildContext context) {
    final items = data.length >= 3
        ? data
        : [
            {'label': 'Open', 'value': 0},
            {'label': 'Partial', 'value': 0},
            {'label': 'Fulfilled', 'value': 0},
          ];
    final maxY =
        items
            .map((e) => (e['value'] as num?)?.toDouble() ?? 0)
            .reduce((a, b) => a > b ? a : b) *
        1.2;
    final maxYClamped = maxY < 1 ? 5.0 : maxY;
    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxYClamped,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i >= 0 && i < items.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        items[i]['label'] as String? ?? '',
                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, meta) => Text(
                  '${v.toInt()}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) =>
                FlLine(color: Colors.grey.shade200),
          ),
          borderData: FlBorderData(show: false),
          barGroups: items
              .asMap()
              .entries
              .map(
                (e) => BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: ((e.value['value'] as num?) ?? 0).toDouble(),
                      color: _statusColors[e.key % _statusColors.length],
                      width: 24,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ],
                  showingTooltipIndicators: [],
                ),
              )
              .toList(),
        ),
        duration: const Duration(milliseconds: 250),
      ),
    );
  }
}

/// Bar chart: Donor Participation (real-time from API).
class DonorParticipationBarChart extends StatelessWidget {
  const DonorParticipationBarChart({
    super.key,
    this.data = const [],
    this.height = 140,
  });

  final List<num> data;
  final double height;

  @override
  Widget build(BuildContext context) {
    final list = data.length >= 5 ? data : List<num>.from(data)
      ..addAll(List.filled(5 - data.length, 0));
    final maxY = list.isEmpty
        ? 10.0
        : (list.reduce((a, b) => a > b ? a : b).toDouble() * 1.2).clamp(
            5.0,
            double.infinity,
          );
    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'W${v.toInt() + 1}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                  ),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (v, meta) => Text(
                  '${v.toInt()}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) =>
                FlLine(color: Colors.grey.shade200),
          ),
          borderData: FlBorderData(show: false),
          barGroups: list
              .asMap()
              .entries
              .map(
                (e) => BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.toDouble(),
                      color: AppTheme.primaryTeal,
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ],
                  showingTooltipIndicators: [],
                ),
              )
              .toList(),
        ),
        duration: const Duration(milliseconds: 250),
      ),
    );
  }
}
