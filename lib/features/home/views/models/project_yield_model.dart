class ProductionYieldData {
  final int goodProducts;
  final int defectiveProducts;
  final String selectedPeriod;
  final DateTime date;

  ProductionYieldData({
    required this.goodProducts,
    required this.defectiveProducts,
    this.selectedPeriod = 'today',
    required this.date,
  });

  int get totalProducts => goodProducts + defectiveProducts;
  double get goodPercentage => (goodProducts / totalProducts * 100);
  double get defectivePercentage => (defectiveProducts / totalProducts * 100);

  ProductionYieldData copyWith({
    int? goodProducts,
    int? defectiveProducts,
    String? selectedPeriod,
    DateTime? date,
  }) {
    return ProductionYieldData(
      goodProducts: goodProducts ?? this.goodProducts,
      defectiveProducts: defectiveProducts ?? this.defectiveProducts,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      date: date ?? this.date,
    );
  }

  // Convert from API response
  factory ProductionYieldData.fromJson(Map<String, dynamic> json) {
    return ProductionYieldData(
      goodProducts: json['goodProducts'] ?? 0,
      defectiveProducts: json['defectiveProducts'] ?? 0,
      selectedPeriod: json['period'] ?? 'today',
      date: DateTime.parse(json['date'] ?? DateTime.now().toString()),
    );
  }

  // Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'goodProducts': goodProducts,
      'defectiveProducts': defectiveProducts,
      'period': selectedPeriod,
      'date': date.toIso8601String(),
    };
  }
}

// Service for fetching production yield data
class ProductionYieldService {
  static const String baseUrl = 'https://your-api.com/api';

  // Fetch production yield data
  Future<ProductionYieldData> fetchProductionYield({
    required String period,
    required DateTime date,
  }) async {
    try {
      // TODO: Replace with actual API call
      // final response = await http.get(
      //   Uri.parse('$baseUrl/production-yield?period=$period&date=${date.toIso8601String()}'),
      // );

      // Mock data for now
      return ProductionYieldData(
        goodProducts: 2160,
        defectiveProducts: 540,
        selectedPeriod: period,
        date: date,
      );
    } catch (e) {
      throw Exception('Failed to fetch production yield: $e');
    }
  }

  // Fetch data for different periods
  Future<ProductionYieldData> fetchByPeriod(String period) async {
    return fetchProductionYield(period: period, date: DateTime.now());
  }
}

// Sample data for testing
class ProductionYieldMockData {
  static final today = ProductionYieldData(
    goodProducts: 2160,
    defectiveProducts: 540,
    selectedPeriod: 'today',
    date: DateTime.now(),
  );

  static final thisWeek = ProductionYieldData(
    goodProducts: 15240,
    defectiveProducts: 2760,
    selectedPeriod: 'this week',
    date: DateTime.now(),
  );

  static final thisMonth = ProductionYieldData(
    goodProducts: 65430,
    defectiveProducts: 10970,
    selectedPeriod: 'this month',
    date: DateTime.now(),
  );

  static final thisYear = ProductionYieldData(
    goodProducts: 780000,
    defectiveProducts: 120000,
    selectedPeriod: 'this year',
    date: DateTime.now(),
  );
}
