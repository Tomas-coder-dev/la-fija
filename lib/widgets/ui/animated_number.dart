import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AnimatedNumber extends StatelessWidget {
  final double value;
  final TextStyle style;
  final String prefix;
  final NumberFormat formatter;
  final Duration duration;

  const AnimatedNumber({
    super.key,
    required this.value,
    required this.style,
    required this.formatter,
    this.prefix = '',
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        return Text(
          '$prefix${formatter.format(val)}',
          style: style,
        );
      },
    );
  }
}
