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
  await apiClient.getStoredToken();
  await apiClient.loadSessionId();

  final loginCubit = LoginCubit(
    apiClient: apiClient,
    authRepository: AuthRepository(apiClient: apiClient),
  );

  String initialRoute = AppRoutes.login;

  // Only attempt auto-login if both token and session exist
  if (apiClient.authToken != null && apiClient.sessionId != null) {
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString('saved_user');

    if (savedUser != null) {
      try {
        // No backend pre-flight check anymore (session-status endpoint was
        // removed). Trust the locally stored credentials and route straight
        // in. If the session is actually invalid/expired, the global 401
        // interceptor (onSessionExpired) will catch it on the first real API
        // call and redirect to login automatically.
        final user = UserProfileResponse.fromJson(
          jsonDecode(savedUser) as Map<String, dynamic>,
        );
        final loginResponse = LoginResponse(
          token: apiClient.authToken!,
          user: user,
          sessionId: apiClient.sessionId!,
        );
        loginCubit.emit(LoginSuccess(loginResponse: loginResponse));
        initialRoute = AppRoutes.navbar;
      } catch (e) {
        // Corrupt/unparseable saved user data — send to login
        await apiClient.clearAuthToken();
        initialRoute = AppRoutes.login;
      }
    }
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
  final LoginCubit loginCubit;

  const MyApp({
    super.key,
    required this.initialRoute,
    required this.apiClient,
    required this.loginCubit,
  });

  @override
  Widget build(BuildContext context) {
    // Wire the global 401 session-expired handler
    AppRouter.initSessionExpiredHandler();

    return BlocProvider.value(
      value: loginCubit,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Industrial Monitoring App',
        theme: AppTheme.primary,
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: initialRoute,
        navigatorKey: AppRouter.navigatorKey,
      ),
    );
  }
}
