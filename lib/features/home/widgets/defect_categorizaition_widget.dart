import 'package:app/core/utils/theme/app_colors.dart';
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
}

class DefectionCategorizationWidget extends StatelessWidget {
  final DefectionCategorization data;
  final Function(String)? onPeriodChanged;

  const DefectionCategorizationWidget({
    Key? key,
    required this.data,
    this.onPeriodChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Defection Categorization',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total Defections: ${data.totalDefects}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          ..._buildDefectItems(context),
        ],
      ),
    );
  }

  List<Widget> _buildDefectItems(BuildContext context) {
    return List.generate(data.categories.length, (index) {
      final category = data.categories[index];
      final percentage = category.getPercentage(data.totalDefects);
      final isLast = index == data.categories.length - 1;

      return Column(
        children: [
          _buildDefectItem(category, percentage, context),
          if (!isLast) const SizedBox(height: 20),
        ],
      );
    });
  }

  Widget _buildDefectItem(
    DefectCategory category,
    double percentage,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: category.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${category.name}: ${category.count}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: FractionallySizedBox(
              widthFactor: percentage / 100,
              alignment: Alignment.centerLeft,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(color: category.color),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Example usage
class DefectionCategorizationExample extends StatelessWidget {
  const DefectionCategorizationExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = DefectionCategorization(
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
        DefectCategory(
          name: 'Labels',
          count: 80,
          color: const Color(0xFFE67E22),
        ),
      ],
      date: DateTime.now(),
      period: 'today',
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DefectionCategorizationWidget(
            data: data,
            onPeriodChanged: (period) {
              debugPrint('Period changed to: $period');
            },
          ),
        ),
      ),
    );
  }
}
