import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../providers/expenses_provider.dart';
import '../../providers/cards_provider.dart';
import '../../models/expense_category.dart';
import '../../models/bank_catalog.dart';

class ExpensesTab extends ConsumerStatefulWidget {
  const ExpensesTab({super.key});

  @override
  ConsumerState<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends ConsumerState<ExpensesTab> {
  String? _selectedCardId; // null means 'All'

  @override
  Widget build(BuildContext context) {
    final expensesState = ref.watch(expensesProvider);
    final cardsState = ref.watch(cardsProvider);
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
        
        // Horizontal Filter Chips
        if (cardsState.value != null && cardsState.value!.isNotEmpty)
          Container(
            height: 40,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildFilterChip('Todas', null, theme, isDark),
                ...cardsState.value!.map((c) {
                  return _buildFilterChip(
                    '${c.banco} ${c.nombreTarjeta}', 
                    c.id, 
                    theme, 
                    isDark, 
                    color: BankCatalog.getBankData(c.banco).primaryColor,
                  );
                }),
              ],
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
              
              var filteredExpenses = _selectedCardId == null 
                  ? expenses 
                  : expenses.where((e) => e.tarjetaId == _selectedCardId).toList();

              if (filteredExpenses.isEmpty) {
                return const Center(child: Text('No hay gastos para esta tarjeta.'));
              }

              final sortedExpenses = List.of(filteredExpenses)..sort((a, b) => b.fechaConsumo.compareTo(a.fechaConsumo));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8).copyWith(bottom: 100),
                itemCount: sortedExpenses.length,
                itemBuilder: (ctx, idx) {
                  final exp = sortedExpenses[idx];
                  final catData = ExpenseCategory.fromKey(exp.categoria);
                  
                  // Find card name to display if we are in "Todas" view
                  String? cardLabel;
                  Color? cardColor;
                  if (_selectedCardId == null && cardsState.value != null) {
                    try {
                      final card = cardsState.value!.firstWhere((c) => c.id == exp.tarjetaId);
                      cardLabel = '${card.banco} ${card.nombreTarjeta}';
                      cardColor = BankCatalog.getBankData(card.banco).primaryColor;
                    } catch (_) {}
                  }

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
                              Row(
                                children: [
                                  Text(
                                    DateFormat('dd MMM yyyy, HH:mm', 'es_PE').format(exp.fechaConsumo),
                                    style: GoogleFonts.inter(color: theme.textTheme.bodySmall?.color, fontSize: 12),
                                  ),
                                  if (cardLabel != null) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: cardColor ?? Colors.grey,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        cardLabel,
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  ]
                                ],
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

  Widget _buildFilterChip(String label, String? cardId, ThemeData theme, bool isDark, {Color? color}) {
    final isSelected = _selectedCardId == cardId;
    final activeColor = color ?? theme.colorScheme.primary;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCardId = cardId;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.15) : (isDark ? const Color(0xFF1E1E38) : Colors.grey[200]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: isSelected ? activeColor : theme.textTheme.bodyMedium?.color,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
