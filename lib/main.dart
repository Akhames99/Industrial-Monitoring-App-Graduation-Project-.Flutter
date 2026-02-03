import 'package:app/core/utils/theme/app_theme.dart';
import 'package:app/features/login/views/pages/login_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Industrial Monitoring App',
      theme: AppTheme.primary,
      home: LoginPage(),
    );
  }
}
