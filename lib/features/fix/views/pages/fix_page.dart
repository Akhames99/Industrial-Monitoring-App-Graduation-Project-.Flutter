import 'package:app/core/utils/theme/app_colors.dart';
import 'package:flutter/material.dart';

class FixPage extends StatefulWidget {
  const FixPage({super.key});

  @override
  State<FixPage> createState() => _FixPageState();
}

class _FixPageState extends State<FixPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(child: Text('Fix Page')),
    );
  }
}
