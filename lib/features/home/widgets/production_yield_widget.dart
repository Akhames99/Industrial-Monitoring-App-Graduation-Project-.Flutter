// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';

import 'package:app/core/utils/theme/app_fonts.dart';

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

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'goodProducts': goodProducts,
      'defectiveProducts': defectiveProducts,
      'selectedPeriod': selectedPeriod,
      'date': date.millisecondsSinceEpoch,
    };
  }

  factory ProductionYieldData.fromMap(Map<String, dynamic> map) {
    return ProductionYieldData(
      goodProducts: map['goodProducts'] as int,
      defectiveProducts: map['defectiveProducts'] as int,
      selectedPeriod: map['selectedPeriod'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
    );
  }

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
}

class ProductionYieldWidget extends StatefulWidget {
  final ProductionYieldData data;
  final Function(String)? onPeriodChanged;
  final List<String> availableSessions;

  const ProductionYieldWidget({
    Key? key,
    required this.data,
    this.onPeriodChanged,
    this.availableSessions = const [],
  }) : super(key: key);

  @override
  State<ProductionYieldWidget> createState() => _ProductionYieldWidgetState();
}

class _ProductionYieldWidgetState extends State<ProductionYieldWidget> {
  late String selectedPeriod;

  @override
  void initState() {
    super.initState();
    selectedPeriod = widget.data.selectedPeriod;
  }

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Production Yield',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              _buildPeriodSelector(),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildStatItem(
                color: const Color(0xFF4A7FFF),
                label: 'Good',
                value: widget.data.goodProducts,
              ),
              const SizedBox(width: 32),
              _buildStatItem(
                color: const Color(0xFF1A1A2E),
                label: 'Defected',
                value: widget.data.defectiveProducts,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildCircularProgress(),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${widget.data.goodPercentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 32.0,
                        fontFamily: AppFonts.poppins,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Of the total: ',
                            style: TextStyle(
                              fontFamily: AppFonts.poppins,
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          TextSpan(
                            text: '${widget.data.totalProducts}\n',
                            style: TextStyle(
                              fontFamily: AppFonts.poppins,
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                          TextSpan(
                            text: 'are ',
                            style: TextStyle(
                              fontFamily: AppFonts.poppins,
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          TextSpan(
                            text: 'Good',
                            style: const TextStyle(
                              fontFamily: AppFonts.poppins,
                              fontSize: 12,
                              color: Color(0xFF4A7FFF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required Color color,
    required String label,
    required int value,
  }) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return GestureDetector(
      onTap: _showPeriodMenu,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedPeriod,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(width: 6),
            Icon(Icons.expand_more, size: 16, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularProgress() {
    final goodPercentage = widget.data.goodPercentage;
    final radius = 95.0; // 190x190 rect (95 * 2 = 190)
    const strokeWidth = 20.0;

    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
            ),
          ),

          CustomPaint(
            size: Size(radius * 2, radius * 2),
            painter: CircularProgressPainter(
              percentage: goodPercentage,
              goodColor: const Color(0xFF4A7FFF),
              defectiveColor: const Color(0xFF1A1A2E),
              strokeWidth: strokeWidth,
            ),
          ),

          Container(
            width: radius * 2 - strokeWidth * 2,
            height: radius * 2 - strokeWidth * 2,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showPeriodMenu() {
    final periods = ['today', 'this week', 'this month', 'this year'];
    final allOptions = [...periods, ...widget.availableSessions];

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 150,
        350,
        0,
        0,
      ),
      items: allOptions
          .map(
            (option) => PopupMenuItem(
              value: option,
              child: Text(
                option.startsWith('today') || periods.contains(option)
                    ? option
                    : 'Session $option',
              ),
              onTap: () {
                setState(() {
                  selectedPeriod = option;
                });
                widget.onPeriodChanged?.call(option);
              },
            ),
          )
          .toList(),
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double percentage;
  final Color goodColor;
  final Color defectiveColor;
  final double strokeWidth;

  CircularProgressPainter({
    required this.percentage,
    required this.goodColor,
    required this.defectiveColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final goodPaint = Paint()
      ..color = goodColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final defectivePaint = Paint()
      ..color = defectiveColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const startAngle = -90 * 3.14159 / 180;
    final goodAngle = (percentage / 100) * 2 * 3.14159;
    final defectiveAngle = 2 * 3.14159 - goodAngle;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      goodAngle,
      false,
      goodPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle + goodAngle,
      defectiveAngle,
      false,
      defectivePaint,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}

// Example Usage
class ProductionYieldExample extends StatelessWidget {
  const ProductionYieldExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = ProductionYieldData(
      goodProducts: 2160,
      defectiveProducts: 540,
      selectedPeriod: 'today',
      date: DateTime.now(),
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ProductionYieldWidget(
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
