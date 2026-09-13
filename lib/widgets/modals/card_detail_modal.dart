import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/bank_catalog.dart';
import '../../models/credit_card.dart';
import '../../models/expense_category.dart';
import '../../providers/cards_provider.dart';
import '../../providers/expenses_provider.dart';
import '../../services/supabase_service.dart';
import '../ui/custom_toast.dart';
import 'add_card_modal.dart';

void showCardDetailModal(BuildContext context, CreditCard card, WidgetRef ref) {
  final supabaseService = ref.read(supabaseServiceProvider);
  final expensesState = ref.read(expensesProvider);
  final allExpenses = expensesState.value ?? [];
  final cycleExpenses =
      supabaseService.getCurrentCycleExpenses(card, allExpenses);
  cycleExpenses.sort((a, b) => b.fechaConsumo.compareTo(a.fechaConsumo));

  final currencyFmt = NumberFormat.currency(locale: 'en_US', symbol: 'S/ ');
  final totalCycleSpent =
      supabaseService.getCurrentCycleConsumption(card, allExpenses);
  final daysRemaining = supabaseService.getDaysUntilCycleEnd(card);
  final bankData = BankCatalog.getBankData(card.banco);

  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: MediaQuery.of(ctx).size.height * 0.85,
            decoration: BoxDecoration(
              color:
                  theme.dialogBackgroundColor.withOpacity(isDark ? 0.85 : 0.95),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Hero(
                    tag: 'card_hero_${card.id}',
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              bankData.primaryColor,
                              bankData.secondaryColor
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: bankData.primaryColor.withOpacity(0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.credit_card_rounded,
                                color: Colors.white, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${card.banco} · ${card.nombreTarjeta}',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(6)),
                                        child: Text(
                                            'Límite: ${currencyFmt.format(card.limiteCredito)}',
                                            style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(6)),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.event_rounded,
                                                color: Colors.white, size: 12),
                                            const SizedBox(width: 4),
                                            Text('Cierra día ${card.diaCierre}',
                                                style: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                  icon: const Icon(Icons.edit_rounded,
                                      color: Colors.white70, size: 20),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.pop(ctx);
                                    showAddCardModal(context, cardToEdit: card);
                                  },
                                ),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      color: Colors.white70, size: 20),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.pop(ctx);
                                    _showDeleteCardConfirmation(
                                        context, card, ref);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E38)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Gastado en ciclo',
                                  style: GoogleFonts.inter(
                                      color: theme.textTheme.bodySmall?.color,
                                      fontSize: 11)),
                              const SizedBox(height: 4),
                              Text(currencyFmt.format(totalCycleSpent),
                                  style: GoogleFonts.inter(
                                      color: theme.textTheme.bodyLarge?.color,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E38)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Días de ciclo',
                                  style: GoogleFonts.inter(
                                      color: theme.textTheme.bodySmall?.color,
                                      fontSize: 11)),
                              const SizedBox(height: 4),
                              Text('$daysRemaining días restantes',
                                  style: GoogleFonts.inter(
                                      color: theme.colorScheme.primary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Gastos del ciclo actual (${cycleExpenses.length})',
                        style: GoogleFonts.inter(
                          color: theme.textTheme.bodyLarge?.color,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Desliza para borrar',
                        style: GoogleFonts.inter(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: cycleExpenses.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(24),
                            alignment: Alignment.center,
                            child: Text(
                              'No hay gastos registrados en este ciclo.',
                              style: GoogleFonts.inter(
                                  color: theme.textTheme.bodySmall?.color,
                                  fontSize: 13),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: cycleExpenses.length,
                            itemBuilder: (c, idx) {
                              final exp = cycleExpenses[idx];
                              final catData =
                                  ExpenseCategory.fromKey(exp.categoria);

                              return Dismissible(
                                key: Key(exp.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.delete_rounded,
                                      color: Colors.white),
                                ),
                                onDismissed: (_) async {
                                  HapticFeedback.lightImpact();
                                  await ref
                                      .read(expensesProvider.notifier)
                                      .deleteExpense(exp.id);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E1E38)
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color:
                                              catData.color.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Center(
                                          child: Text(catData.emoji,
                                              style: const TextStyle(
                                                  fontSize: 16)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              catData.label,
                                              style: GoogleFonts.inter(
                                                color: theme
                                                    .textTheme.bodyLarge?.color,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              DateFormat(
                                                      'dd MMM, HH:mm', 'es_PE')
                                                  .format(exp.fechaConsumo),
                                              style: GoogleFonts.inter(
                                                  color: theme.textTheme
                                                      .bodySmall?.color,
                                                  fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        currencyFmt.format(exp.monto),
                                        style: GoogleFonts.inter(
                                          color:
                                              theme.textTheme.bodyLarge?.color,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

void _showDeleteCardConfirmation(
    BuildContext context, CreditCard card, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('¿Eliminar tarjeta?'),
      content: Text(
          'Se eliminará "${card.banco} ${card.nombreTarjeta}" y todos sus gastos.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
          onPressed: () async {
            Navigator.pop(ctx);
            await ref.read(cardsProvider.notifier).deleteCard(card.id);
            if (context.mounted) {
              CustomToast.show(context, 'Tarjeta eliminada');
            }
          },
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
}
