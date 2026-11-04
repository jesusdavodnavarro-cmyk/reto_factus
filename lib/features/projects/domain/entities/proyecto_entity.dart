import 'cuota_entity.dart';

/// Totales del proyecto. Los calcula el backend a partir de las cuotas.
class ResumenProyecto {
  final int facturadoCop;
  final int recaudadoCop;
  final int pendienteCop;
  final int enMoraCop;
  final int cuotasPagadas;
  final int cuotasTotales;

  const ResumenProyecto({
    required this.facturadoCop,
    required this.recaudadoCop,
    required this.pendienteCop,
    required this.enMoraCop,
    required this.cuotasPagadas,
    required this.cuotasTotales,
  });

  factory ResumenProyecto.fromJson(Map<String, dynamic> json) {
    int entero(String clave) => (json[clave] as num? ?? 0).toInt();
    return ResumenProyecto(
      facturadoCop: entero('facturadoCop'),
      recaudadoCop: entero('recaudadoCop'),
      pendienteCop: entero('pendienteCop'),
      enMoraCop: entero('enMoraCop'),
      cuotasPagadas: entero('cuotasPagadas'),
      cuotasTotales: entero('cuotasTotales'),
    );
  }
}

/// Proyecto solar con su plan de cuotas (respuesta de POST/GET /api/proyectos).
class ProyectoEntity {
  final String id; // PRY-001
  final String solicitudId; // SOL-001
  final String cliente;
  final double potenciaKwp;
  final int valorTotalCop;
  final double subsidioPct;
  final int subsidioCop;
  final int financiadoCop;
  final List<CuotaEntity> cuotas;
  final ResumenProyecto resumen;

  const ProyectoEntity({
    required this.id,
    required this.solicitudId,
    required this.cliente,
    required this.potenciaKwp,
    required this.valorTotalCop,
    required this.subsidioPct,
    required this.subsidioCop,
    required this.financiadoCop,
    required this.cuotas,
    required this.resumen,
  });

  factory ProyectoEntity.fromJson(Map<String, dynamic> json) {
    return ProyectoEntity(
      id: json['id'] as String,
      solicitudId: json['solicitudId'] as String,
      cliente: json['cliente'] as String,
      potenciaKwp: (json['potenciaKwp'] as num? ?? 0).toDouble(),
      valorTotalCop: (json['valorTotalCop'] as num).toInt(),
      subsidioPct: (json['subsidioPct'] as num).toDouble(),
      subsidioCop: (json['subsidioCop'] as num).toInt(),
      financiadoCop: (json['financiadoCop'] as num).toInt(),
      cuotas: (json['cuotas'] as List)
          .map((c) => CuotaEntity.fromJson(c as Map<String, dynamic>))
          .toList(),
      resumen: ResumenProyecto.fromJson(
        json['resumen'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
