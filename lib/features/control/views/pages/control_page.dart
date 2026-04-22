import 'package:app/core/utils/theme/app_colors.dart';
import 'package:app/core/utils/theme/app_fonts.dart';
import 'package:app/core/widgets/hold_to_confirm_button.dart';
import 'package:app/features/home/bloc/home_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ControlState {
  final int currentSpeed;
  final int targetSpeed;

  ControlState({this.currentSpeed = 0, this.targetSpeed = 400});

  ControlState copyWith({int? currentSpeed, int? targetSpeed}) {
    return ControlState(
      currentSpeed: currentSpeed ?? this.currentSpeed,
      targetSpeed: targetSpeed ?? this.targetSpeed,
    );
  }
}

class ControlPage extends StatefulWidget {
  const ControlPage({Key? key}) : super(key: key);

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  late ControlState controlState;

  @override
  void initState() {
    super.initState();
    controlState = ControlState();
    context.read<HomeBloc>().add(const CheckActiveSessionRequested());
  }

  void _updateTargetSpeed(double value) {
    setState(() {
      final newSpeed = value.toInt();
      controlState = controlState.copyWith(targetSpeed: newSpeed);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        final bool isRunning = state.systemStatus == 'Running';

        return Scaffold(
          backgroundColor: AppColors.primary,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 14.0,
              ),
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<HomeBloc>().add(
                    const CheckActiveSessionRequested(),
                  );
                  await Future.delayed(const Duration(seconds: 1));
                },
                color: AppColors.blue,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 28.0),
                      Center(child: _buildControlCircle(isRunning, state)),
                      const SizedBox(height: 24.0),
                      _buildSessionControls(context, state),
                      const SizedBox(height: 24.0),
                      _buildLineSpeedCard(isRunning),
                      const SizedBox(height: 24.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(LucideIcons.settings2, color: AppColors.blue, size: 28),
        const SizedBox(width: 12),
        Text(
          'Control',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildControlCircle(bool isRunning, HomeState state) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (isRunning)
          CustomPaint(
            size: const Size(232, 232),
            painter: ProgressRingPainter(progress: 1.0, color: AppColors.green),
          ),
        Container(
          width: 232,
          height: 232,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRunning ? Colors.green[400] : Colors.grey[300],
              ),
              child: Icon(
                isRunning ? Icons.check : Icons.power_settings_new,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isRunning ? 'RUNNING' : 'IDLE',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isRunning ? Colors.green[400] : Colors.grey[500],
              ),
            ),
            if (isRunning && state.sessionStartTime != null) ...[
              const SizedBox(height: 8),
              _buildTimer(state.sessionStartTime!),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTimer(DateTime startTime) {
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
      builder: (context, snapshot) {
        final duration = DateTime.now().difference(startTime);
        final hours = duration.inHours.toString().padLeft(2, '0');
        final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
        final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

        return Column(
          children: [
            Text(
              '$hours:$minutes:$seconds',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
                fontFamily: 'monospace',
              ),
            ),
            Text(
              'Started at: ${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 10, color: Colors.grey[400]),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSessionControls(BuildContext context, HomeState state) {
    final bool isRunning = state.systemStatus == 'Running';

    return Column(
      children: [
        if (!isRunning)
          HoldToConfirmButton(
            text: 'START SESSION',
            icon: Icons.play_arrow,
            color: Colors.blue[600]!,
            isLoading: state.isSessionLoading && !isRunning,
            onConfirmed: () {
              context.read<HomeBloc>().add(StartSessionRequested());
            },
          )
        else
          HoldToConfirmButton(
            text: 'PAUSE SESSION',
            icon: Icons.pause,
            color: Colors.orange[600]!,
            isLoading: state.isSessionLoading && isRunning,
            onConfirmed: () {
              context.read<HomeBloc>().add(StopSessionRequested());
            },
          ),
      ],
    );
  }

  Widget _buildLineSpeedCard(bool isRunning) {
    final int currentSpeed = isRunning ? controlState.targetSpeed : 0;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
              Text(
                'Line Speed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Current Speed\n',
                      style: TextStyle(
                        fontFamily: AppFonts.poppins,
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                    TextSpan(
                      text: '$currentSpeed ',
                      style: const TextStyle(
                        fontFamily: AppFonts.poppins,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    TextSpan(
                      text: 'RPM',
                      style: TextStyle(
                        fontFamily: AppFonts.poppins,
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Target Speed',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${controlState.targetSpeed} RPM',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              thumbShape: RoundSliderThumbShape(
                elevation: 4,
                enabledThumbRadius: 12,
              ),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: Slider(
              value: controlState.targetSpeed.toDouble(),
              min: 0,
              max: 1000,
              divisions: 100,
              activeColor: Colors.blue[600],
              inactiveColor: Colors.grey[300],
              onChanged: _updateTargetSpeed,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Idle',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              Text(
                'max load',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  ProgressRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -90 * 3.14159 / 180,
      (progress * 360) * 3.14159 / 180,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class ControlPageExample extends StatelessWidget {
  const ControlPageExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ControlPage();
  }
}
