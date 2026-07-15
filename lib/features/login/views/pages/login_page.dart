import 'package:app/core/utils/route/app_routes.dart';
import 'package:app/core/utils/theme/app_colors.dart';
import 'package:app/core/utils/theme/app_fonts.dart';
import 'package:app/features/login/widgets/loginpage_carousel.dart';
import 'package:app/features/login/widgets/text_field_element.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app/features/login/cubit/login_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController usernameController;
  late TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: BlocListener<LoginCubit, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccess) {
            // Navigate to home page on successful login
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.navbar,
              (route) => false,
            );
          } else if (state is LoginError) {
            // Show error snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 32.0,
                right: 32.0,
                top: 44.0,
              ),
              child: Column(
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
                                fontFamily: AppFonts.nunito,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 64.0),
                  LoginPageCarousel(),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32.0),
                  topRight: Radius.circular(32.0),
                ),
                child: Container(
                  height: size.height * 0.485,
                  width: double.infinity,
                  color: AppColors.white,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: 32.0,
                      top: 32.0,
                      left: 32.0,
                    ),
                    child: Column(
                      children: [
                        TextFieldElement(
                          title: 'UserName',
                          icon: Icons.person,
                          controller: usernameController,
                        ),
                        const SizedBox(height: 24.0),
                        TextFieldElement(
                          title: 'Password',
                          icon: Icons.password,
                          controller: passwordController,
                          obscureText: true,
                        ),
                        const SizedBox(height: 16.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'Forget Password?',
                                style: TextStyle(
                                  color: AppColors.blue,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        BlocBuilder<LoginCubit, LoginState>(
                          builder: (context, state) {
                            return Container(
                              height: 53.0,
                              width: 348.0,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.0),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0XFF6200EA),
                                      Color(0XFF2563EB),
                                    ],
                                    begin: Alignment.centerRight,
                                    end: Alignment.centerLeft,
                                  ),
                                ),
                                child: TextButton(
                                  onPressed: state is LoginLoading
                                      ? null
                                      : () {
                                          if (usernameController.text.isEmpty ||
                                              passwordController.text.isEmpty) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Please enter UserName and Password',
                                                ),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                            return;
                                          }

                                          context.read<LoginCubit>().login(
                                            usernameController.text.trim(),
                                            passwordController.text,
                                          );
                                        },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (state is LoginLoading)
                                        const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      else
                                        Text(
                                          'Login',
                                          style: TextStyle(
                                            color: AppColors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      if (state is! LoginLoading)
                                        Icon(
                                          Icons.arrow_right_sharp,
                                          color: AppColors.white,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16.0),
                        TextButton(
                          onPressed: () {
                            // TODO: Implement help/support
                          },
                          child: const Text('Can\'t Login?, Get Help'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
