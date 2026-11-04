/// Una cuota del plan de pagos, tal como la devuelve el backend.
/// El [id] (ej. PRY-001-C01) es la MISMA referencia en Factus y en Factus Pay:
/// así se asocia automáticamente el pago con su factura.
class CuotaEntity {
  final String id;
  final int numero;
  final DateTime fechaVencimiento;
  final int valorTotal; // pesos enteros (montoCop en el backend)
  final String estado; // pendiente | facturada | cobrando | pagada | anulada

  // Se llenan cuando la cuota se facture (Factus) y se cobre (Factus Pay)
  final String? idFacturaFactus; // número de factura, ej. SETP990000123
  final String? urlPagoFactusPay;

  const CuotaEntity({
    required this.id,
    required this.numero,
    required this.fechaVencimiento,
    required this.valorTotal,
    this.estado = 'pendiente',
    this.idFacturaFactus,
    this.urlPagoFactusPay,
  });

  /// Vencida y sin pagar
  bool get enMora {
    if (estado == 'pagada' || estado == 'anulada') return false;
    final hoy = DateTime.now();
    final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);
    return fechaVencimiento.isBefore(hoySinHora);
  }

  factory CuotaEntity.fromJson(Map<String, dynamic> json) {
    final factura = json['factura'] as Map<String, dynamic>?;
    final recaudo = json['recaudo'] as Map<String, dynamic>?;

    return CuotaEntity(
      id: json['id'] as String,
      numero: json['numero'] as int,
      fechaVencimiento: DateTime.parse(json['vence'] as String),
      valorTotal: (json['montoCop'] as num).toInt(),
      estado: json['estado'] as String? ?? 'pendiente',
      idFacturaFactus: factura?['number'] as String?,
      urlPagoFactusPay: recaudo?['link'] as String?,
    );
  }
}
