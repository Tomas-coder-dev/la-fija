import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../providers/expenses_provider.dart';
import '../../models/expense_category.dart';

class ExpensesTab extends ConsumerWidget {
  const ExpensesTab({super.key});

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
            'Historial de Gastos',
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
                return const Center(child: Text('No hay gastos registrados.'));
              }
              
              final sortedExpenses = List.of(expenses)..sort((a, b) => b.fechaConsumo.compareTo(a.fechaConsumo));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8).copyWith(bottom: 100),
                itemCount: sortedExpenses.length,
                itemBuilder: (ctx, idx) {
                  final exp = sortedExpenses[idx];
                  final catData = ExpenseCategory.fromKey(exp.categoria);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E38) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isDark ? [] : [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
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
                                  color: theme.textTheme.bodyLarge?.color,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                DateFormat('dd MMM yyyy, HH:mm', 'es_PE').format(exp.fechaConsumo),
                                style: GoogleFonts.inter(color: theme.textTheme.bodySmall?.color, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          currencyFmt.format(exp.monto),
                          style: GoogleFonts.inter(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
