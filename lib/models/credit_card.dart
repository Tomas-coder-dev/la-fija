/// Modelo que mapea la tabla `tarjetas` en Supabase.
class CreditCard {
  final String id;
  final String banco;
  final String nombreTarjeta;
  final int diaCierre;
  final int diaPago;
  final double metaMensual;
  final double limiteCredito;

  const CreditCard({
    required this.id,
    required this.banco,
    required this.nombreTarjeta,
    required this.diaCierre,
    required this.diaPago,
    required this.metaMensual,
    required this.limiteCredito,
  });

  factory CreditCard.fromJson(Map<String, dynamic> json) {
    return CreditCard(
      id: json['id'] as String,
      banco: json['banco'] as String,
      nombreTarjeta: json['nombre_tarjeta'] as String,
      diaCierre: json['dia_cierre'] as int,
      diaPago: json['dia_pago'] as int,
      metaMensual: (json['meta_mensual'] as num).toDouble(),
      limiteCredito: (json['limite_credito'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'banco': banco,
        'nombre_tarjeta': nombreTarjeta,
        'dia_cierre': diaCierre,
        'dia_pago': diaPago,
        'meta_mensual': metaMensual,
      };
}
