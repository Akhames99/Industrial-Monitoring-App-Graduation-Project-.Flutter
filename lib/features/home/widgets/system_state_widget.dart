import 'package:flutter/material.dart';

enum SystemState { running, idle }

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
    this.currentStatus = 'Running',
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
                  color: isRunning
                      ? const Color(0xFFD4F8F0)
                      : const Color(0xFFF2F4F4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  currentStatus,
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    color: isRunning
                        ? const Color(0xFF1abc9c)
                        : const Color(0xFF95a5a6),
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
        const SizedBox(width: 48),
        _legendItem('Idle', _getStateColor(SystemState.idle)),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }

  Color _getStateColor(SystemState state) {
    switch (state) {
      case SystemState.running:
        return const Color(0xFF1abc9c);
      case SystemState.idle:
        return const Color(0xFF95a5a6);
    }
  }
}

class SystemStateExample extends StatelessWidget {
  const SystemStateExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final segments = [
      StateSegment(state: SystemState.idle, startHour: 0, endHour: 6),
      StateSegment(state: SystemState.running, startHour: 6, endHour: 14),
      StateSegment(state: SystemState.idle, startHour: 14, endHour: 24),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SystemStateWidget(
            segments: segments,
            subtitle: 'Last 24 hours',
            currentStatus: 'Running',
            onStartSession: () => debugPrint('Start session'),
            onStopSession: () => debugPrint('Stop session'),
          ),
        ),
      ),
    );
  }
}
