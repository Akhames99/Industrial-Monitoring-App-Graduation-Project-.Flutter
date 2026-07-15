import 'package:app/features/home/views/models/active_alerts_model.dart';
import 'package:flutter/material.dart';

class ActiveAlertsWidget extends StatefulWidget {
  final List<Alert> alerts;
  final Function(String)? onAlertAcknowledged;
  final Function(String)? onAlertDismissed;

  const ActiveAlertsWidget({
    Key? key,
    required this.alerts,
    this.onAlertAcknowledged,
    this.onAlertDismissed,
  }) : super(key: key);

  @override
  State<ActiveAlertsWidget> createState() => _ActiveAlertsWidgetState();
}

class _ActiveAlertsWidgetState extends State<ActiveAlertsWidget> {
  late List<Alert> _alerts;

  @override
  void initState() {
    super.initState();
    _alerts = List.from(widget.alerts);
  }

  @override
  void didUpdateWidget(ActiveAlertsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.alerts != widget.alerts) {
      _alerts = List.from(widget.alerts);
    }
  }

  void _acknowledgeAlert(String alertId) {
    setState(() {
      final index = _alerts.indexWhere((alert) => alert.id == alertId);
      if (index != -1) {
        _alerts[index] = _alerts[index].copyWith(
          status: AlertStatus.acknowledged,
          acknowledgedAt: DateTime.now(),
        );
      }
    });
    widget.onAlertAcknowledged?.call(alertId);
  }

  // void _dismissAlert(String alertId) {
  //   setState(() {
  //     _alerts.removeWhere((alert) => alert.id == alertId);
  //   });
  //   widget.onAlertDismissed?.call(alertId);
  // }

  @override
  Widget build(BuildContext context) {
    final activeAlerts = _alerts
        .where((alert) => !alert.isAcknowledged)
        .toList();

    if (activeAlerts.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
              const Text(
                'Active Alerts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getAlertBadgeColor(
                    activeAlerts.any(
                          (a) => a.severity == AlertSeverity.critical,
                        )
                        ? AlertSeverity.critical
                        : activeAlerts.any(
                            (a) => a.severity == AlertSeverity.warning,
                          )
                        ? AlertSeverity.warning
                        : AlertSeverity.info,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${activeAlerts.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activeAlerts.length,
            itemBuilder: (context, index) {
              final alert = activeAlerts[index];
              return Column(
                children: [
                  _buildAlertCard(alert),
                  if (index < activeAlerts.length - 1)
                    const SizedBox(height: 12),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          const Text(
            'Active Alerts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.check_circle, size: 48, color: Colors.green[300]),
                  const SizedBox(height: 12),
                  Text(
                    'No active alerts',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'System Operates normally',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Alert alert) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getAlertBackgroundColor(alert.severity),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getAlertBorderColor(alert.severity),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_outlined,
                color: _getAlertIconColor(alert.severity),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => _acknowledgeAlert(alert.id),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check,
                    size: 16,
                    color: _getAlertActionColor(alert.severity),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Acknowledge',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getAlertActionColor(alert.severity),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getAlertBackgroundColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return const Color(0xFFFEE8E8);
      case AlertSeverity.warning:
        return const Color(0xFFFEF5E7);
      case AlertSeverity.info:
        return const Color(0xFFEBF5FB);
    }
  }

  Color _getAlertBorderColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return const Color(0xFFFFCDD2);
      case AlertSeverity.warning:
        return const Color(0xFFFFE4B5);
      case AlertSeverity.info:
        return const Color(0xFFBBDEFB);
    }
  }

  Color _getAlertIconColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return const Color(0xFFE74C3C);
      case AlertSeverity.warning:
        return const Color(0xFFF39C12);
      case AlertSeverity.info:
        return const Color(0xFF3498DB);
    }
  }

  Color _getAlertActionColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return const Color(0xFFE74C3C);
      case AlertSeverity.warning:
        return const Color(0xFFF39C12);
      case AlertSeverity.info:
        return const Color(0xFF3498DB);
    }
  }

  Color _getAlertBadgeColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return const Color(0xFFE74C3C);
      case AlertSeverity.warning:
        return const Color(0xFFF39C12);
      case AlertSeverity.info:
        return const Color(0xFF3498DB);
    }
  }
}

class ActiveAlertsExample extends StatefulWidget {
  const ActiveAlertsExample({Key? key}) : super(key: key);

  @override
  State<ActiveAlertsExample> createState() => _ActiveAlertsExampleState();
}

class _ActiveAlertsExampleState extends State<ActiveAlertsExample> {
  late List<Alert> alerts;

  @override
  void initState() {
    super.initState();
    alerts = [
      Alert(
        id: '1',
        title: 'High Temp',
        description:
            'The temperature of the motor is very high, Please check the motor\'s condition',
        severity: AlertSeverity.warning,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      Alert(
        id: '2',
        title: 'Cam2',
        description: 'Cam2 is not active, Please check the cam2 condition',
        severity: AlertSeverity.warning,
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: ActiveAlertsWidget(
              alerts: alerts,
              onAlertAcknowledged: (alertId) {
                debugPrint('Alert acknowledged: $alertId');
              },
              onAlertDismissed: (alertId) {
                debugPrint('Alert dismissed: $alertId');
              },
            ),
          ),
        ),
      ),
    );
  }
}
