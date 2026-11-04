import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/entities/cuota_entity.dart';
import '../domain/entities/informe_solar_entity.dart';
import '../domain/entities/proyecto_entity.dart';

/// Única puerta de la app hacia el backend para solicitudes, proyectos y cuotas.
/// Las pantallas y providers NO usan Dio directamente: usan este repositorio.
class ProjectsRepository {
  final Dio _dio;

  ProjectsRepository(this._dio);

  /// POST /api/solicitudes -> "Quiero mi proyecto solar"
  Future<SolicitudCreada> crearSolicitud(InformeSolarEntity solicitud) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/solicitudes',
        data: solicitud.toJson(),
      );
      return SolicitudCreada.fromJson(res.data!);
    } catch (e) {
      throw traducirError(e);
    }
  }

  /// POST /api/proyectos -> plan de cuotas.
  /// No enviamos precio: el backend lo estima con el consumo (nunca confiar
  /// en precios calculados en el frontend).
  Future<ProyectoEntity> crearProyecto({
    required String solicitudId,
    required int numeroCuotas,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/proyectos',
        data: {'solicitudId': solicitudId, 'numeroCuotas': numeroCuotas},
      );
      return ProyectoEntity.fromJson(res.data!);
    } catch (e) {
      throw traducirError(e);
    }
  }

  /// GET /api/proyectos/:id -> para refrescar estados de cuotas y totales
  Future<ProyectoEntity> obtenerProyecto(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/proyectos/$id');
      return ProyectoEntity.fromJson(res.data!);
    } catch (e) {
      throw traducirError(e);
    }
  }

  /// POST /api/cuotas/:id/pagar -> emite la factura (Factus) y crea el
  /// recaudo (Factus Pay). Devuelve la cuota con su QR y llave Bre-B.
  Future<CuotaEntity> pagarCuota(String cuotaId) =>
      _postCuota('/cuotas/$cuotaId/pagar');

  /// POST /api/cuotas/:id/verificar-pago -> consulta Factus Pay y concilia
  Future<CuotaEntity> verificarPago(String cuotaId) =>
      _postCuota('/cuotas/$cuotaId/verificar-pago');

  Future<CuotaEntity> _postCuota(String path) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(path);
      return CuotaEntity.fromJson(res.data!);
    } catch (e) {
      throw traducirError(e);
    }
  }
}

// Providers: así cualquier parte de la app pide el repositorio con ref.read(...)
final dioProvider = Provider<Dio>((ref) => crearDio());

final projectsRepositoryProvider = Provider<ProjectsRepository>(
  (ref) => ProjectsRepository(ref.watch(dioProvider)),
);
