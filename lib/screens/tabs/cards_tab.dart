import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/cards_provider.dart';
import '../../providers/expenses_provider.dart';
import '../../widgets/card_progress_widget.dart';
import '../../services/supabase_service.dart';
import '../../models/credit_card.dart';
import '../../widgets/modals/card_detail_modal.dart';

class CardsTab extends ConsumerWidget {
  const CardsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsState = ref.watch(cardsProvider);
    final expensesState = ref.watch(expensesProvider);
    final supabaseService = ref.read(supabaseServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mis Tarjetas',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              IconButton(
                icon: Icon(Icons.sort_rounded, color: Theme.of(context).iconTheme.color),
                onPressed: () {
                  // Todo: Add sorting logic if needed
                },
              ),
            ],
          ),
        ),
        
        Expanded(
          child: cardsState.when(
            loading: () => _buildShimmerLoading(context),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (cards) {
              if (cards.isEmpty) {
                return const Center(child: Text('No tienes tarjetas registradas.'));
              }
              
              return RefreshIndicator(
                onRefresh: () async {
                  await ref.read(cardsProvider.notifier).loadCards();
                  await ref.read(expensesProvider.notifier).loadAllExpenses();
                },
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8).copyWith(bottom: 100),
                  itemCount: cards.length,
                  onReorder: (oldIndex, newIndex) {
                    ref.read(cardsProvider.notifier).reorderCards(oldIndex, newIndex);
                  },
                  itemBuilder: (ctx, index) {
                    final card = cards[index];
                    
                    // Calculamos consumo actual si los expenses están cargados
                    double consumption = 0.0;
                    if (expensesState.value != null) {
                      consumption = supabaseService.getCurrentCycleConsumption(card, expensesState.value!);
                    }
                    
                    final daysRemaining = supabaseService.getDaysUntilCycleEnd(card);
                    
                    return Padding(
                      key: ValueKey(card.id),
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: CardProgressWidget(
                        card: card,
                        consumption: consumption,
                        currencyFormat: NumberFormat.currency(locale: 'en_US', symbol: 'S/ '),
                        daysRemaining: daysRemaining,
                        onTap: () {
                          showCardDetailModal(context, card, ref);
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerLoading(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[850]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: 3,
      itemBuilder: (_, __) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 20,
                  width: 150,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 15,
                  width: 100,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
