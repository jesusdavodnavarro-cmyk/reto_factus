class CuotaEntity {
  final int numero;
  final DateTime fechaVencimiento;
  final double valorCapital;
  final double valorInteres;
  final double valorTotal;
  final String estado; // 'pendiente', 'pagada', 'vencida'

  // Variables clave para el Reto Factus
  final String? idFacturaFactus;
  final String? urlPagoFactusPay;

  CuotaEntity({
    required this.numero,
    required this.fechaVencimiento,
    required this.valorCapital,
    required this.valorInteres,
    required this.valorTotal,
    this.estado = 'pendiente',
    this.idFacturaFactus,
    this.urlPagoFactusPay,
  });

  factory CuotaEntity.fromJson(Map<String, dynamic> json) {
    return CuotaEntity(
      numero: json['numero'],
      fechaVencimiento: DateTime.parse(json['fechaVencimiento']),
      valorCapital: (json['valorCapital'] as num).toDouble(),
      valorInteres: (json['valorInteres'] as num).toDouble(),
      valorTotal: (json['valorTotal'] as num).toDouble(),
      estado: json['estado'] ?? 'pendiente',
      idFacturaFactus: json['idFacturaFactus'],
      urlPagoFactusPay: json['urlPagoFactusPay'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'numero': numero,
      'fechaVencimiento': fechaVencimiento.toIso8601String(),
      'valorCapital': valorCapital,
      'valorInteres': valorInteres,
      'valorTotal': valorTotal,
      'estado': estado,
      'idFacturaFactus': idFacturaFactus,
      'urlPagoFactusPay': urlPagoFactusPay,
    };
  }
}
