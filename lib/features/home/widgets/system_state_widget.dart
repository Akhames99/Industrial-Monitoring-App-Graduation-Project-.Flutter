import 'package:flutter/material.dart';

enum SystemState { running, stopped, error, offline, unknown }

SystemState? mapMotorStateString(String raw) {
  switch (raw.toUpperCase()) {
    case 'RUNNING':
      return SystemState.running;
    case 'STOPPED':
      return SystemState.stopped;
    case 'ERROR':
      return SystemState.error;
    case 'OFFLINE':
      return SystemState.offline;
    case 'UNKNOWN':
      return SystemState.unknown;
    default:
      return null;
  }
}

Color getSystemStateColor(SystemState state) {
  switch (state) {
    case SystemState.running:
      return const Color(0xFF1abc9c);
    case SystemState.stopped:
      return const Color(0xFF95a5a6);
    case SystemState.error:
      return const Color(0xFFe74c3c);
    case SystemState.offline:
      return const Color(0xFF2c3e50);
    case SystemState.unknown:
      return const Color(0xFFbdc3c7);
  }
}

class StateSegment {
  final SystemState state;
  final double startHour;
  final double endHour;

  StateSegment({
    required this.state,
    required this.startHour,
    required this.endHour,
  });
}

class SystemStateWidget extends StatelessWidget {
  final List<StateSegment> segments;
  final String subtitle;
  final String currentStatus;
  final VoidCallback? onStartSession;
  final VoidCallback? onStopSession;
  final VoidCallback? onHistoryPressed;
  final bool isLoading;
  final bool showButtons;

  const SystemStateWidget({
    Key? key,
    required this.segments,
    this.subtitle = 'Last 24 hours',
    // Was 'Running' — an unsafe default that would silently show a live
    // "Running" badge if this widget is ever built before the bloc has
    // supplied a real currentStatus. 'Unknown' is a truthful placeholder.
    this.currentStatus = 'Unknown',
    this.onStartSession,
    this.onStopSession,
    this.onHistoryPressed,
    this.isLoading = false,
    this.showButtons = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isRunning = currentStatus.toLowerCase() == 'running';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'System State',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        if (onHistoryPressed != null) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: onHistoryPressed,
                            child: Icon(
                              Icons.history_rounded,
                              size: 20,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _statusBadgeColor(currentStatus).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  currentStatus,
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    color: _statusBadgeColor(currentStatus),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildTimelineBar(),
          const SizedBox(height: 16),

          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '00:00',
                style: TextStyle(fontSize: 11, color: Colors.black),
              ),
              Text(
                '06:00',
                style: TextStyle(fontSize: 11, color: Colors.black),
              ),
              Text(
                '12:00',
                style: TextStyle(fontSize: 11, color: Colors.black),
              ),
              Text(
                '18:00',
                style: TextStyle(fontSize: 11, color: Colors.black),
              ),
              Text(
                '24:00',
                style: TextStyle(fontSize: 11, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildLegend(),

          // Session Control Buttons
          if (showButtons)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading || isRunning ? null : onStartSession,
                    style:
                        ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1abc9c),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ).copyWith(
                          backgroundColor: MaterialStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(MaterialState.disabled)) {
                              return Colors.grey[300];
                            }
                            return const Color(0xFF1abc9c);
                          }),
                        ),
                    child: isLoading && !isRunning
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Start Session',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading || !isRunning ? null : onStopSession,
                    style:
                        ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFe74c3c),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ).copyWith(
                          backgroundColor: MaterialStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(MaterialState.disabled)) {
                              return Colors.grey[300];
                            }
                            return const Color(0xFFe74c3c);
                          }),
                        ),
                    child: isLoading && isRunning
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Stop Session',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: Row(
        children: segments.isEmpty
            ? [
                Expanded(
                  child: Container(height: 24, color: const Color(0xFFF2F4F4)),
                ),
              ]
            : segments.map((segment) {
                double duration = (segment.endHour - segment.startHour)
                    .toDouble();

                return Expanded(
                  flex: (duration * 100).toInt(),
                  child: Container(
                    height: 24,
                    color: _getStateColor(segment.state),
                  ),
                );
              }).toList(),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem('Running', _getStateColor(SystemState.running)),
        _legendItem('Stopped', _getStateColor(SystemState.stopped)),
        _legendItem('Error', _getStateColor(SystemState.error)),
        _legendItem('Offline', _getStateColor(SystemState.offline)),
      ],
    );
  }

  Color _statusBadgeColor(String status) {
    switch (status.toLowerCase()) {
      case 'running':
        return const Color(0xFF1abc9c);
      case 'stopped':
        return const Color(0xFF95a5a6);
      case 'error':
        return const Color(0xFFe74c3c);
      case 'offline':
        return const Color(0xFF2c3e50);
      case 'unknown':
        return const Color(0xFFbdc3c7);
      default:
        return const Color(0xFF95a5a6);
    }
  }

  Widget _legendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Color _getStateColor(SystemState state) => getSystemStateColor(state);
}
