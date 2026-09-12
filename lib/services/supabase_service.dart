import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/credit_card.dart';
import '../models/expense.dart';
import 'local_storage_service.dart';

/// Servicio principal para interactuar con la base de datos de Supabase.
/// Asume que el usuario está autenticado y que las tablas `tarjetas` y `gastos`
/// tienen Row-Level Security (RLS) activo, filtrando por el usuario actual.
class SupabaseService {
  final _client = Supabase.instance.client;
  final _localService = LocalStorageService();

  // ─────────────────────────────────────────
  // TARJETAS
  // ─────────────────────────────────────────

  /// Obtiene todas las tarjetas del usuario autenticado.
  Future<List<CreditCard>> getCards() async {
    try {
      final response = await _client.from('tarjetas').select();
      final cards = (response as List)
          .map((json) => CreditCard.fromJson(json as Map<String, dynamic>))
          .toList();
      _localService.saveCardsLocally(cards);
      return cards;
    } catch (e) {
      // Fallback a caché local
      return _localService.getLocalCards();
    }
  }

  /// Inserta una nueva tarjeta en la tabla `tarjetas`.
  Future<void> addCard({
    required String banco,
    required String nombreTarjeta,
    required int diaCierre,
    required int diaPago,
    required double metaMensual, // Legacy
    required double limiteCredito,
    required double membershipFee,
    required String exemptionType,
    required double exemptionTarget,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    await _client.from('tarjetas').insert({
      'user_id': user.id,
      'banco': banco,
      'nombre_tarjeta': nombreTarjeta,
      'dia_cierre': diaCierre,
      'dia_pago': diaPago,
      'meta_mensual': metaMensual,
      'limite_credito': limiteCredito,
      'membership_fee': membershipFee,
      'exemption_type': exemptionType,
      'exemption_target': exemptionTarget,
    });
  }

  /// Elimina una tarjeta y sus gastos asociados.
  Future<void> deleteCard(String cardId) async {
    await _client.from('gastos').delete().eq('tarjeta_id', cardId);
    await _client.from('tarjetas').delete().eq('id', cardId);
  }

  /// Actualiza una tarjeta existente.
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
    await _client.from('tarjetas').update({
      'banco': banco,
      'nombre_tarjeta': nombreTarjeta,
      'dia_cierre': diaCierre,
      'dia_pago': diaPago,
      'meta_mensual': metaMensual,
      'limite_credito': limiteCredito,
      'membership_fee': membershipFee,
      'exemption_type': exemptionType,
      'exemption_target': exemptionTarget,
    }).eq('id', id);
  }

  // ─────────────────────────────────────────
  // GASTOS
  // ─────────────────────────────────────────

  /// Obtiene todos los gastos asociados a una tarjeta específica.
  Future<List<Expense>> getExpensesByCard(String cardId) async {
    try {
      final response = await _client
          .from('gastos')
          .select()
          .eq('tarjeta_id', cardId);
      final expenses = (response as List)
          .map((json) => Expense.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Update this specific card's expenses in the local storage
      // In a real app we might fetch ALL expenses at once to cache them properly,
      // but for now we'll just cache whatever we fetch.
      return expenses;
    } catch (e) {
      final allLocal = _localService.getLocalExpenses();
      return allLocal.where((ex) => ex.tarjetaId == cardId).toList();
    }
  }
  
  /// Obtiene TODOS los gastos de todas las tarjetas para cache.
  Future<List<Expense>> getAllExpenses() async {
    try {
      final response = await _client.from('gastos').select();
      final expenses = (response as List)
          .map((json) => Expense.fromJson(json as Map<String, dynamic>))
          .toList();
      _localService.saveExpensesLocally(expenses);
      return expenses;
    } catch (e) {
      return _localService.getLocalExpenses();
    }
  }

  /// Inserta un nuevo gasto en la tabla `gastos`.
  Future<void> addExpense({
    required String tarjetaId,
    required double monto,
    String categoria = 'otros',
  }) async {
    await _client.from('gastos').insert({
      'tarjeta_id': tarjetaId,
      'monto': monto,
      'fecha_consumo': DateTime.now().toUtc().toIso8601String(),
      'categoria': categoria,
    });
  }

  /// Elimina un gasto por su ID.
  Future<void> deleteExpense(String expenseId) async {
    await _client.from('gastos').delete().eq('id', expenseId);
  }

  // ─────────────────────────────────────────
  // MOTOR DEL CICLO DE FACTURACIÓN
  // ─────────────────────────────────────────

  /// Obtiene los gastos dentro del ciclo de facturación ACTUAL.
  List<Expense> getCurrentCycleExpenses(
    CreditCard card,
    List<Expense> expenses,
  ) {
    final today = DateTime.now();
    final diaCierre = card.diaCierre;

    late DateTime cycleStart;
    late DateTime cycleEnd;

    if (today.day > diaCierre) {
      cycleStart = DateTime(today.year, today.month, diaCierre + 1);
      final nextMonth = DateTime(today.year, today.month + 1);
      cycleEnd = DateTime(nextMonth.year, nextMonth.month, diaCierre, 23, 59, 59);
    } else {
      final prevMonth = DateTime(today.year, today.month - 1);
      cycleStart = DateTime(prevMonth.year, prevMonth.month, diaCierre + 1);
      cycleEnd = DateTime(today.year, today.month, diaCierre, 23, 59, 59);
    }

    return expenses
        .where((e) =>
            e.tarjetaId == card.id &&
            !e.fechaConsumo.isBefore(cycleStart) &&
            !e.fechaConsumo.isAfter(cycleEnd))
        .toList();
  }

  /// Obtiene la fecha de finalización del ciclo actual.
  DateTime getCycleEndDate(CreditCard card) {
    final today = DateTime.now();
    final diaCierre = card.diaCierre;

    if (today.day > diaCierre) {
      final nextMonth = DateTime(today.year, today.month + 1);
      return DateTime(nextMonth.year, nextMonth.month, diaCierre, 23, 59, 59);
    } else {
      return DateTime(today.year, today.month, diaCierre, 23, 59, 59);
    }
  }

  /// Calcula los días restantes hasta el final del ciclo actual.
  int getDaysUntilCycleEnd(CreditCard card) {
    final cycleEnd = getCycleEndDate(card);
    final today = DateTime.now();
    return cycleEnd.difference(today).inDays;
  }

  /// Calcula el consumo total dentro del ciclo de facturación ACTUAL
  /// basándose en el [dia_cierre] de la tarjeta y la fecha de hoy.
  ///
  /// Regla:
  /// - Si hoy > dia_cierre → el ciclo va desde (dia_cierre+1 del mes actual)
  ///   hasta (dia_cierre del mes siguiente).
  /// - Si hoy <= dia_cierre → el ciclo va desde (dia_cierre+1 del mes anterior)
  ///   hasta (dia_cierre del mes actual).
  double getCurrentCycleConsumption(
    CreditCard card,
    List<Expense> expenses,
  ) {
    final today = DateTime.now();
    final diaCierre = card.diaCierre;

    late DateTime cycleStart;
    late DateTime cycleEnd;

    if (today.day > diaCierre) {
      // Ciclo actual: desde el día siguiente al cierre de ESTE mes
      //               hasta el día de cierre del MES SIGUIENTE
      cycleStart = DateTime(today.year, today.month, diaCierre + 1);
      final nextMonth = DateTime(today.year, today.month + 1);
      cycleEnd = DateTime(nextMonth.year, nextMonth.month, diaCierre, 23, 59, 59);
    } else {
      // Ciclo actual: desde el día siguiente al cierre del MES PASADO
      //               hasta el día de cierre de ESTE mes
      final prevMonth = DateTime(today.year, today.month - 1);
      cycleStart = DateTime(prevMonth.year, prevMonth.month, diaCierre + 1);
      cycleEnd = DateTime(today.year, today.month, diaCierre, 23, 59, 59);
    }

    return expenses
        .where((e) =>
            e.tarjetaId == card.id &&
            !e.fechaConsumo.isBefore(cycleStart) &&
            !e.fechaConsumo.isAfter(cycleEnd))
        .fold(0.0, (sum, e) => sum + e.monto);
  }

  /// Calcula la cantidad de consumos (transacciones) dentro del ciclo de facturación ACTUAL.
  int getCurrentCycleExpenseCount(
    CreditCard card,
    List<Expense> expenses,
  ) {
    final today = DateTime.now();
    final diaCierre = card.diaCierre;

    late DateTime cycleStart;
    late DateTime cycleEnd;

    if (today.day > diaCierre) {
      cycleStart = DateTime(today.year, today.month, diaCierre + 1);
      final nextMonth = DateTime(today.year, today.month + 1);
      cycleEnd = DateTime(nextMonth.year, nextMonth.month, diaCierre, 23, 59, 59);
    } else {
      final prevMonth = DateTime(today.year, today.month - 1);
      cycleStart = DateTime(prevMonth.year, prevMonth.month, diaCierre + 1);
      cycleEnd = DateTime(today.year, today.month, diaCierre, 23, 59, 59);
    }

    return expenses
        .where((e) =>
            e.tarjetaId == card.id &&
            !e.fechaConsumo.isBefore(cycleStart) &&
            !e.fechaConsumo.isAfter(cycleEnd))
        .length;
  }
}
