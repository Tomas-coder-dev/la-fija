import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'ui/animated_number.dart';

/// Un widget de progreso dinámico para la pestaña de Membresía.
/// Soporta dos diseños visuales distintos:
/// 1. Tarjetas Estrictas (CMR, Interbank): Enfoque en urgencia, countdown destacado, barra horizontal y gasto diario requerido.
/// 2. Tarjetas Flexibles (BBVA, BCP): Anillo circular elegante, ritmo relajado e información clara.
class ProgressRingWidget extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final Color ringColor;
  final Color secondaryColor;
  final Color bgRingColor;
  final String centerLabel;
  final String statusText;
  final String cardName;
  final String penaltyText;
  final bool showPenalty;
  final double size;

  final bool isStrictMonthly;
  final int daysRemaining;
  final DateTime? cycleEndDate;
  final double dailyNeeded;
  final double currentValue;
  final double targetValue;
  final bool isCountBased;
  final double membershipFee;

  const ProgressRingWidget({
    super.key,
    required this.progress,
    required this.ringColor,
    this.secondaryColor = const Color(0xFF6366F1),
    this.bgRingColor = const Color(0xFF252540),
    required this.centerLabel,
    required this.statusText,
    required this.cardName,
    this.penaltyText = '',
    this.showPenalty = false,
    this.size = 200,
    this.isStrictMonthly = false,
    this.daysRemaining = 30,
    this.cycleEndDate,
    this.dailyNeeded = 0.0,
    this.currentValue = 0.0,
    this.targetValue = 0.0,
    this.isCountBased = false,
    this.membershipFee = 0.0,
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
    _animation = Tween<double>(begin: 0, end: widget.progress.clamp(0.0, 1.0))
        .animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant ProgressRingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
              begin: _animation.value, end: widget.progress.clamp(0.0, 1.0))
          .animate(
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

  Color _getCountdownColor(int days) {
    if (days > 15) return const Color(0xFF10B981); // Verde suave
    if (days >= 10) return const Color(0xFFFBBF24); // Amarillo
    if (days >= 5) return const Color(0xFFF97316); // Naranja
    return const Color(0xFFEF4444); // Rojo urgente
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isStrictMonthly) {
      return _buildStrictLayout();
    }
    return _buildFlexibleLayout();
  }

  /// ─────────────────────────────────────────
  /// DISEÑO 1: TARJETAS ESTRICTAS (CMR / INTERBANK)
  /// ─────────────────────────────────────────
  Widget _buildStrictLayout() {
    final countdownColor = _getCountdownColor(widget.daysRemaining);
    final currencyFmt = NumberFormat.currency(locale: 'en_US', symbol: 'S/ ');
    final dateFmt = widget.cycleEndDate != null
        ? DateFormat('dd/MM').format(widget.cycleEndDate!)
        : '--/--';
    final isCompleted = widget.progress >= 1.0;
    final remainingAmount = (widget.targetValue - widget.currentValue).clamp(0.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E30),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.ringColor.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.ringColor.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Card Name + Strict Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.cardName,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt, color: Colors.redAccent, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'MENSUAL VITAL',
                      style: GoogleFonts.inter(
                        color: Colors.redAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Countdown Chip Prominente
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: countdownColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: countdownColor.withOpacity(0.5), width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer, color: countdownColor, size: 20),
                const SizedBox(width: 8),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                    children: [
                      const TextSpan(text: 'Quedan '),
                      TextSpan(
                        text: '${widget.daysRemaining} días ',
                        style: TextStyle(
                          color: countdownColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      TextSpan(text: 'de ciclo (cierra el $dateFmt)'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Horizontal Progress Bar Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progreso del mes',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(widget.progress * 100).toInt()}%',
                style: GoogleFonts.inter(
                  color: widget.ringColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Custom Horizontal Animated Progress Bar
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Stack(
                children: [
                  Container(
                    height: 22,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: _animation.value.clamp(0.0, 1.0),
                    child: Container(
                      height: 22,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.ringColor.withOpacity(0.8),
                            widget.secondaryColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: widget.ringColor.withOpacity(0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // Numbers Summary Block
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: -2,
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gastado', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Text(
                        widget.isCountBased ? '${widget.currentValue.toInt()} compras' : currencyFmt.format(widget.currentValue),
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                Container(width: 1.5, height: 40, color: Colors.white.withOpacity(0.1)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isCompleted ? 'Estado' : 'Falta', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Text(
                        isCompleted
                            ? '¡Exonerado! 🎉'
                            : (widget.isCountBased ? '${remainingAmount.toInt()} compra' : currencyFmt.format(remainingAmount)),
                        style: GoogleFonts.inter(
                          color: isCompleted ? const Color(0xFF10B981) : Colors.amber.shade300,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Pace Action Card (Gasta ~S/ X por día)
          if (!isCompleted && widget.dailyNeeded > 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.ringColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: widget.ringColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.ringColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.speed_rounded, color: widget.ringColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ritmo diario sugerido',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          'Gasta ~${currencyFmt.format(widget.dailyNeeded)} por día',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else if (isCompleted)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '¡Excelente! Cumpliste la meta de este mes.',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF10B981),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Penalty Banner
          if (widget.showPenalty && widget.membershipFee > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1520),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Evita la penalidad anual de ${currencyFmt.format(widget.membershipFee)}',
                      style: GoogleFonts.inter(
                        color: Colors.redAccent.shade100,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// ─────────────────────────────────────────
  /// DISEÑO 2: TARJETAS FLEXIBLES (BBVA / BCP)
  /// ─────────────────────────────────────────
  Widget _buildFlexibleLayout() {
    final countdownColor = _getCountdownColor(widget.daysRemaining);
    final dateFmt = widget.cycleEndDate != null
        ? DateFormat('dd/MM').format(widget.cycleEndDate!)
        : '--/--';
    final currencyFmt = NumberFormat.currency(locale: 'en_US', symbol: 'S/ ');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Card Name
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            widget.cardName,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),

        // Flexible Chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.ringColor.withOpacity(0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.ringColor.withOpacity(0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.published_with_changes_rounded, color: Colors.white.withOpacity(0.9), size: 16),
              const SizedBox(width: 6),
              Text(
                'META FLEXIBLE / PROMEDIO',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Countdown Subtitle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: countdownColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '🗓️ Cierra $dateFmt (${widget.daysRemaining} días restantes)',
            style: GoogleFonts.inter(
              color: countdownColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // The Ring
        _AnimatedRing(
          animation: _animation,
          size: widget.size,
          ringColor: widget.ringColor,
          secondaryColor: widget.secondaryColor,
          bgRingColor: widget.bgRingColor,
          centerLabel: widget.centerLabel,
        ),

        const SizedBox(height: 16),

        // Status text (Glassmorphism)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.ringColor.withOpacity(0.15),
                Colors.black.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.ringColor.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: -2,
              )
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Gastado: ', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                  AnimatedNumber(
                    value: widget.currentValue,
                    formatter: currencyFmt,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  Text(' / ', style: GoogleFonts.inter(color: Colors.white30, fontSize: 14)),
                  AnimatedNumber(
                    value: widget.targetValue,
                    formatter: currencyFmt,
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Falta: ', style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                  Text(currencyFmt.format((widget.targetValue - widget.currentValue).clamp(0.0, double.infinity)), 
                    style: GoogleFonts.inter(
                      color: widget.progress >= 1.0 ? const Color(0xFF10B981) : Colors.amber.shade300,
                      fontSize: 18, 
                      fontWeight: FontWeight.w900
                    )
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Vas bien. Puedes compensar consumo en los siguientes meses.',
          style: GoogleFonts.inter(
            color: Colors.white54,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),

        if (widget.showPenalty && widget.membershipFee > 0) ...[
          const SizedBox(height: 12),
          Text(
            'Membresía anual: ${currencyFmt.format(widget.membershipFee)}',
            style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color secondaryColor;
  final Color bgRingColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.ringColor,
    required this.secondaryColor,
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
          ringColor,
          secondaryColor,
          ringColor,
        ],
        stops: const [0.0, 0.7, 1.0],
        transform: const GradientRotation(-pi / 2),
      ).createShader(rect);

    canvas.drawArc(rect, -pi / 2, sweepAngle, false, progressPaint);

    // Glow dot at the end of the arc
    if (progress > 0.02) {
      final dotAngle = -pi / 2 + sweepAngle;
      final dotX = center.dx + radius * cos(dotAngle);
      final dotY = center.dy + radius * sin(dotAngle);

      final glowPaint = Paint()
        ..color = ringColor.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(dotX, dotY), strokeWidth * 0.6, glowPaint);

      final dotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(dotX, dotY), strokeWidth * 0.3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}

class _AnimatedRing extends AnimatedWidget {
  final double size;
  final Color ringColor;
  final Color secondaryColor;
  final Color bgRingColor;
  final String centerLabel;

  const _AnimatedRing({
    required Animation<double> animation,
    required this.size,
    required this.ringColor,
    required this.secondaryColor,
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
          secondaryColor: secondaryColor,
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
                    secondaryColor,
                  ],
                ).createShader(bounds),
                child: const Icon(
                  Icons.star_rounded,
                  size: 38,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                centerLabel,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
