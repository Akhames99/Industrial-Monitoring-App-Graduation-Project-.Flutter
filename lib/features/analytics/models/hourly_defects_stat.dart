/// Model for a single point in the /analytics/hourly-defects trend array.
class HourlyDefectPoint {
  final String hourLabel;
  final int defectCount;

  HourlyDefectPoint({required this.hourLabel, required this.defectCount});

  factory HourlyDefectPoint.fromJson(Map<String, dynamic> json) {
    return HourlyDefectPoint(
      hourLabel: json['hour_label']?.toString() ?? '',
      defectCount: (json['defect_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Model for the full /analytics/hourly-defects response.
class HourlyDefectsResponse {
  final String date;
  final List<HourlyDefectPoint> trend;

  HourlyDefectsResponse({required this.date, required this.trend});

  factory HourlyDefectsResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawTrend = json['trend'] as List<dynamic>? ?? [];
    return HourlyDefectsResponse(
      date: json['date']?.toString() ?? '',
      trend: rawTrend
          .map((e) => HourlyDefectPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  int get totalDefects =>
      trend.fold(0, (sum, point) => sum + point.defectCount);

  int get maxDefectCount => trend.isEmpty
      ? 0
      : trend.map((p) => p.defectCount).reduce((a, b) => a > b ? a : b);
}
