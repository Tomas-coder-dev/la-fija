import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A premium circular progress ring with a star icon in the center.
/// Inspired by the Meta revenue wheel design.
class ProgressRingWidget extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final Color ringColor;
  final Color bgRingColor;
  final String centerLabel; // e.g. "75%"
  final String statusText; // e.g. "Falta S/ 200"
  final String cardName;   // e.g. "BCP Platinum VISA"
  final String penaltyText; // e.g. "Penalidad: S/ 350"
  final bool showPenalty;
  final double size;

  const ProgressRingWidget({
    super.key,
    required this.progress,
    required this.ringColor,
    this.bgRingColor = const Color(0xFF252540),
    required this.centerLabel,
    required this.statusText,
    required this.cardName,
    this.penaltyText = '',
    this.showPenalty = false,
    this.size = 220,
  });

  @override
  State<ProgressRingWidget> createState() => _ProgressRingWidgetState();
}

class _ProgressRingWidgetState extends State<ProgressRingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant ProgressRingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(begin: _animation.value, end: widget.progress).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Card name
        Text(
          widget.cardName,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        if (widget.showPenalty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
            ),
            child: Text(
              widget.penaltyText,
              style: GoogleFonts.inter(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (!widget.showPenalty) const SizedBox(height: 16),
        // The ring
        _AnimatedRing(
          animation: _animation,
          size: widget.size,
          ringColor: widget.ringColor,
          bgRingColor: widget.bgRingColor,
          centerLabel: widget.centerLabel,
        ),
        const SizedBox(height: 20),
        // Status text
        Text(
          widget.statusText,
          style: GoogleFonts.inter(
            color: widget.progress >= 1.0
                ? Colors.greenAccent
                : Colors.white60,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color bgRingColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.ringColor,
    required this.bgRingColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background ring
    final bgPaint = Paint()
      ..color = bgRingColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc with gradient
    final sweepAngle = 2 * pi * progress;
    if (sweepAngle <= 0) return;

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: -pi / 2 + sweepAngle,
        colors: [
          ringColor.withOpacity(0.7),
          ringColor,
          ringColor.withOpacity(0.9),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: const GradientRotation(-pi / 2),
      ).createShader(rect);

    canvas.drawArc(rect, -pi / 2, sweepAngle, false, progressPaint);

    // Glow dot at the end of the arc
    if (progress > 0.02) {
      final dotAngle = -pi / 2 + sweepAngle;
      final dotX = center.dx + radius * cos(dotAngle);
      final dotY = center.dy + radius * sin(dotAngle);

      // Outer glow
      final glowPaint = Paint()
        ..color = ringColor.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(dotX, dotY), strokeWidth * 0.6, glowPaint);

      // Inner dot
      final dotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(dotX, dotY), strokeWidth * 0.3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ringColor != ringColor;
  }
}

class _AnimatedRing extends AnimatedWidget {
  final double size;
  final Color ringColor;
  final Color bgRingColor;
  final String centerLabel;

  const _AnimatedRing({
    required Animation<double> animation,
    required this.size,
    required this.ringColor,
    required this.bgRingColor,
    required this.centerLabel,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: animation.value,
          ringColor: ringColor,
          bgRingColor: bgRingColor,
          strokeWidth: 18,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    ringColor,
                    ringColor.withOpacity(0.6),
                  ],
                ).createShader(bounds),
                child: const Icon(
                  Icons.star_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                centerLabel,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
