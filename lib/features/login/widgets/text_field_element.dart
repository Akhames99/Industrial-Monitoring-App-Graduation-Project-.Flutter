import 'package:flutter/material.dart';
import 'package:app/core/utils/theme/app_colors.dart';

class TextFieldElement extends StatelessWidget {
  final String title;
  final IconData icon;
  final TextEditingController? controller;
  final bool obscureText;
  final String? Function(String?)? validator;

  const TextFieldElement({
    Key? key,
    required this.title,
    required this.icon,
    this.controller,
    this.obscureText = false,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: title,
        prefixIcon: Icon(icon, color: AppColors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: AppColors.blue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0,
        ),
      ),
    );
  }
}
