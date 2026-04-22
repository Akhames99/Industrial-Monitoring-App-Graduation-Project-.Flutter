import 'package:app/core/utils/theme/app_colors.dart';
import 'package:app/core/utils/theme/app_fonts.dart';
import 'package:flutter/material.dart';

class CarouselItem extends StatelessWidget {
  final String imagePath;
  final String headline;
  final String description;
  const CarouselItem({
    super.key,
    required this.imagePath,
    required this.headline,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 80.0, width: 80.0, child: Image.asset(imagePath)),
        const SizedBox(height: 24.0),
        Text(
          headline,
          style: TextStyle(
            color: AppColors.title,
            fontFamily: AppFonts.outfit,
            fontWeight: FontWeight.w800,
            fontSize: 30.0,
          ),
        ),
        const SizedBox(height: 12.0),
        Expanded(
          child: Text(
            description,
            style: TextStyle(
              color: AppColors.description,
              fontFamily: AppFonts.outfit,
              fontWeight: FontWeight.w400,
              fontSize: 16.0,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
