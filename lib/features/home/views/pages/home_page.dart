import 'package:app/core/utils/route/app_routes.dart';
import 'package:app/core/utils/theme/app_colors.dart';
import 'package:app/features/home/bloc/home_bloc.dart';
import 'package:app/features/home/widgets/active_alerts_widget.dart';
import 'package:app/features/home/widgets/defect_categorizaition_widget.dart';
import 'package:app/features/home/widgets/system_state_widget.dart';
import 'package:app/features/home/widgets/production_yield_widget.dart';
import 'package:app/features/login/cubit/login_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<StateSegment> systemStateSegments = [];
  late ProductionYieldData productionYieldData;
  late DefectionCategorization defectionData;
  late List<Alert> alertsList;

  @override
  void initState() {
    super.initState();
    _initializeSystemState();
    _initializeProductionYield();
    _initializeDefectionCategorization();
    _initializeAlerts();
  }

  void _initializeSystemState() {
    systemStateSegments = [
      StateSegment(state: SystemState.idle, startHour: 0, endHour: 4),
      StateSegment(state: SystemState.running, startHour: 4, endHour: 10),
      StateSegment(state: SystemState.idle, startHour: 10, endHour: 12),
    ];
  }

  void _initializeProductionYield() {
    productionYieldData = ProductionYieldData(
      goodProducts: 2160,
      defectiveProducts: 540,
      selectedPeriod: 'today',
      date: DateTime.now(),
    );
  }

  void _initializeDefectionCategorization() {
    defectionData = DefectionCategorization(
      categories: [
        DefectCategory(
          name: 'Cracks',
          count: 261,
          color: const Color(0xFF1A1A2E),
        ),
        DefectCategory(
          name: 'Scratch',
          count: 199,
          color: const Color(0xFF9B59B6),
        ),
        DefectCategory(
          name: 'Labels',
          count: 80,
          color: const Color(0xFFE67E22),
        ),
      ],
      period: 'today',
      date: DateTime.now(),
    );
  }

  void _onProductionYieldPeriodChanged(String period) {
    setState(() {
      productionYieldData = productionYieldData.copyWith(
        selectedPeriod: period,
      );
    });
  }

  void _onDefectionPeriodChanged(String period) {
    setState(() {
      defectionData = defectionData.copyWith(period: period);
    });
  }

  void _initializeAlerts() {
    alertsList = [];
  }

  void _onAlertAcknowledged(String alertId) {
    debugPrint('Alert acknowledged: $alertId');
  }

  void _onAlertDismissed(String alertId) {
    debugPrint('Alert dismissed: $alertId');
  }

  @override
  Widget build(BuildContext context) {
    final loginState = context.watch<LoginCubit>().state;
    final user = loginState is LoginSuccess
        ? loginState.loginResponse.user
        : null;

    final avatarInitial =
        (user?.fullName?.isNotEmpty == true
                ? user!.fullName![0]
                : user?.username.isNotEmpty == true
                ? user!.username[0]
                : '?')
            .toUpperCase();

    final displayName =
        (user?.fullName?.isNotEmpty == true
            ? user!.fullName!
            : user?.username) ??
        'Unknown User';

    final displayRole = user?.role ?? 'Unknown Role';

    return BlocListener<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 44.0),
          child: RefreshIndicator(
            onRefresh: () async {
              final bloc = context.read<HomeBloc>();
              bloc.add(HomeFetchData());
              // Wait for the status to change from loading
              await bloc.stream.firstWhere(
                (state) => state.status != HomeStatus.loading,
              );
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          InkWell(
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.settings,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.purple,
                                shape: BoxShape.circle,
                              ),
                              height: 40.0,
                              width: 40.0,
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  avatarInitial,
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontFamily: 'nunito',
                                    fontSize: 10.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayRole,
                                style: TextStyle(
                                  color: AppColors.description,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12.0,
                                ),
                              ),
                              Text(
                                displayName,
                                style: TextStyle(
                                  color: AppColors.title,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        height: 40.0,
                        width: 40.0,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          size: 20.0,
                          color: AppColors.description,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24.0),
                  BlocBuilder<HomeBloc, HomeState>(
                    builder: (context, state) {
                      return SystemStateWidget(
                        segments: state.systemSegments.isNotEmpty
                            ? state.systemSegments
                            : systemStateSegments,
                        subtitle: 'Last 24 hours',
                        currentStatus: state.systemStatus,
                        isLoading: state.isSessionLoading,
                        showButtons: false,
                      );
                    },
                  ),
                  const SizedBox(height: 24.0),
                  ProductionYieldWidget(
                    data: productionYieldData,
                    onPeriodChanged: _onProductionYieldPeriodChanged,
                  ),
                  const SizedBox(height: 24.0),
                  DefectionCategorizationWidget(
                    data: defectionData,
                    onPeriodChanged: _onDefectionPeriodChanged,
                  ),
                  const SizedBox(height: 24.0),
                  ActiveAlertsWidget(
                    alerts: alertsList,
                    onAlertAcknowledged: _onAlertAcknowledged,
                    onAlertDismissed: _onAlertDismissed,
                  ),
                  const SizedBox(height: 24.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
