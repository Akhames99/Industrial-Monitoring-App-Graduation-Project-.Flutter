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
  List<StateSegment> systemStateSegments = [
    StateSegment(state: SystemState.idle, startHour: 0, endHour: 4),
    StateSegment(state: SystemState.running, startHour: 4, endHour: 10),
    StateSegment(state: SystemState.idle, startHour: 10, endHour: 12),
  ];
  ProductionYieldData productionYieldData = ProductionYieldData(
    goodProducts: 2160,
    defectiveProducts: 540,
    selectedPeriod: 'today',
    date: DateTime.now(),
  );
  DefectionCategorization defectionData = DefectionCategorization(
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
      DefectCategory(name: 'Labels', count: 80, color: const Color(0xFFE67E22)),
    ],
    period: 'today',
    date: DateTime.now(),
  );
  List<Alert> alertsList = [];

  @override
  void initState() {
    super.initState();

    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeBloc>().add(HomeFetchData());
      context.read<HomeBloc>().add(FetchSessionHistory());
    });
  }

  void _onProductionYieldPeriodChanged(String period) {
    if (period == 'today' ||
        period == 'this week' ||
        period == 'this month' ||
        period == 'this year') {
      // Handle period if needed, or just clear session
      context.read<HomeBloc>().add(const ChangeProductionYieldSession(null));
    } else {
      // Handle session ID
      context.read<HomeBloc>().add(ChangeProductionYieldSession(period));
    }
  }

  void _onDefectionPeriodChanged(String period) {
    // Similar handling for defection if needed, or just use production yield's session
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
                        onHistoryPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.sessionHistory,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24.0),
                  BlocBuilder<HomeBloc, HomeState>(
                    builder: (context, state) {
                      final yieldData = state.productionYield != null
                          ? ProductionYieldData(
                              goodProducts: state.productionYield!.goodProducts,
                              defectiveProducts:
                                  state.productionYield!.defectiveProducts,
                              selectedPeriod: state.selectedSessionId != null
                                  ? 'Session ${state.selectedSessionId}'
                                  : state.productionYield!.period,
                              date: state.productionYield!.timestamp,
                            )
                          : productionYieldData;

                      // Add sessions to available options
                      final sessionOptions = state.allSessions
                          .map((s) => s.id.toString())
                          .toList();

                      return ProductionYieldWidget(
                        data: yieldData,
                        onPeriodChanged: _onProductionYieldPeriodChanged,
                        availableSessions: sessionOptions,
                      );
                    },
                  ),
                  const SizedBox(height: 24.0),
                  BlocBuilder<HomeBloc, HomeState>(
                    builder: (context, state) {
                      final defection = state.defectionData != null
                          ? DefectionCategorization(
                              categories: state.defectionData!.categories
                                  .map(
                                    (c) => DefectCategory(
                                      name: c.name,
                                      count: c.count,
                                      color: Color(
                                        int.parse(
                                          c.color.replaceFirst('#', '0xFF'),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              period: state.selectedSessionId != null
                                  ? 'Session ${state.selectedSessionId}'
                                  : state.defectionData!.period,
                              date: state.defectionData!.timestamp,
                            )
                          : defectionData;

                      return DefectionCategorizationWidget(
                        data: defection,
                        onPeriodChanged: _onDefectionPeriodChanged,
                      );
                    },
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
