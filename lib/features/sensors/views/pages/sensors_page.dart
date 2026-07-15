import 'package:app/core/api/api_client.dart';
import 'package:app/core/utils/theme/app_colors.dart';
import 'package:app/features/login/cubit/login_cubit.dart';
import 'package:app/features/sensors/cubit/telemetry_cubit.dart';
import 'package:app/features/sensors/cubit/telemetry_state.dart';
import 'package:app/features/sensors/repositories/sensors_repository.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SensorsPage extends StatefulWidget {
  const SensorsPage({Key? key}) : super(key: key);

  @override
  State<SensorsPage> createState() => _SensorsPageState();
}

class _SensorsPageState extends State<SensorsPage> {
  final SensorsRepository _repo = SensorsRepository();
  late final TelemetryCubit _telemetryCubit;
  List<SensorModel> sensors = [];
  bool isLoading = true;
  final Set<String> _expandedSensorIds = {};

  @override
  void initState() {
    super.initState();
    _telemetryCubit = TelemetryCubit();
    _loadSensors();
    _telemetryCubit.connect(ApiClient().sessionId ?? '');
  }

  @override
  void dispose() {
    _telemetryCubit.close();
    super.dispose();
  }

  Future<void> _loadSensors() async {
    try {
      final result = await _repo.getSensors();
      setState(() {
        sensors = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading sensors: $e')));
      }
    }
  }

  void _showAddSensorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddSensorDialog(
        onSensorAdded: (sensor) {
          setState(() => sensors.add(sensor));
        },
      ),
    );
  }

  Future<void> _toggleSensorStatus(SensorModel sensor) async {
    try {
      await _repo.updateSensorStatus(
        sensorId: sensor.sensorId,
        isActive: !sensor.isActive,
      );
      setState(() {
        final index = sensors.indexWhere((s) => s.sensorId == sensor.sensorId);
        if (index != -1) {
          sensors[index] = sensor.copyWith(isActive: !sensor.isActive);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update sensor: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginState = context.watch<LoginCubit>().state;
    final isAdmin =
        loginState is LoginSuccess &&
        loginState.loginResponse.user.role.toLowerCase() == 'admin';

    return BlocProvider.value(
      value: _telemetryCubit,
      child: BlocListener<TelemetryCubit, TelemetryState>(
        listenWhen: (prev, curr) => prev.sessionExpired != curr.sessionExpired,
        listener: (context, state) {
          if (state.sessionExpired) {
            // TODO: trigger your app's real logout flow / redirect to login,
            // e.g. context.read<LoginCubit>().logout(); Navigator.pushNamedAndRemoveUntil('/login', (r) => false);
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.primary,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isAdmin),
                  const SizedBox(height: 24),
                  _buildConnectionStatus(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : sensors.isEmpty
                        ? _buildEmptyState(isAdmin)
                        : RefreshIndicator(
                            onRefresh: _loadSensors,
                            child: BlocBuilder<TelemetryCubit, TelemetryState>(
                              builder: (context, telemetryState) {
                                return ListView.builder(
                                  itemCount: sensors.length,
                                  itemBuilder: (context, index) {
                                    final sensor = sensors[index];
                                    return _buildSensorCard(
                                      sensor,
                                      telemetryState,
                                      isAdmin,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isAdmin) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(LucideIcons.activity, color: AppColors.blue, size: 28),
            const SizedBox(width: 12),
            Text(
              'Sensors',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.blue,
              ),
            ),
          ],
        ),
        if (isAdmin)
          GestureDetector(
            onTap: _showAddSensorDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.add, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'Add Sensor',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    return BlocBuilder<TelemetryCubit, TelemetryState>(
      builder: (context, telemetryState) {
        final isConnected = telemetryState.isConnected;
        return Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isConnected ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isConnected ? 'Live — Connected' : 'Disconnected',
              style: TextStyle(
                fontSize: 12,
                color: isConnected ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!isConnected) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () =>
                    _telemetryCubit.reconnect(ApiClient().sessionId ?? ''),
                child: Text(
                  'Reconnect',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(bool isAdmin) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.activity, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No sensors found',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showAddSensorDialog,
              child: Text(
                'Add your first sensor',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue[600],
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSensorCard(
    SensorModel sensor,
    TelemetryState telemetryState,
    bool isAdmin,
  ) {
    final double? liveValue = telemetryState.values[sensor.sensorId];
    final bool hasLiveData = liveValue != null;
    final bool isOverThreshold = hasLiveData && liveValue > sensor.maxThreshold;
    final bool isUnderThreshold =
        hasLiveData && liveValue < sensor.minThreshold;
    final bool isAlert = isOverThreshold || isUnderThreshold;
    final bool isExpanded = _expandedSensorIds.contains(sensor.sensorId);

    // Calculate progress percentage
    final double progress = hasLiveData
        ? ((liveValue - sensor.minThreshold) /
                  (sensor.maxThreshold - sensor.minThreshold))
              .clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedSensorIds.remove(sensor.sensorId);
          } else {
            _expandedSensorIds.add(sensor.sensorId);
          }
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isAlert
              ? Border.all(color: Colors.red[300]!, width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getSensorIcon(sensor.sensorType),
                      color: isAlert ? Colors.red : AppColors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      sensor.sensorId,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        sensor.sensorType,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (isAdmin)
                      Switch(
                        value: sensor.isActive,
                        activeColor: AppColors.blue,
                        onChanged: (_) => _toggleSensorStatus(sensor),
                      ),
                    const SizedBox(width: 4),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.grey[400],
                      size: 22,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (sensor.sensorType.toLowerCase() == 'vibration' &&
                          telemetryState.latestVibration.containsKey(
                            sensor.sensorId,
                          )) ...[
                        Builder(
                          builder: (context) {
                            final vib = telemetryState
                                .latestVibration[sensor.sensorId]!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${liveValue?.toStringAsFixed(1) ?? '--'} ${sensor.unit} (Mag)',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: isAlert
                                        ? Colors.red
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    _buildAxisBadge(
                                      'X',
                                      vib.x,
                                      Colors.red,
                                      Colors.red[800]!,
                                    ),
                                    const SizedBox(width: 6),
                                    _buildAxisBadge(
                                      'Y',
                                      vib.y,
                                      Colors.green,
                                      Colors.green[800]!,
                                    ),
                                    const SizedBox(width: 6),
                                    _buildAxisBadge(
                                      'Z',
                                      vib.z,
                                      Colors.blue,
                                      Colors.blue[800]!,
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ] else ...[
                        Text(
                          hasLiveData
                              ? '${liveValue.toStringAsFixed(1)} ${sensor.unit}'
                              : '-- ${sensor.unit}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: isAlert ? Colors.red : Colors.black87,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Range: ${sensor.minThreshold} – ${sensor.maxThreshold} ${sensor.unit}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: sensor.isActive
                        ? Colors.green[50]
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    sensor.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: sensor.isActive
                          ? Colors.green[700]
                          : Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isAlert ? Colors.red : Colors.blue[400]!,
                ),
              ),
            ),
            if (isAlert) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red[400],
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isOverThreshold
                        ? 'Above maximum threshold!'
                        : 'Below minimum threshold!',
                    style: TextStyle(fontSize: 11, color: Colors.red[400]),
                  ),
                ],
              ),
            ],
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Column(
                      children: [
                        const Divider(height: 24, thickness: 0.5),
                        _buildSensorChart(sensor, telemetryState),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAxisBadge(
    String axis,
    double value,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: bgColor.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        '$axis: ${value.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildSensorChart(SensorModel sensor, TelemetryState telemetryState) {
    final isVibration = sensor.sensorType.toLowerCase() == 'vibration';

    if (isVibration) {
      final history = telemetryState.vibrationHistory[sensor.sensorId] ?? [];
      if (history.isEmpty) {
        return const SizedBox(
          height: 120,
          child: Center(
            child: Text(
              'Waiting for vibration telemetry data...',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        );
      }

      final spotsX = history
          .asMap()
          .entries
          .map((e) => FlSpot(e.key.toDouble(), e.value.x))
          .toList();
      final spotsY = history
          .asMap()
          .entries
          .map((e) => FlSpot(e.key.toDouble(), e.value.y))
          .toList();
      final spotsZ = history
          .asMap()
          .entries
          .map((e) => FlSpot(e.key.toDouble(), e.value.z))
          .toList();

      // Find min/max values to fit the chart nicely
      double minY = sensor.minThreshold;
      double maxY = sensor.maxThreshold;
      for (final r in history) {
        if (r.x < minY) minY = r.x;
        if (r.y < minY) minY = r.y;
        if (r.z < minY) minY = r.z;
        if (r.x > maxY) maxY = r.x;
        if (r.y > maxY) maxY = r.y;
        if (r.z > maxY) maxY = r.z;
      }
      // Add a bit of padding to the bounds
      final yRange = (maxY - minY).abs();
      final rangePadding = yRange > 0 ? yRange * 0.15 : 1.0;
      minY = minY - rangePadding;
      maxY = maxY + rangePadding;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('X Axis', Colors.red),
              const SizedBox(width: 16),
              _buildLegendItem('Y Axis', Colors.green),
              const SizedBox(width: 16),
              _buildLegendItem('Z Axis', Colors.blue),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.12),
                    strokeWidth: 1,
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: sensor.maxThreshold,
                      color: Colors.red.withOpacity(0.35),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.red.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                        labelResolver: (line) => 'Max Threshold',
                      ),
                    ),
                    HorizontalLine(
                      y: sensor.minThreshold,
                      color: Colors.blue.withOpacity(0.35),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.bottomRight,
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.blue.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                        labelResolver: (line) => 'Min Threshold',
                      ),
                    ),
                  ],
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          meta: meta,
                          space: 4,
                          child: Text(
                            value.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[500],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spotsX,
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 1.5,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: spotsY,
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 1.5,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: spotsZ,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 1.5,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      final history = telemetryState.history[sensor.sensorId] ?? [];
      if (history.isEmpty) {
        return const SizedBox(
          height: 120,
          child: Center(
            child: Text(
              'Waiting for telemetry data...',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        );
      }

      final spots = history
          .asMap()
          .entries
          .map((e) => FlSpot(e.key.toDouble(), e.value.value))
          .toList();

      // Find min/max values to fit the chart nicely
      double minY = sensor.minThreshold;
      double maxY = sensor.maxThreshold;
      for (final r in history) {
        if (r.value < minY) minY = r.value;
        if (r.value > maxY) maxY = r.value;
      }
      final yRange = (maxY - minY).abs();
      final rangePadding = yRange > 0 ? yRange * 0.15 : 1.0;
      minY = minY - rangePadding;
      maxY = maxY + rangePadding;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 130,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.12),
                    strokeWidth: 1,
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: sensor.maxThreshold,
                      color: Colors.red.withOpacity(0.35),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.red.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                        labelResolver: (line) => 'Max Threshold',
                      ),
                    ),
                    HorizontalLine(
                      y: sensor.minThreshold,
                      color: Colors.blue.withOpacity(0.35),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.bottomRight,
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.blue.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                        labelResolver: (line) => 'Min Threshold',
                      ),
                    ),
                  ],
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          meta: meta,
                          space: 4,
                          child: Text(
                            value.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[500],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.blue,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.blue.withOpacity(0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  IconData _getSensorIcon(String type) {
    switch (type.toLowerCase()) {
      case 'temperature':
        return LucideIcons.thermometer;
      case 'current':
        return LucideIcons.zap;
      case 'vibration':
        return LucideIcons.waves;
      default:
        return LucideIcons.activity;
    }
  }
}

// ============ Add Sensor Dialog ============
class AddSensorDialog extends StatefulWidget {
  final Function(SensorModel) onSensorAdded;
  const AddSensorDialog({Key? key, required this.onSensorAdded})
    : super(key: key);

  @override
  State<AddSensorDialog> createState() => _AddSensorDialogState();
}

class _AddSensorDialogState extends State<AddSensorDialog> {
  final _sensorIdController = TextEditingController();
  final _minController = TextEditingController();
  final _maxController = TextEditingController();
  final _unitController = TextEditingController();
  String _selectedType = 'temperature';
  bool _isActive = true;
  bool _isAdding = false;

  @override
  void dispose() {
    _sensorIdController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Sensor'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _sensorIdController,
              decoration: InputDecoration(
                labelText: 'Sensor ID',
                hintText: 'e.g. temp_01',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Sensor Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: [
                'temperature',
                'current',
                'vibration',
              ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (value) =>
                  setState(() => _selectedType = value ?? 'temperature'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Min Threshold',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Max Threshold',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _unitController,
              decoration: InputDecoration(
                labelText: 'Unit',
                hintText: 'e.g. °C, A, Hz',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Active', style: TextStyle(fontSize: 14)),
                Switch(
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isAdding ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isAdding ? null : _submit,
          child: _isAdding
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final id = _sensorIdController.text.trim();
    final min = double.tryParse(_minController.text.trim());
    final max = double.tryParse(_maxController.text.trim());
    final unit = _unitController.text.trim();

    if (id.isEmpty || min == null || max == null || unit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields correctly')),
      );
      return;
    }

    setState(() => _isAdding = true);
    try {
      final repo = SensorsRepository();
      final sensor = await repo.addSensor(
        sensorId: id,
        sensorType: _selectedType,
        minThreshold: min,
        maxThreshold: max,
        unit: unit,
        isActive: _isActive,
      );

      if (!mounted) return;
      widget.onSensorAdded(sensor);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sensor added successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add sensor: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }
}
