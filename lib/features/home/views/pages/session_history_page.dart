import 'package:app/core/utils/theme/app_colors.dart';
import 'package:app/features/home/bloc/home_bloc.dart';
import 'package:app/features/home/widgets/system_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:app/core/api/api_response_models.dart';

class SessionHistoryPage extends StatefulWidget {
  const SessionHistoryPage({super.key});

  @override
  State<SessionHistoryPage> createState() => _SessionHistoryPageState();
}

class _SessionHistoryPageState extends State<SessionHistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(const FetchMotorTimeline());
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
                  if (state.isHistoryLoading && state.timelineEntries.isEmpty)
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: const Center(
                        child: CircularProgressIndicator(color: AppColors.blue),
                      ),
                    )
                  else if (state.historyErrorMessage != null &&
                      state.timelineEntries.isEmpty)
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
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
                              state.historyErrorMessage!,
                              textAlign: TextAlign.center,
                            ),
                            TextButton(
                              onPressed: () => context.read<HomeBloc>().add(
                                ChangeHistoryDate(state.selectedHistoryDate),
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
                      'State Timeline',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (state.timelineEntries.isEmpty)
                      const Center(
                        child: Text('No timeline data found for this day'),
                      )
                    else
                      ..._buildTimelineList(state.timelineEntries),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildTimelineList(List<MotorTimelineEntryResponse> entries) {
    final timeFormat = DateFormat('HH:mm:ss');
    final sorted = List<MotorTimelineEntryResponse>.from(entries)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    return sorted.map((entry) {
      final state = mapMotorStateString(entry.state) ?? SystemState.unknown;
      final color = getSystemStateColor(state);
      final start = entry.startTime.toLocal();
      final end = entry.endTime.toLocal();
      final duration = end.difference(start);

      // Guard against an empty state string from the API, which would
      // otherwise throw a RangeError on entry.state[0] below.
      final label = entry.state.isEmpty
          ? 'Unknown'
          : entry.state[0].toUpperCase() +
                entry.state.substring(1).toLowerCase();

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(_iconForState(state), color: color),
          ),
          title: Text(label),
          subtitle: Text(
            '${timeFormat.format(start)} - ${timeFormat.format(end)}',
          ),
          trailing: Text(
            _formatDuration(duration),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }).toList();
  }

  IconData _iconForState(SystemState state) {
    switch (state) {
      case SystemState.running:
        return Icons.play_arrow;
      case SystemState.stopped:
        return Icons.stop;
      case SystemState.error:
        return Icons.error_outline;
      case SystemState.offline:
        return Icons.power_off;
      case SystemState.unknown:
        return Icons.help_outline;
    }
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
