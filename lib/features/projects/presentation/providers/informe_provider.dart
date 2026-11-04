import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/projects_repository.dart';
import '../../domain/entities/cuota_entity.dart';
import '../../domain/entities/informe_solar_entity.dart';
import '../../domain/entities/proyecto_entity.dart';

/// Estado inmutable de la pantalla del informe.
/// Los números (valor, subsidio, cuotas) vienen SIEMPRE del backend.
class InformeState {
  final bool isLoading;
  final String? error;

  /// Errores por campo que devolvió el backend (400). Clave: 'facturacion.email'
  final Map<String, String> erroresCampos;

  final InformeSolarEntity? solicitud; // lo que llenó el cliente
  final SolicitudCreada? solicitudCreada; // SOL-001 + consumo en kWh
  final ProyectoEntity? proyecto; // PRY-001 + cuotas

  /// Cuota que se está facturando/cobrando/verificando (para el "cargando" del botón)
  final String? cuotaEnProceso;

  /// Último error al pagar o verificar una cuota
  final String? errorPago;

  const InformeState({
    this.isLoading = false,
    this.error,
    this.erroresCampos = const {},
    this.solicitud,
    this.solicitudCreada,
    this.proyecto,
    this.cuotaEnProceso,
    this.errorPago,
  });

  bool get tieneResultado => proyecto != null;

  CuotaEntity? cuota(String cuotaId) {
    for (final c in proyecto?.cuotas ?? const <CuotaEntity>[]) {
      if (c.id == cuotaId) return c;
    }
    return null;
  }

  /// Copia que conserva solicitud y proyecto, cambiando solo lo del pago
  InformeState conPago({ProyectoEntity? proyecto, String? cuotaEnProceso, String? errorPago}) {
    return InformeState(
      solicitud: solicitud,
      solicitudCreada: solicitudCreada,
      proyecto: proyecto ?? this.proyecto,
      cuotaEnProceso: cuotaEnProceso,
      errorPago: errorPago,
    );
  }
}

/// Orquesta el flujo: formulario -> POST /solicitudes -> POST /proyectos
/// y luego, por cuota: pagar (factura + recaudo) -> verificar pago.
class InformeNotifier extends Notifier<InformeState> {
  @override
  InformeState build() => const InformeState();

  ProjectsRepository get _repo => ref.read(projectsRepositoryProvider);

  Future<void> generarInforme({
    required InformeSolarEntity solicitud,
    required int plazoMeses,
  }) async {
    // Limpiamos errores anteriores y mostramos el cargando
    state = InformeState(isLoading: true, solicitud: solicitud);

    try {
      // 1. Guardar la solicitud (el backend valida y convierte pesos -> kWh)
      final creada = await _repo.crearSolicitud(solicitud);

      // 2. Generar el plan de cuotas (el backend estima valor y subsidio)
      final proyecto = await _repo.crearProyecto(
        solicitudId: creada.id,
        numeroCuotas: plazoMeses,
      );

      state = InformeState(
        solicitud: solicitud,
        solicitudCreada: creada,
        proyecto: proyecto,
      );
    } on ApiException catch (e) {
      state = InformeState(
        solicitud: solicitud,
        error: e.mensaje,
        erroresCampos: e.campos,
      );
    } catch (e) {
      // Cualquier otro error: nunca dejar la pantalla "cargando" para siempre
      state = InformeState(solicitud: solicitud, error: 'Error inesperado: $e');
    }
  }

  /// Botón "Pagar": factura en Factus + recaudo en Factus Pay. true si salió bien.
  Future<bool> pagarCuota(String cuotaId) =>
      _accionCuota(cuotaId, () => _repo.pagarCuota(cuotaId));

  /// Botón "Ya pagué": consulta Factus Pay y concilia. true si salió bien.
  Future<bool> verificarPago(String cuotaId) =>
      _accionCuota(cuotaId, () => _repo.verificarPago(cuotaId));

  Future<bool> _accionCuota(String cuotaId, Future<CuotaEntity> Function() accion) async {
    final proyecto = state.proyecto;
    if (proyecto == null) return false;

    state = state.conPago(cuotaEnProceso: cuotaId);
    try {
      await accion();
      // Recargamos el proyecto: así los totales (recaudado, pendiente, mora) quedan al día
      final actualizado = await _repo.obtenerProyecto(proyecto.id);
      state = state.conPago(proyecto: actualizado);
      return true;
    } on ApiException catch (e) {
      state = state.conPago(errorPago: e.mensaje);
      return false;
    } catch (e) {
      state = state.conPago(errorPago: 'Error inesperado: $e');
      return false;
    }
  }

  /// Vuelve al formulario para una nueva simulación
  void reiniciar() => state = const InformeState();
}

final informeProvider = NotifierProvider<InformeNotifier, InformeState>(
  InformeNotifier.new,
);
