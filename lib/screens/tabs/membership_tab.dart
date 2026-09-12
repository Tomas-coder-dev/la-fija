import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/cards_provider.dart';
import '../../providers/expenses_provider.dart';
import '../../services/supabase_service.dart';
import '../../models/bank_catalog.dart';
import '../../widgets/progress_ring_widget.dart';

class MembershipTab extends ConsumerWidget {
  const MembershipTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cardsState = ref.watch(cardsProvider);
    final expensesState = ref.watch(expensesProvider);
    final supabaseService = ref.read(supabaseServiceProvider);

    if (cardsState.isLoading || expensesState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final cards = cardsState.value ?? [];
    final expenses = expensesState.value ?? [];

    if (cards.isEmpty) {
      return Center(
        child: Text(
          'Agrega una tarjeta para ver tu progreso de membresía.',
          style: GoogleFonts.inter(color: theme.textTheme.bodySmall?.color),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Membresía',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: theme.textTheme.bodyLarge?.color,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lleva el control para evitar pagos anuales.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.88),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              final bankData = BankCatalog.getBankData(card.banco);
              
              final isCountBased = card.exemptionType == 'count';
              
              final currentCycleExpenses = supabaseService.getCurrentCycleExpenses(card, expenses);
              final currentConsumption = supabaseService.getCurrentCycleConsumption(card, expenses);
              
              final targetValue = card.metaMensual;
              final currentValue = isCountBased ? currentCycleExpenses.length.toDouble() : currentConsumption;
              
              final progress = targetValue > 0 ? (currentValue / targetValue) : 1.0;
              final daysRemaining = supabaseService.getDaysUntilCycleEnd(card);
              final dailyNeeded = (targetValue - currentValue) > 0 && daysRemaining > 0
                  ? (targetValue - currentValue) / daysRemaining
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                child: ProgressRingWidget(
                  progress: progress,
                  ringColor: bankData.primaryColor,
                  secondaryColor: bankData.secondaryColor,
                  bgRingColor: theme.brightness == Brightness.dark ? const Color(0xFF1E1E38) : Colors.grey[200]!,
                  centerLabel: isCountBased 
                      ? '${currentCycleExpenses.length}/${targetValue.toInt()}' 
                      : '${(progress * 100).clamp(0, 100).toInt()}%',
                  statusText: progress >= 1.0 ? 'Meta Completada' : 'En progreso',
                  cardName: '${card.banco} ${card.nombreTarjeta}',
                  showPenalty: true,
                  penaltyText: 'Evita pagar S/ ${card.membershipFee}',
                  isStrictMonthly: bankData.isStrictMonthly,
                  daysRemaining: daysRemaining,
                  dailyNeeded: isCountBased ? 0 : dailyNeeded,
                  currentValue: currentValue,
                  targetValue: targetValue,
                  isCountBased: isCountBased,
                  membershipFee: card.membershipFee,
                  cycleEndDate: supabaseService.getCycleEndDate(card),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20), // Bottom spacing for navigation bar
      ],
    );
  }
}
