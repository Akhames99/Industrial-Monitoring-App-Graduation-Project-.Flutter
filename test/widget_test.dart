// Basic Flutter widget test for the Industrial Monitoring App.

import 'package:app/core/api/api_client.dart';
import 'package:app/core/utils/route/app_routes.dart';
import 'package:app/features/login/cubit/login_cubit.dart';
import 'package:app/features/auth/repositories/auth_repository.dart';
import 'package:app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    final apiClient = ApiClient();
    final loginCubit = LoginCubit(
      apiClient: apiClient,
      authRepository: AuthRepository(apiClient: apiClient),
    );

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MyApp(
        initialRoute: AppRoutes.login,
        apiClient: apiClient,
        loginCubit: loginCubit,
      ),
    );

    // Verify the app renders without throwing.
    await tester.pump();
  });
}
