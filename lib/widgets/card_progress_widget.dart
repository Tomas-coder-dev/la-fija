import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../models/bank_catalog.dart';
import '../models/credit_card.dart';

/// Widget de tarjeta que muestra el progreso de consumo respecto a la meta mensual.
/// Ahora con estilo de tarjeta física y logos de los bancos.
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
        isGoalReached ? Colors.greenAccent.shade400 : Colors.amberAccent.shade400;
    final progressBgColor = Colors.white.withOpacity(0.15);

    // Obtener los datos del banco del catálogo
    final bankData = BankCatalog.getBankData(card.banco);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: bankData.fallbackColors.first.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Capa 1: El fondo de gradiente por defecto
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: bankData.fallbackColors,
                ),
              ),
            ),
            // Capa 2: La imagen de la tarjeta (si está disponible y carga bien)
            if (bankData.cardImageUrl.isNotEmpty)
              Positioned.fill(
                child: Image.network(
                  bankData.cardImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  color: Colors.black.withOpacity(0.1), // Un pequeño filtro oscuro para que las letras resalten
                  colorBlendMode: BlendMode.darken,
                ),
              ),
          // Patrón o brillo de fondo sutil
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Encabezado: Logo + Banco + Cierre ────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo y Banco
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.network(
                            bankData.logoUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, err, stack) => const Icon(
                              Icons.account_balance,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.nombreTarjeta,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: bankData.textColor,
                              ),
                            ),
                            Text(
                              card.banco,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: bankData.textColor.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    // Badge de fecha de cierre
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Cierre: ${card.diaCierre}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: bankData.textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

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
                            fontSize: 12,
                            color: bankData.textColor.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currencyFormat.format(consumption),
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: bankData.textColor,
                            letterSpacing: -1.0,
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
                            color: bankData.textColor.withOpacity(0.7),
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
                            color: bankData.textColor.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Barra de progreso ─────────────────────────────────────
                LinearPercentIndicator(
                  percent: percent,
                  lineHeight: 8,
                  padding: EdgeInsets.zero,
                  backgroundColor: progressBgColor,
                  progressColor: progressColor,
                  barRadius: const Radius.circular(8),
                  animation: true,
                  animationDuration: 1000,
                  curve: Curves.easeOutCubic,
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
                        color: bankData.textColor.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    // Estado: falta / completado
                    if (isGoalReached)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.shade400.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: Colors.greenAccent.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '¡Alcanzada!',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.greenAccent.shade100,
                                fontWeight: FontWeight.w700,
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
                          color: Colors.amberAccent.shade100,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
