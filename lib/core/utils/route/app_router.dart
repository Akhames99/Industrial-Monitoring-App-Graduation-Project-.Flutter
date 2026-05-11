import 'package:app/core/utils/route/app_routes.dart';
import 'package:app/features/login/cubit/login_cubit.dart';
import 'package:app/features/fix/views/pages/fix_page.dart';
import 'package:app/features/home/views/pages/home_page.dart';
import 'package:app/features/home/views/pages/session_history_page.dart';
import 'package:app/features/navBar/views/pages/navbar_page.dart';
import 'package:app/features/quality%20log/views/pages/quality_log_page.dart';
import 'package:app/features/login/views/pages/login_page.dart';
import 'package:app/features/settings/views/pages/settings_page.dart';
import 'package:app/features/vision/views/pages/vision_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (context) => BlocProvider.value(
            value: context.read<LoginCubit>(),
            child: const LoginPage(),
          ),
        );
      case AppRoutes.navbar:
        return MaterialPageRoute(builder: (_) => const NavbarPage());
      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (context) => BlocProvider.value(
            value: context.read<LoginCubit>(),
            child: const HomePage(),
          ),
        );
      case AppRoutes.vision:
        return MaterialPageRoute(builder: (_) => const VisionPage());
      case AppRoutes.log:
        return MaterialPageRoute(builder: (_) => const QualityLogPage());
      case AppRoutes.settings:
        return MaterialPageRoute(
          builder: (context) => BlocProvider.value(
            value: context.read<LoginCubit>(),
            child: const SettingsPage(),
          ),
        );
      case AppRoutes.fix:
        return MaterialPageRoute(builder: (_) => const FixPage());
      case AppRoutes.sessionHistory:
        return MaterialPageRoute(builder: (_) => const SessionHistoryPage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
