import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/credit_card.dart';
import '../services/supabase_service.dart';

final supabaseServiceProvider = Provider((ref) => SupabaseService());

final cardsProvider = StateNotifierProvider<CardsNotifier, AsyncValue<List<CreditCard>>>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return CardsNotifier(service);
});

class CardsNotifier extends StateNotifier<AsyncValue<List<CreditCard>>> {
  final SupabaseService _service;

  CardsNotifier(this._service) : super(const AsyncValue.loading()) {
    loadCards();
  }

  Future<void> loadCards() async {
    state = const AsyncValue.loading();
    try {
      final cards = await _service.getCards();
      state = AsyncValue.data(cards);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCard({
    required String banco,
    required String nombreTarjeta,
    required int diaCierre,
    required int diaPago,
    required double metaMensual,
    required double limiteCredito,
    required double membershipFee,
    required String exemptionType,
    required double exemptionTarget,
  }) async {
    await _service.addCard(
      banco: banco,
      nombreTarjeta: nombreTarjeta,
      diaCierre: diaCierre,
      diaPago: diaPago,
      metaMensual: metaMensual,
      limiteCredito: limiteCredito,
      membershipFee: membershipFee,
      exemptionType: exemptionType,
      exemptionTarget: exemptionTarget,
    );
    await loadCards(); // Refresh
  }

  Future<void> updateCard({
    required String id,
    required String banco,
    required String nombreTarjeta,
    required int diaCierre,
    required int diaPago,
    required double metaMensual,
    required double limiteCredito,
    required double membershipFee,
    required String exemptionType,
    required double exemptionTarget,
  }) async {
    await _service.updateCard(
      id: id,
      banco: banco,
      nombreTarjeta: nombreTarjeta,
      diaCierre: diaCierre,
      diaPago: diaPago,
      metaMensual: metaMensual,
      limiteCredito: limiteCredito,
      membershipFee: membershipFee,
      exemptionType: exemptionType,
      exemptionTarget: exemptionTarget,
    );
    await loadCards(); // Refresh
  }

  Future<void> deleteCard(String id) async {
    await _service.deleteCard(id);
    await loadCards();
  }

  void reorderCards(int oldIndex, int newIndex) {
    if (state.value == null) return;
    
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    
    final items = List<CreditCard>.from(state.value!);
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    
    state = AsyncValue.data(items);
    // Note: If you want to persist the order, you'd need an 'order_index' column in Supabase
    // and update it here. For now, it reorders locally for the session.
  }
}
