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
      height: 412.0,
      width: double.infinity,
      child: Column(
        children: [
          Expanded(
            child: CarouselSlider(
              items: items,
              carouselController: _controller,
              options: CarouselOptions(
                autoPlay: false,
                enlargeCenterPage: true,
                aspectRatio: 2.0,
                onPageChanged: (index, reason) {
                  setState(() {
                    _current = index;
                  });
                },
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: items.asMap().entries.map((entry) {
              return GestureDetector(
                onTap: () => _controller.animateToPage(entry.key),
                child: Container(
                  width: 12.0,
                  height: 12.0,
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black)
                            .withOpacity(_current == entry.key ? 0.9 : 0.4),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
