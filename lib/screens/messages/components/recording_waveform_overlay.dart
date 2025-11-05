import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../ui_constants.dart';

class RecordingWaveformOverlay extends StatefulWidget {
  final List<double> decibels;
  final bool isRecording;

  const RecordingWaveformOverlay({
    super.key,
    required this.decibels,
    required this.isRecording,
  });

  @override
  State<RecordingWaveformOverlay> createState() =>
      _RecordingWaveformOverlayState();
}

class _RecordingWaveformOverlayState extends State<RecordingWaveformOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isRecording) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Container(
            width: 300,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: WaveformPainter(
                    decibels: widget.decibels,
                    color: primaryColor.withValues(alpha: 0.8),
                    animationValue: _animationController.value,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> decibels;
  final Color color;
  final double animationValue;

  WaveformPainter({
    required this.decibels,
    required this.color,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (decibels.isEmpty) {
      return;
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    final maxBarHeight = size.height * 0.8;

    // Number of bars to display
    const barCount = 50;
    final barWidth = size.width / barCount;
    final barSpacing = barWidth * 0.3;
    final actualBarWidth = barWidth - barSpacing;

    // Sample decibels to fit bar count
    final sampledDecibels = _sampleDecibels(decibels, barCount);

    for (int i = 0; i < sampledDecibels.length; i++) {
      final x = i * barWidth + barSpacing / 2;

      // Get amplitude (0.0 to 1.0)
      double amplitude = sampledDecibels[i];

      // Add slight animation pulse
      amplitude = amplitude * (0.9 + 0.1 * math.sin(animationValue * 2 * math.pi + i * 0.2));

      // Calculate bar height with minimum height for visual appeal
      final barHeight = math.max(4.0, amplitude * maxBarHeight);

      // Draw bar centered vertically
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x,
          centerY - barHeight / 2,
          actualBarWidth,
          barHeight,
        ),
        Radius.circular(actualBarWidth / 2),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  List<double> _sampleDecibels(List<double> decibels, int targetCount) {
    if (decibels.length <= targetCount) {
      // If we don't have enough samples, pad with zeros or repeat
      return List<double>.generate(targetCount, (index) {
        if (index < decibels.length) {
          return decibels[index];
        }
        return 0.1; // Minimum amplitude for empty bars
      });
    }

    // Sample evenly from the decibels list
    final result = <double>[];
    final step = decibels.length / targetCount;

    for (int i = 0; i < targetCount; i++) {
      final index = (i * step).floor();
      if (index < decibels.length) {
        result.add(decibels[index]);
      } else {
        result.add(0.1);
      }
    }

    return result;
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color ||
        !listEquals(oldDelegate.decibels, decibels);
  }
}
