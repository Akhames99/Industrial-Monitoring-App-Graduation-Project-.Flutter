import 'package:app/core/utils/theme/app_colors.dart';
import 'package:app/core/utils/theme/app_fonts.dart';
import 'package:app/features/login/widgets/loginpage_carousel.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 32.0, right: 32.0, top: 44.0),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'assets/images/appIcon.png',
                  height: 40.0,
                  width: 118.0,
                ),
                Container(
                  height: 15.0,
                  width: 40.0,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6.0,
                      vertical: 2.0,
                    ),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        'v1.0.0',
                        style: TextStyle(
                          fontSize: 8.0,
                          fontFamily: AppFonts.secondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32.0),
            LoginPageCarousel(),
          ],
        ),
      ),
    );
  }
}
