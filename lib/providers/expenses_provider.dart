import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../services/supabase_service.dart';
import 'cards_provider.dart';

final expensesProvider = StateNotifierProvider<ExpensesNotifier, AsyncValue<List<Expense>>>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return ExpensesNotifier(service);
});

class ExpensesNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  final SupabaseService _service;

  ExpensesNotifier(this._service) : super(const AsyncValue.loading()) {
    loadAllExpenses();
  }

  Future<void> loadAllExpenses() async {
    state = const AsyncValue.loading();
    try {
      final expenses = await _service.getAllExpenses();
      state = AsyncValue.data(expenses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addExpense({
    required String tarjetaId,
    required double monto,
    required String categoria,
  }) async {
    await _service.addExpense(
      tarjetaId: tarjetaId,
      monto: monto,
      categoria: categoria,
    );
    await loadAllExpenses();
  }

  Future<void> deleteExpense(String id) async {
    await _service.deleteExpense(id);
    await loadAllExpenses();
  }
}
