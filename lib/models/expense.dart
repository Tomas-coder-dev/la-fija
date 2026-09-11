/// Modelo que mapea la tabla `gastos` en Supabase.
class Expense {
  final String id;
  final String tarjetaId;
  final double monto;
  final DateTime fechaConsumo;
  final String categoria;

  const Expense({
    required this.id,
    required this.tarjetaId,
    required this.monto,
    required this.fechaConsumo,
    this.categoria = 'otros',
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      tarjetaId: json['tarjeta_id'] as String,
      monto: (json['monto'] as num).toDouble(),
      fechaConsumo: DateTime.parse(json['fecha_consumo'] as String),
      categoria: json['categoria'] as String? ?? 'otros',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tarjeta_id': tarjetaId,
        'monto': monto,
        'fecha_consumo': fechaConsumo.toIso8601String(),
        'categoria': categoria,
      };
}
