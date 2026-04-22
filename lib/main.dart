import 'dart:convert';
import 'package:app/core/api/api_client.dart';
import 'package:app/core/api/api_response_models.dart';
import 'package:app/core/utils/route/app_router.dart';
import 'package:app/core/utils/route/app_routes.dart';
import 'package:app/core/utils/theme/app_theme.dart';
import 'package:app/features/auth/repositories/auth_repository.dart';
import 'package:app/features/login/cubit/login_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiClient = ApiClient();
  final token = await apiClient.getStoredToken();

  LoginCubit? loginCubit;
  String initialRoute;

  if (token != null) {
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString('saved_user');

    if (savedUser != null) {
      final user = UserProfileResponse.fromJson(
        jsonDecode(savedUser) as Map<String, dynamic>,
      );
      final loginResponse = LoginResponse(token: token, user: user);
      loginCubit = LoginCubit(
        apiClient: apiClient,
        authRepository: AuthRepository(apiClient: apiClient),
      )..emit(LoginSuccess(loginResponse: loginResponse));
      initialRoute = AppRoutes.navbar;
    } else {
      initialRoute = AppRoutes.login;
    }
  } else {
    initialRoute = AppRoutes.login;
  }

  runApp(
    MyApp(
      initialRoute: initialRoute,
      apiClient: apiClient,
      loginCubit: loginCubit,
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  final ApiClient apiClient;
  final LoginCubit? loginCubit;

  const MyApp({
    super.key,
    required this.initialRoute,
    required this.apiClient,
    this.loginCubit,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          loginCubit ??
          LoginCubit(
            apiClient: apiClient,
            authRepository: AuthRepository(apiClient: apiClient),
          ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Industrial Monitoring App',
        theme: AppTheme.primary,
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: initialRoute,
      ),
    );
  }
}
