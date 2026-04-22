import 'dart:async';
import 'package:flutter/material.dart';

class HoldToConfirmButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color color;
  final Duration duration;
  final VoidCallback onConfirmed;
  final bool isLoading;
  final bool isDisabled;

  const HoldToConfirmButton({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    required this.onConfirmed,
    this.duration = const Duration(seconds: 2),
    this.isLoading = false,
    this.isDisabled = false,
  });

  @override
  State<HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHolding = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onHoldComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _onHoldStart() {
    if (widget.isDisabled || widget.isLoading) return;
    setState(() {
      _isHolding = true;
    });
    _controller.forward();
  }

  void _onHoldEnd() {
    if (!_isHolding) return;
    setState(() {
      _isHolding = false;
    });
    if (_controller.status != AnimationStatus.completed) {
      _controller.reverse();
    }
  }

  void _onHoldComplete() {
    setState(() {
      _isHolding = false;
    });
    _controller.reset();
    widget.onConfirmed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _onHoldStart(),
      onTapUp: (_) => _onHoldEnd(),
      onTapCancel: () => _onHoldEnd(),
      child: Stack(
        children: [
          // Background / Progress
          Container(
            height: 56,
            width: double.infinity,
            decoration: BoxDecoration(
              color: widget.isDisabled
                  ? Colors.grey[300]
                  : widget.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _controller.value,
                    child: Container(
                      color: widget.isDisabled
                          ? Colors.grey[400]
                          : widget.color.withOpacity(0.6),
                    ),
                  );
                },
              ),
            ),
          ),
          // Content
          Container(
            height: 56,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHolding ? widget.color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else ...[
                  Icon(
                    widget.icon,
                    color: widget.isDisabled ? Colors.grey[600] : Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: widget.isDisabled
                          ? Colors.grey[600]
                          : Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Base Color Layer (Solid when not holding)
          if (!_isHolding && !widget.isLoading)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.isDisabled ? Colors.grey[300] : widget.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.text,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Loading Indicator Overlay
          if (widget.isLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
