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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Text(
            'Analíticas',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        ),
        
        Expanded(
          child: expensesState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (expenses) {
              if (expenses.isEmpty) {
                return const Center(child: Text('No hay suficientes datos para analíticas.'));
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
                  title: '${percentage.toStringAsFixed(0)}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24).copyWith(bottom: 100),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E38) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isDark ? [] : [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                        ]
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Distribución de Gastos',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                sections: pieSections,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ...groupedByCategory.entries.map((entry) {
                            final catData = ExpenseCategory.fromKey(entry.key);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: catData.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    catData.label,
                                    style: GoogleFonts.inter(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
                                  ),
                                  const Spacer(),
                                  Text(
                                    NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ').format(entry.value),
                                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
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
