import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  const RingPainter({required this.progress, this.strokeWidth = 16});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    const startAngle = -math.pi / 2;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.ringTrack
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    final sweepAngle = 2 * math.pi * progress;

    // Soft glow behind the arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..strokeCap = StrokeCap.round,
    );

    // Main arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Bright tip dot
    final endX = center.dx + radius * math.cos(startAngle + sweepAngle);
    final endY = center.dy + radius * math.sin(startAngle + sweepAngle);
    canvas.drawCircle(
      Offset(endX, endY),
      strokeWidth / 2,
      Paint()..color = AppColors.accent,
    );
  }

  @override
  bool shouldRepaint(RingPainter old) => old.progress != progress;
}