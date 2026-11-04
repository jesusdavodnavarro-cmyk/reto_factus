/// Una cuota del plan de pagos, tal como la devuelve el backend.
/// La [referencia] (ej. PRY-001-C01-K7Q2X) es la MISMA en Factus y en Factus Pay:
/// así se asocia automáticamente el pago con su factura.
class CuotaEntity {
  final String id; // PRY-001-C01 (para mostrar)
  final String referencia;
  final int numero;
  final DateTime fechaVencimiento;
  final int valorTotal; // pesos enteros (montoCop en el backend)
  final String estado; // pendiente | facturada | cobrando | pagada | anulada

  // Factura electrónica (Factus)
  final String? idFacturaFactus; // número de factura, ej. SETP990000123
  final String? urlFactura; // representación gráfica pública

  // Recaudo (Factus Pay)
  final String? qrDataUri; // data:image/png;base64,...
  final String? llaveBreB; // ej. @FCWHUYLIV2MWUEUESTONH
  final String? qrExpiraEn;

  const CuotaEntity({
    required this.id,
    required this.referencia,
    required this.numero,
    required this.fechaVencimiento,
    required this.valorTotal,
    this.estado = 'pendiente',
    this.idFacturaFactus,
    this.urlFactura,
    this.qrDataUri,
    this.llaveBreB,
    this.qrExpiraEn,
  });

  bool get pagada => estado == 'pagada';
  bool get tieneRecaudo => qrDataUri != null || llaveBreB != null;

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
      referencia: (json['referencia'] ?? json['id']) as String,
      numero: json['numero'] as int,
      fechaVencimiento: DateTime.parse(json['vence'] as String),
      valorTotal: (json['montoCop'] as num).toInt(),
      estado: json['estado'] as String? ?? 'pendiente',
      idFacturaFactus: factura?['number'] as String?,
      urlFactura: factura?['publicUrl'] as String?,
      qrDataUri: recaudo?['qr'] as String?,
      llaveBreB: recaudo?['brebKey'] as String?,
      qrExpiraEn: recaudo?['qrExpiraEn'] as String?,
    );
  }
}
