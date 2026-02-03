import 'package:app/core/utils/theme/app_colors.dart';
import 'package:app/core/utils/theme/app_fonts.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static final primary = ThemeData(
    fontFamily: AppFonts.primary,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
  );
}
