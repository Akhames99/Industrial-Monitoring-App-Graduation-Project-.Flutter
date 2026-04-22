import 'package:app/core/utils/theme/app_colors.dart';
import 'package:app/features/navBar/views/widgets/my_bottom_nav_bar.dart';
import 'package:flutter/material.dart';

import 'package:app/features/home/bloc/home_bloc.dart';
import 'package:app/features/home/repositories/home_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NavbarPage extends StatefulWidget {
  const NavbarPage({super.key});

  @override
  State<NavbarPage> createState() => _NavbarPageState();
}

class _NavbarPageState extends State<NavbarPage> with WidgetsBindingObserver {
  late HomeBloc _homeBloc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _homeBloc = HomeBloc(homeRepository: HomeRepository())
      ..add(HomeFetchData());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _homeBloc.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Sync session state when the app is resumed from background
      _homeBloc.add(const CheckActiveSessionRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _homeBloc,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: const MyBottomNavigationBar(),
      ),
    );
  }
}
