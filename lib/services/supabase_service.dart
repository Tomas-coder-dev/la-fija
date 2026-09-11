import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/credit_card.dart';
import '../models/expense.dart';

/// Servicio principal para interactuar con la base de datos de Supabase.
/// Asume que el usuario está autenticado y que las tablas `tarjetas` y `gastos`
/// tienen Row-Level Security (RLS) activo, filtrando por el usuario actual.
class SupabaseService {
  final _client = Supabase.instance.client;

  // ─────────────────────────────────────────
  // TARJETAS
  // ─────────────────────────────────────────

  /// Obtiene todas las tarjetas del usuario autenticado.
  Future<List<CreditCard>> getCards() async {
    final response = await _client.from('tarjetas').select();
    return (response as List)
        .map((json) => CreditCard.fromJson(json as Map<String, dynamic>))
        .toList();
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

  // ─────────────────────────────────────────
  // GASTOS
  // ─────────────────────────────────────────

  /// Obtiene todos los gastos asociados a una tarjeta específica.
  Future<List<Expense>> getExpensesByCard(String cardId) async {
    final response = await _client
        .from('gastos')
        .select()
        .eq('tarjeta_id', cardId);
    return (response as List)
        .map((json) => Expense.fromJson(json as Map<String, dynamic>))
        .toList();
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

  // ─────────────────────────────────────────
  // MOTOR DEL CICLO DE FACTURACIÓN
  // ─────────────────────────────────────────

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
