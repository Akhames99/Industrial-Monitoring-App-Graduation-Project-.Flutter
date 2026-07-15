import 'package:app/core/api/api_client.dart';
import 'package:app/core/utils/theme/app_colors.dart';
import 'package:app/features/analytics/models/ai_confidence_stat.dart';
import 'package:app/features/analytics/models/hourly_defects_stat.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  static const int _minDays = ApiClient.minAiConfidenceTimeframeDays; // 1
  static const int _maxDays = ApiClient.maxAiConfidenceTimeframeDays; // 30

  int _timeframeDays = ApiClient.defaultAiConfidenceTimeframeDays; // 7
  late Future<AiConfidenceResponse> _futureStats;
  late Future<HourlyDefectsResponse> _futureHourlyDefects;

  @override
  void initState() {
    super.initState();
    _futureStats = _fetchStats(_timeframeDays);
    _futureHourlyDefects = _fetchHourlyDefects();
  }

  Future<AiConfidenceResponse> _fetchStats(int days) async {
    final response = await ApiClient().getAiConfidenceStats(
      timeframeDays: days,
    );
    return AiConfidenceResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<HourlyDefectsResponse> _fetchHourlyDefects() async {
    final response = await ApiClient().get(Endpoints.hourlyDefects);
    return HourlyDefectsResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<void> _refreshAll() async {
    setState(() {
      _futureStats = _fetchStats(_timeframeDays);
      _futureHourlyDefects = _fetchHourlyDefects();
    });
    await Future.wait([_futureStats, _futureHourlyDefects]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshAll,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      _HourlyDefectsCard(future: _futureHourlyDefects),
                      const SizedBox(height: 16),
                      _AiConfidenceCard(
                        future: _futureStats,
                        timeframeDays: _timeframeDays,
                        minDays: _minDays,
                        maxDays: _maxDays,
                        onChanged: (days) {
                          setState(() => _timeframeDays = days);
                        },
                        onChangeEnd: (_) {
                          setState(() {
                            _futureStats = _fetchStats(_timeframeDays);
                          });
                        },
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

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.bar_chart_rounded, color: AppColors.blue, size: 28),
            const SizedBox(width: 12),
            Text(
              'Analytics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// ================== Hourly Defects Card ==================
class _HourlyDefectsCard extends StatelessWidget {
  final Future<HourlyDefectsResponse> future;

  const _HourlyDefectsCard({required this.future});

  @override
  Widget build(BuildContext context) {
    return _AnalyticsCard(
      child: FutureBuilder<HourlyDefectsResponse>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return _CardErrorState(message: snapshot.error.toString());
          }

          final data = snapshot.data;
          if (data == null || data.trend.isEmpty) {
            return const _CardEmptyState(message: 'No defect data for today.');
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.triangleAlert,
                        color: AppColors.blue,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Hourly Defects',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      data.totalDefects == 1
                          ? '1 defect today'
                          : '${data.totalDefects} defects today',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                data.date,
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
              const SizedBox(height: 16),
              SizedBox(height: 180, child: _HourlyDefectsBarChart(data: data)),
            ],
          );
        },
      ),
    );
  }
}

class _HourlyDefectsBarChart extends StatelessWidget {
  final HourlyDefectsResponse data;

  const _HourlyDefectsBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxCount = data.maxDefectCount;
    final maxY = (maxCount == 0 ? 4 : (maxCount * 1.3)).toDouble();

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceBetween,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.withOpacity(0.12), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: maxY <= 4 ? 1 : null,
              getTitlesWidget: (value, meta) {
                if (value == meta.max) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  space: 4,
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.trend.length) {
                  return const SizedBox.shrink();
                }
                // Only show every 3rd hour label to avoid crowding 24 bars.
                if (index % 3 != 0) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Text(
                    data.trend[index].hourLabel,
                    style: TextStyle(fontSize: 8, color: Colors.grey[500]),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final point = data.trend[group.x.toInt()];
              return BarTooltipItem(
                '${point.hourLabel}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                children: [
                  TextSpan(
                    text:
                        '${point.defectCount} defect${point.defectCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.normal,
                      fontSize: 11,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        barGroups: data.trend.asMap().entries.map((entry) {
          final index = entry.key;
          final point = entry.value;
          final isPeak = maxCount > 0 && point.defectCount == maxCount;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: point.defectCount.toDouble(),
                width: 6,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(3),
                ),
                color: isPeak ? const Color(0xFFE74C3C) : AppColors.blue,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

/// ================== AI Confidence Card ==================
class _AiConfidenceCard extends StatelessWidget {
  final Future<AiConfidenceResponse> future;
  final int timeframeDays;
  final int minDays;
  final int maxDays;
  final ValueChanged<int> onChanged;
  final ValueChanged<double> onChangeEnd;

  const _AiConfidenceCard({
    required this.future,
    required this.timeframeDays,
    required this.minDays,
    required this.maxDays,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.brainCircuit, color: AppColors.blue, size: 18),
              const SizedBox(width: 8),
              const Text(
                'AI Confidence',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _TimeframeSelector(
            value: timeframeDays,
            min: minDays,
            max: maxDays,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
          const SizedBox(height: 12),
          FutureBuilder<AiConfidenceResponse>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return _CardErrorState(message: snapshot.error.toString());
              }

              final data = snapshot.data;
              if (data == null || data.stats.isEmpty) {
                return const _CardEmptyState(
                  message: 'No analytics data for this timeframe.',
                );
              }

              final sortedStats = [...data.stats]
                ..sort((a, b) => b.sampleCount.compareTo(a.sampleCount));

              return Column(
                children: sortedStats
                    .map(
                      (stat) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ConfidenceRow(stat: stat),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TimeframeSelector extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final ValueChanged<double> onChangeEnd;

  const _TimeframeSelector({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Timeframe',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            Text(
              'Last $value day${value == 1 ? '' : 's'}',
              style: TextStyle(
                color: AppColors.blue,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            label: '$value',
            activeColor: AppColors.blue,
            inactiveColor: Colors.grey[200],
            onChanged: (v) => onChanged(v.round()),
            onChangeEnd: onChangeEnd,
          ),
        ),
        Wrap(
          spacing: 8,
          children: [7, 14, 30].map((preset) {
            final selected = value == preset;
            return ChoiceChip(
              label: Text('${preset}d'),
              selected: selected,
              onSelected: (_) {
                onChanged(preset);
                onChangeEnd(preset.toDouble());
              },
              selectedColor: AppColors.blue,
              backgroundColor: Colors.grey[100],
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              side: BorderSide.none,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ConfidenceRow extends StatelessWidget {
  final AiConfidenceStat stat;

  const _ConfidenceRow({required this.stat});

  Color get _confidenceColor {
    if (stat.averageConfidence >= 80) return const Color(0xFF2ECC71);
    if (stat.averageConfidence >= 50) return const Color(0xFFF5A623);
    return const Color(0xFFE74C3C);
  }

  @override
  Widget build(BuildContext context) {
    final pct = (stat.averageConfidence.clamp(0, 100)) / 100;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  stat.category,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${stat.sampleCount} sample${stat.sampleCount == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct.toDouble(),
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(_confidenceColor),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${stat.averageConfidence.toStringAsFixed(1)}% avg confidence',
            style: TextStyle(
              color: _confidenceColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// ================== Shared card + states ==================
class _AnalyticsCard extends StatelessWidget {
  final Widget child;

  const _AnalyticsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardErrorState extends StatelessWidget {
  final String message;

  const _CardErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.grey[400], size: 32),
            const SizedBox(height: 8),
            Text(
              'Couldn\'t load data\n$message',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardEmptyState extends StatelessWidget {
  final String message;

  const _CardEmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ),
    );
  }
}
