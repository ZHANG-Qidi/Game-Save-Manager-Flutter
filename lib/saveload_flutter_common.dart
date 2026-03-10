import 'package:flutter/material.dart';

class SmartTapWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onSingleTap;
  final VoidCallback onDoubleTap;
  final Duration doubleTapThreshold;
  const SmartTapWidget({
    super.key,
    required this.child,
    required this.onSingleTap,
    required this.onDoubleTap,
    this.doubleTapThreshold = const Duration(milliseconds: 300),
  });
  @override
  State<SmartTapWidget> createState() => _SmartTapWidgetState();
}

class _SmartTapWidgetState extends State<SmartTapWidget> {
  DateTime? _lastTapTime;
  void _handleTap() {
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!) <= widget.doubleTapThreshold) {
      widget.onDoubleTap();
    } else {
      widget.onSingleTap();
    }
    _lastTapTime = now;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(behavior: HitTestBehavior.translucent, onTap: _handleTap, child: widget.child);
  }
}
