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
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(height: 80.0, width: 80.0, child: Image.asset(imagePath)),
        const SizedBox(height: 24.0),
        Text(headline),
        Text(description),
      ],
    );
  }
}
