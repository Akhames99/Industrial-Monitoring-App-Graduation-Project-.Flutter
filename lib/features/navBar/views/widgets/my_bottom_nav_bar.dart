import 'package:app/core/utils/theme/app_colors.dart';
// import 'package:app/features/fix/views/pages/fix_page.dart';
import 'package:app/features/home/views/pages/home_page.dart';
import 'package:app/features/quality%20log/views/pages/quality_log_page.dart';
import 'package:app/features/sensors/views/pages/sensors_page.dart';
import 'package:app/features/analytics/views/pages/analytics_page.dart';
import 'package:app/features/control/views/pages/control_page.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

class MyBottomNavigationBar extends StatefulWidget {
  const MyBottomNavigationBar({super.key});

  @override
  State<MyBottomNavigationBar> createState() => _MyBottomNavigationBarState();
}

class _MyBottomNavigationBarState extends State<MyBottomNavigationBar> {
  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      backgroundColor: AppColors.primary,
      tabs: [
        PersistentTabConfig(
          screen: HomePage(),
          item: ItemConfig(
            icon: Icon(LucideIcons.layoutDashboard),
            title: "Home",
            activeForegroundColor: AppColors.white,
            activeColorSecondary: AppColors.blue,
          ),
        ),
        PersistentTabConfig(
          screen: AnalyticsPage(),
          item: ItemConfig(
            icon: Icon(Icons.bar_chart_rounded),
            title: "Analytics",
            activeForegroundColor: AppColors.white,
            activeColorSecondary: AppColors.blue,
          ),
        ),
        PersistentTabConfig(
          screen: QualityLogPage(),
          item: ItemConfig(
            icon: Icon(LucideIcons.clipboardList300),
            title: "Log",
            activeForegroundColor: AppColors.white,
            activeColorSecondary: AppColors.blue,
          ),
        ),
        PersistentTabConfig(
          screen: SensorsPage(),
          item: ItemConfig(
            icon: Icon(LucideIcons.activity),
            title: "Sensors",
            activeForegroundColor: AppColors.white,
            activeColorSecondary: AppColors.blue,
          ),
        ),
        PersistentTabConfig(
          screen: ControlPage(),
          item: ItemConfig(
            icon: Icon(LucideIcons.settings2),
            title: "Control",
            activeForegroundColor: AppColors.white,
            activeColorSecondary: AppColors.blue,
          ),
        ),
      ],
      navBarBuilder: (navBarConfig) => Style2BottomNavBar(
        navBarConfig: navBarConfig,
        height: 74.0,
        navBarDecoration: NavBarDecoration(
          color: AppColors.navBar,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.0),
            topRight: Radius.circular(24.0),
          ),
        ),
      ),
    );
  }
}
