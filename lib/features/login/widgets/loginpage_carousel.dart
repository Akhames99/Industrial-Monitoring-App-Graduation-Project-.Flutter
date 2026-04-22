import 'package:app/core/utils/theme/app_colors.dart';
import 'package:app/features/login/widgets/carousel_item.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class LoginPageCarousel extends StatefulWidget {
  const LoginPageCarousel({super.key});

  @override
  State<LoginPageCarousel> createState() => _LoginPageCarouselState();
}

class _LoginPageCarouselState extends State<LoginPageCarousel> {
  final CarouselSliderController _controller = CarouselSliderController();
  int _current = 0;
  late final List<Widget> items;

  @override
  void initState() {
    super.initState();
    items = [
      CarouselItem(
        imagePath: 'assets/images/carousel1.png',
        headline: 'Real Time Monitoring',
        description:
            'Track production yield and hardware health from anywhere.',
      ),
      CarouselItem(
        imagePath: 'assets/images/carousel2.png',
        headline: 'AI Quality Control',
        description: 'Review defects and retrain models with a single tap.',
      ),
      CarouselItem(
        imagePath: 'assets/images/carousel3.png',
        headline: 'Instant Diagnostics',
        description: 'Locate and resolve system errors faster than ever.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 420.0,
      width: double.infinity,
      child: Column(
        children: [
          CarouselSlider(
            items: items,
            carouselController: _controller,
            options: CarouselOptions(
              autoPlay: false,
              enlargeCenterPage: true,
              aspectRatio: 1.5,
              viewportFraction: 1.0,
              onPageChanged: (index, reason) {
                setState(() {
                  _current = index;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: items.asMap().entries.map((entry) {
                return GestureDetector(
                  onTap: () => _controller.animateToPage(entry.key),
                  child: Container(
                    width: _current == entry.key ? 32.0 : 8.0,
                    height: 6.0,
                    margin: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 4.0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color:
                          (_current == entry.key
                                  ? AppColors.blue
                                  : Colors.black)
                              .withOpacity(_current == entry.key ? 0.9 : 0.2),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
