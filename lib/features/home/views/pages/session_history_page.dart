import 'package:app/core/utils/theme/app_colors.dart';
import 'package:app/features/home/bloc/home_bloc.dart';
import 'package:app/features/home/widgets/system_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class SessionHistoryPage extends StatefulWidget {
  const SessionHistoryPage({super.key});

  @override
  State<SessionHistoryPage> createState() => _SessionHistoryPageState();
}

class _SessionHistoryPageState extends State<SessionHistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(FetchSessionHistory());
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: context.read<HomeBloc>().state.selectedHistoryDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.blue,
              onPrimary: Colors.white,
              onSurface: AppColors.title,
            ),
          ),
          child: child!,
        );
      },
    );
    if (!mounted) return;
    if (picked != null) {
      context.read<HomeBloc>().add(ChangeHistoryDate(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text(
          'Session History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.title,
        centerTitle: true,
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          final dateStr = DateFormat(
            'yyyy-MM-dd',
          ).format(state.selectedHistoryDate);
          final isToday =
              DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateStr;

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.description,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isToday ? 'Today ($dateStr)' : dateStr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.title,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_month_rounded,
                            color: AppColors.blue,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (state.status == HomeStatus.loading &&
                      state.allSessions.isEmpty)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.blue),
                      ),
                    )
                  else if (state.status == HomeStatus.failure &&
                      state.allSessions.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              state.errorMessage ?? 'Failed to load history',
                              textAlign: TextAlign.center,
                            ),
                            TextButton(
                              onPressed: () => context.read<HomeBloc>().add(
                                FetchSessionHistory(),
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    SystemStateWidget(
                      segments: state.historySegments,
                      subtitle: 'Timeline for $dateStr',
                      currentStatus: isToday ? state.systemStatus : 'Past Day',
                      showButtons: false,
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Session Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (state.allSessions.isEmpty)
                      const Center(
                        child: Text('No sessions found for this day'),
                      )
                    else
                      ..._buildSessionList(state, dateStr),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildSessionList(HomeState state, String dateStr) {
    final now = DateTime.now();
    final startOfDay = DateTime(
      state.selectedHistoryDate.year,
      state.selectedHistoryDate.month,
      state.selectedHistoryDate.day,
    );
    final endOfDay = DateTime(
      state.selectedHistoryDate.year,
      state.selectedHistoryDate.month,
      state.selectedHistoryDate.day,
      23,
      59,
      59,
      999,
    );

    final daySessions = state.allSessions.where((s) {
      final sStart = s.startTime.toLocal();
      final sEnd = (s.stopTime ?? now).toLocal();
      return sStart.isBefore(endOfDay) && sEnd.isAfter(startOfDay);
    }).toList();

    daySessions.sort((a, b) => b.startTime.compareTo(a.startTime));

    if (daySessions.isEmpty) {
      return [const Center(child: Text('No active sessions in this period'))];
    }

    final timeFormat = DateFormat('HH:mm:ss');

    return daySessions.map((session) {
      final sStart = session.startTime.toLocal();
      final sEnd = session.stopTime?.toLocal();
      final duration = sEnd != null
          ? sEnd.difference(sStart)
          : DateTime.now().difference(sStart);

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: session.stopTime == null
                ? const Color(0xFF1abc9c).withOpacity(0.1)
                : Colors.grey[100],
            child: Icon(
              session.stopTime == null ? Icons.play_arrow : Icons.stop,
              color: session.stopTime == null
                  ? const Color(0xFF1abc9c)
                  : Colors.grey[600],
            ),
          ),
          title: Text('Session #${session.id}'),
          subtitle: Text(
            '${timeFormat.format(sStart)} - ${sEnd != null ? timeFormat.format(sEnd) : 'Running...'}',
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatDuration(duration),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (session.stopTime == null)
                const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: Color(0xFF1abc9c),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    if (d.inHours > 0) {
      return "${d.inHours}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
