import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../providers/expenses_provider.dart';
import '../../providers/cards_provider.dart';
import '../../models/expense_category.dart';
import '../../models/bank_catalog.dart';
import '../../models/credit_card.dart';

class AnalyticsTab extends ConsumerStatefulWidget {
  const AnalyticsTab({super.key});

  @override
  ConsumerState<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends ConsumerState<AnalyticsTab> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expensesState = ref.watch(expensesProvider);
    final cardsState = ref.watch(cardsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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

        // Page Indicator
        if (cardsState.value != null && cardsState.value!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(cardsState.value!.length + 1, (index) {
                final isActive = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: isActive ? 24 : 6,
                  decoration: BoxDecoration(
                    color: isActive ? theme.colorScheme.primary : (isDark ? Colors.white24 : Colors.black12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),

        Expanded(
          child: expensesState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (allExpenses) {
              final cards = cardsState.value ?? [];
              
              if (allExpenses.isEmpty) {
                return Center(
                  child: Text(
                    'No hay suficientes datos para analíticas.',
                    style: GoogleFonts.inter(color: theme.textTheme.bodySmall?.color),
                  ),
                );
              }

              return PageView.builder(
                controller: _pageController,
                onPageChanged: (idx) {
                  setState(() {
                    _currentPage = idx;
                  });
                },
                itemCount: cards.length + 1, // +1 for "General" view
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildAnalyticsPage(context, null, allExpenses, theme, isDark);
                  } else {
                    final card = cards[index - 1];
                    final cardExpenses = allExpenses.where((e) => e.tarjetaId == card.id).toList();
                    return _buildAnalyticsPage(context, card, cardExpenses, theme, isDark);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsPage(BuildContext context, CreditCard? card, List expenses, ThemeData theme, bool isDark) {
    final currencyFmt = NumberFormat.currency(locale: 'en_US', symbol: 'S/ ');
    
    if (expenses.isEmpty) {
      return Center(
        child: Text(
          card == null ? 'No hay gastos registrados.' : 'No hay gastos para ${card.nombreTarjeta}.',
          style: GoogleFonts.inter(color: theme.textTheme.bodySmall?.color),
        ),
      );
    }
    
    final Map<String, double> groupedByCategory = {};
    double total = 0;
    for (var exp in expenses) {
      groupedByCategory[exp.categoria] = (groupedByCategory[exp.categoria] ?? 0) + exp.monto;
      total += exp.monto;
    }

    final sortedEntries = groupedByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    String titleText = 'Total Gastado (Este Ciclo)';
    Color cardColor1 = theme.colorScheme.primary;
    Color cardColor2 = theme.colorScheme.secondary;
    
    if (card != null) {
      final bData = BankCatalog.getBankData(card.banco);
      titleText = 'Gastado en ${bData.name} ${card.nombreTarjeta}';
      cardColor1 = bData.primaryColor;
      cardColor2 = bData.secondaryColor;
    }

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
                colors: [cardColor1, cardColor2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: cardColor1.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleText,
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
          
          // Lista de detalles con barras horizontales
          ...sortedEntries.map((entry) {
            final catData = ExpenseCategory.fromKey(entry.key);
            final percentage = (entry.value / total) * 100;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: catData.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(catData.emoji, style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          catData.label,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      Text(
                        currencyFmt.format(entry.value),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white12 : Colors.black12,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: percentage / 100,
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: catData.color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
