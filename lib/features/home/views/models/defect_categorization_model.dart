import 'package:flutter/material.dart';

// Data Models
class DefectCategory {
  final String name;
  final int count;
  final Color color;
  final String? icon;

  DefectCategory({
    required this.name,
    required this.count,
    required this.color,
    this.icon,
  });

  double getPercentage(int totalDefects) {
    if (totalDefects == 0) return 0;
    return (count / totalDefects) * 100;
  }

  // Copy constructor
  DefectCategory copyWith({
    String? name,
    int? count,
    Color? color,
    String? icon,
  }) {
    return DefectCategory(
      name: name ?? this.name,
      count: count ?? this.count,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }

  factory DefectCategory.fromJson(Map<String, dynamic> json) {
    return DefectCategory(
      name: json['name'] ?? '',
      count: json['count'] ?? 0,
      color: _parseColor(json['color']),
      icon: json['icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'count': count,
      'color': _colorToHex(color),
      'icon': icon,
    };
  }

  static Color _parseColor(dynamic colorValue) {
    if (colorValue is String) {
      return Color(int.parse(colorValue.replaceFirst('#', '0xff')));
    }
    return Colors.grey;
  }

  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0')}';
  }
}

class DefectionCategorization {
  final List<DefectCategory> categories;
  final DateTime date;
  final String period;

  DefectionCategorization({
    required this.categories,
    this.period = 'today',
    required this.date,
  });

  int get totalDefects => categories.fold(0, (sum, cat) => sum + cat.count);

  // Copy constructor
  DefectionCategorization copyWith({
    List<DefectCategory>? categories,
    String? period,
    DateTime? date,
  }) {
    return DefectionCategorization(
      categories: categories ?? this.categories,
      period: period ?? this.period,
      date: date ?? this.date,
    );
  }

  // Convert from JSON
  factory DefectionCategorization.fromJson(Map<String, dynamic> json) {
    final categoriesJson = json['categories'] as List? ?? [];
    return DefectionCategorization(
      categories: categoriesJson
          .map((cat) => DefectCategory.fromJson(cat as Map<String, dynamic>))
          .toList(),
      period: json['period'] ?? 'today',
      date: DateTime.parse(json['date'] ?? DateTime.now().toString()),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'categories': categories.map((cat) => cat.toJson()).toList(),
      'period': period,
      'date': date.toIso8601String(),
    };
  }
}

// Service class for fetching defection data
class DefectionCategorizationService {
  static const String baseUrl = 'https://your-api.com/api';

  // Fetch defection categorization data
  Future<DefectionCategorization> fetchDefectionCategorization({
    required String period,
    required DateTime date,
  }) async {
    try {
      // TODO: Replace with actual API call
      // final response = await http.get(
      //   Uri.parse('$baseUrl/defections?period=$period&date=${date.toIso8601String()}'),
      // );

      // Mock data for now
      return DefectionCategorization(
        categories: [
          DefectCategory(
            name: 'Cracks',
            count: 261,
            color: const Color(0xFF1A1A2E), // Dark/Black
          ),
          DefectCategory(
            name: 'Scratch',
            count: 199,
            color: const Color(0xFF9B59B6), // Purple
          ),
          DefectCategory(
            name: 'Labels',
            count: 80,
            color: const Color(0xFFE67E22), // Orange
          ),
        ],
        period: period,
        date: date,
      );
    } catch (e) {
      throw Exception('Failed to fetch defection categorization: $e');
    }
  }

  // Fetch data for different periods
  Future<DefectionCategorization> fetchByPeriod(String period) async {
    return fetchDefectionCategorization(period: period, date: DateTime.now());
  }
}

// Mock data for testing
class DefectionCategorizationMockData {
  static final today = DefectionCategorization(
    categories: [
      DefectCategory(
        name: 'Cracks',
        count: 261,
        color: const Color(0xFF1A1A2E),
      ),
      DefectCategory(
        name: 'Scratch',
        count: 199,
        color: const Color(0xFF9B59B6),
      ),
      DefectCategory(name: 'Labels', count: 80, color: const Color(0xFFE67E22)),
    ],
    period: 'today',
    date: DateTime.now(),
  );

  static final thisWeek = DefectionCategorization(
    categories: [
      DefectCategory(
        name: 'Cracks',
        count: 1305,
        color: const Color(0xFF1A1A2E),
      ),
      DefectCategory(
        name: 'Scratch',
        count: 995,
        color: const Color(0xFF9B59B6),
      ),
      DefectCategory(
        name: 'Labels',
        count: 400,
        color: const Color(0xFFE67E22),
      ),
    ],
    period: 'this week',
    date: DateTime.now(),
  );

  static final thisMonth = DefectionCategorization(
    categories: [
      DefectCategory(
        name: 'Cracks',
        count: 5220,
        color: const Color(0xFF1A1A2E),
      ),
      DefectCategory(
        name: 'Scratch',
        count: 3980,
        color: const Color(0xFF9B59B6),
      ),
      DefectCategory(
        name: 'Labels',
        count: 1600,
        color: const Color(0xFFE67E22),
      ),
    ],
    period: 'this month',
    date: DateTime.now(),
  );
}

// Predefined color scheme for defects
class DefectColors {
  static const Color cracks = Color(0xFF1A1A2E); // Dark/Black
  static const Color scratch = Color(0xFF9B59B6); // Purple
  static const Color labels = Color(0xFFE67E22); // Orange
  static const Color dents = Color(0xFF3498DB); // Blue
  static const Color misalignment = Color(0xFFE74C3C); // Red
  static const Color other = Color(0xFF95A5A6); // Gray
}
