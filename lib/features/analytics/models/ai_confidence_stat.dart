/// One category row from /analytics/ai-confidence.
class AiConfidenceStat {
  final String category;
  final double averageConfidence;
  final int sampleCount;

  const AiConfidenceStat({
    required this.category,
    required this.averageConfidence,
    required this.sampleCount,
  });

  factory AiConfidenceStat.fromJson(Map<String, dynamic> json) {
    return AiConfidenceStat(
      category: json['category'] as String? ?? 'Unknown',
      averageConfidence:
          (json['average_confidence'] as num?)?.toDouble() ?? 0.0,
      sampleCount: (json['sample_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Full response of /analytics/ai-confidence.
class AiConfidenceResponse {
  final int timeframeDays;
  final List<AiConfidenceStat> stats;

  const AiConfidenceResponse({
    required this.timeframeDays,
    required this.stats,
  });

  factory AiConfidenceResponse.fromJson(Map<String, dynamic> json) {
    final rawStats = json['stats'] as List<dynamic>? ?? [];
    return AiConfidenceResponse(
      timeframeDays: (json['timeframe_days'] as num?)?.toInt() ?? 7,
      stats: rawStats
          .map((e) => AiConfidenceStat.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
