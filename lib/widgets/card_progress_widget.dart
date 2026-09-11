import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../models/credit_card.dart';

/// Widget de tarjeta que muestra el progreso de consumo respecto a la meta mensual.
class CardProgressWidget extends StatelessWidget {
  final CreditCard card;
  final double consumption;
  final NumberFormat currencyFormat;

  const CardProgressWidget({
    super.key,
    required this.card,
    required this.consumption,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (consumption / card.metaMensual).clamp(0.0, 1.0);
    final isGoalReached = consumption >= card.metaMensual;
    final remaining = card.metaMensual - consumption;

    final progressColor =
        isGoalReached ? Colors.green.shade400 : Colors.amber.shade600;
    final progressBgColor = isGoalReached
        ? Colors.green.withOpacity(0.12)
        : Colors.amber.withOpacity(0.10);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A2E),
            Colors.indigo.shade900.withOpacity(0.3),
          ],
        ),
        border: Border.all(
          color: Colors.indigo.withOpacity(0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado: Banco + Cierre ──────────────────────────
          Row(
            children: [
              // Icono banco
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Colors.indigo,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.banco,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      card.nombreTarjeta,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white54,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge de fecha de cierre
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Cierre día ${card.diaCierre}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Montos ───────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Consumido',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white38,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currencyFormat.format(consumption),
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Meta',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white38,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currencyFormat.format(card.metaMensual),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Barra de progreso ─────────────────────────────────────
          LinearPercentIndicator(
            percent: percent,
            lineHeight: 10,
            padding: EdgeInsets.zero,
            backgroundColor: progressBgColor,
            progressColor: progressColor,
            barRadius: const Radius.circular(8),
            animation: true,
            animationDuration: 800,
            curve: Curves.easeOut,
          ),
          const SizedBox(height: 12),

          // ── Estado del ciclo ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Porcentaje
              Text(
                '${(percent * 100).toStringAsFixed(0)}% de la meta',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white38,
                  fontWeight: FontWeight.w500,
                ),
              ),

              // Estado: falta / completado
              if (isGoalReached)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 12,
                        color: Colors.green.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '¡Meta alcanzada!',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.green.shade400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  'Faltan ${currencyFormat.format(remaining)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.amber.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
