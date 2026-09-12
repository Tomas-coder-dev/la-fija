import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../providers/expenses_provider.dart';
import '../../models/expense_category.dart';

class AnalyticsTab extends ConsumerWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesState = ref.watch(expensesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFmt = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Text(
            'Resumen',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: theme.textTheme.bodyLarge?.color,
              letterSpacing: -0.5,
            ),
          ),
        ),
        
        Expanded(
          child: expensesState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (expenses) {
              if (expenses.isEmpty) {
                return Center(
                  child: Text(
                    'No hay suficientes datos para analíticas.',
                    style: GoogleFonts.inter(color: theme.textTheme.bodySmall?.color),
                  ),
                );
              }
              
              // Agrupar por categoría
              final Map<String, double> groupedByCategory = {};
              double total = 0;
              for (var exp in expenses) {
                groupedByCategory[exp.categoria] = (groupedByCategory[exp.categoria] ?? 0) + exp.monto;
                total += exp.monto;
              }

              final List<PieChartSectionData> pieSections = groupedByCategory.entries.map((entry) {
                final catData = ExpenseCategory.fromKey(entry.key);
                final percentage = (entry.value / total) * 100;
                
                return PieChartSectionData(
                  color: catData.color,
                  value: entry.value,
                  title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
                  radius: 60,
                  titleStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  badgeWidget: _Badge(catData.emoji, size: 24, borderColor: catData.color),
                  badgePositionPercentageOffset: .98,
                );
              }).toList();

              // Sort for the list below
              final sortedEntries = groupedByCategory.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24).copyWith(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tarjeta Principal - Total Gastado
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Gastado (Este Ciclo)',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currencyFmt.format(total),
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    Text(
                      'Distribución',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Gráfico de torta
                    SizedBox(
                      height: 220,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 50,
                          sections: pieSections,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Lista de detalles
                    ...sortedEntries.map((entry) {
                      final catData = ExpenseCategory.fromKey(entry.key);
                      final percentage = (entry.value / total) * 100;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E38) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isDark ? [] : [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                          ]
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: catData.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(catData.emoji, style: const TextStyle(fontSize: 24)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    catData.label,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${percentage.toStringAsFixed(1)}% del total',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              currencyFmt.format(entry.value),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(
    this.emoji, {
    required this.size,
    required this.borderColor,
  });
  final String emoji;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(.2),
            offset: const Offset(3, 3),
            blurRadius: 3,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * .15),
      child: Center(
        child: Text(emoji, style: TextStyle(fontSize: size * 0.5)),
      ),
    );
  }
}
