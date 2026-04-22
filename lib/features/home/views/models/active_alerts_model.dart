import 'package:flutter/material.dart';

enum AlertSeverity { warning, critical, info }

enum AlertStatus { active, acknowledged, resolved }

// Data Models
class Alert {
  final String id;
  final String title;
  final String description;
  final AlertSeverity severity;
  final AlertStatus status;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;

  Alert({
    required this.id,
    required this.title,
    required this.description,
    this.severity = AlertSeverity.warning,
    this.status = AlertStatus.active,
    required this.createdAt,
    this.acknowledgedAt,
    this.resolvedAt,
  });

  bool get isAcknowledged =>
      status == AlertStatus.acknowledged || status == AlertStatus.resolved;

  // Copy constructor
  Alert copyWith({
    String? id,
    String? title,
    String? description,
    AlertSeverity? severity,
    AlertStatus? status,
    DateTime? createdAt,
    DateTime? acknowledgedAt,
    DateTime? resolvedAt,
  }) {
    return Alert(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  // Convert from JSON
  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      severity: _parseSeverity(json['severity']),
      status: _parseStatus(json['status']),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      acknowledgedAt: json['acknowledgedAt'] != null
          ? DateTime.parse(json['acknowledgedAt'])
          : null,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'])
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'severity': severity.toString(),
      'status': status.toString(),
      'createdAt': createdAt.toIso8601String(),
      'acknowledgedAt': acknowledgedAt?.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }

  static AlertSeverity _parseSeverity(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'critical':
          return AlertSeverity.critical;
        case 'info':
          return AlertSeverity.info;
        default:
          return AlertSeverity.warning;
      }
    }
    return AlertSeverity.warning;
  }

  static AlertStatus _parseStatus(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'acknowledged':
          return AlertStatus.acknowledged;
        case 'resolved':
          return AlertStatus.resolved;
        default:
          return AlertStatus.active;
      }
    }
    return AlertStatus.active;
  }
}

class AlertsContainer {
  final List<Alert> alerts;
  final DateTime lastUpdated;

  AlertsContainer({required this.alerts, required this.lastUpdated});

  List<Alert> get activeAlerts =>
      alerts.where((a) => !a.isAcknowledged).toList();
  List<Alert> get acknowledgedAlerts =>
      alerts.where((a) => a.isAcknowledged).toList();

  int get activeCount => activeAlerts.length;
  int get criticalCount =>
      activeAlerts.where((a) => a.severity == AlertSeverity.critical).length;
  int get warningCount =>
      activeAlerts.where((a) => a.severity == AlertSeverity.warning).length;
}

// Service class for fetching alerts
class AlertsService {
  static const String baseUrl = 'https://your-api.com/api';

  // Fetch active alerts
  Future<AlertsContainer> fetchActiveAlerts() async {
    try {
      // TODO: Replace with actual API call
      // final response = await http.get(
      //   Uri.parse('$baseUrl/alerts?status=active'),
      // );

      // Mock data for now
      return AlertsContainer(
        alerts: [
          Alert(
            id: '1',
            title: 'High Temp',
            description:
                'The temperature of the motor is very high, Please check the motor\'s condition',
            severity: AlertSeverity.warning,
            status: AlertStatus.active,
            createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
          Alert(
            id: '2',
            title: 'Cam2',
            description: 'Cam2 is not active, Please check the cam2 condition',
            severity: AlertSeverity.warning,
            status: AlertStatus.active,
            createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
          ),
        ],
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to fetch alerts: $e');
    }
  }

  // Acknowledge alert
  Future<bool> acknowledgeAlert(String alertId) async {
    try {
      // TODO: Replace with actual API call
      // final response = await http.put(
      //   Uri.parse('$baseUrl/alerts/$alertId/acknowledge'),
      // );

      return true;
    } catch (e) {
      throw Exception('Failed to acknowledge alert: $e');
    }
  }

  // Resolve alert
  Future<bool> resolveAlert(String alertId) async {
    try {
      // TODO: Replace with actual API call
      // final response = await http.put(
      //   Uri.parse('$baseUrl/alerts/$alertId/resolve'),
      // );

      return true;
    } catch (e) {
      throw Exception('Failed to resolve alert: $e');
    }
  }

  // Dismiss alert
  Future<bool> dismissAlert(String alertId) async {
    try {
      // TODO: Replace with actual API call
      // final response = await http.delete(
      //   Uri.parse('$baseUrl/alerts/$alertId'),
      // );

      return true;
    } catch (e) {
      throw Exception('Failed to dismiss alert: $e');
    }
  }
}

// Mock data for testing
class AlertsMockData {
  static final warningAlerts = [
    Alert(
      id: '1',
      title: 'High Temp',
      description:
          'The temperature of the motor is very high, Please check the motor\'s condition',
      severity: AlertSeverity.warning,
      status: AlertStatus.active,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    Alert(
      id: '2',
      title: 'Cam2',
      description: 'Cam2 is not active, Please check the cam2 condition',
      severity: AlertSeverity.warning,
      status: AlertStatus.active,
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
  ];

  static final criticalAlerts = [
    Alert(
      id: '3',
      title: 'Motor Failure',
      description: 'Motor 3 has failed and needs immediate attention',
      severity: AlertSeverity.critical,
      status: AlertStatus.active,
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
  ];

  static final infoAlerts = [
    Alert(
      id: '4',
      title: 'Maintenance Due',
      description: 'Scheduled maintenance is due for equipment A',
      severity: AlertSeverity.info,
      status: AlertStatus.active,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  static final allAlerts = [...warningAlerts, ...criticalAlerts, ...infoAlerts];
}

// Color helper extension
extension AlertColorExtension on AlertSeverity {
  Color getBackgroundColor() {
    switch (this) {
      case AlertSeverity.critical:
        return const Color(0xFFFEE8E8); // Light red
      case AlertSeverity.warning:
        return const Color(0xFFFEF5E7); // Light yellow/tan
      case AlertSeverity.info:
        return const Color(0xFFEBF5FB); // Light blue
    }
  }

  Color getBorderColor() {
    switch (this) {
      case AlertSeverity.critical:
        return const Color(0xFFFFCDD2); // Red border
      case AlertSeverity.warning:
        return const Color(0xFFFFE4B5); // Yellow border
      case AlertSeverity.info:
        return const Color(0xFFBBDEFB); // Blue border
    }
  }

  Color getIconColor() {
    switch (this) {
      case AlertSeverity.critical:
        return const Color(0xFFE74C3C); // Red
      case AlertSeverity.warning:
        return const Color(0xFFF39C12); // Orange/Yellow
      case AlertSeverity.info:
        return const Color(0xFF3498DB); // Blue
    }
  }

  Color getActionColor() {
    switch (this) {
      case AlertSeverity.critical:
        return const Color(0xFFE74C3C);
      case AlertSeverity.warning:
        return const Color(0xFFF39C12);
      case AlertSeverity.info:
        return const Color(0xFF3498DB);
    }
  }

  Color getBadgeColor() {
    switch (this) {
      case AlertSeverity.critical:
        return const Color(0xFFE74C3C);
      case AlertSeverity.warning:
        return const Color(0xFFF39C12);
      case AlertSeverity.info:
        return const Color(0xFF3498DB);
    }
  }
}
