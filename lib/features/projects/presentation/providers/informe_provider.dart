import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/projects_repository.dart';
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

  const InformeState({
    this.isLoading = false,
    this.error,
    this.erroresCampos = const {},
    this.solicitud,
    this.solicitudCreada,
    this.proyecto,
  });

  bool get tieneResultado => proyecto != null;
}

/// Orquesta el flujo: formulario -> POST /solicitudes -> POST /proyectos.
class InformeNotifier extends Notifier<InformeState> {
  @override
  InformeState build() => const InformeState();

  Future<void> generarInforme({
    required InformeSolarEntity solicitud,
    required int plazoMeses,
  }) async {
    // Limpiamos errores anteriores y mostramos el cargando
    state = InformeState(isLoading: true, solicitud: solicitud);
    final repo = ref.read(projectsRepositoryProvider);

    try {
      // 1. Guardar la solicitud (el backend valida y convierte pesos -> kWh)
      final creada = await repo.crearSolicitud(solicitud);

      // 2. Generar el plan de cuotas (el backend estima valor y subsidio)
      final proyecto = await repo.crearProyecto(
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

  /// Vuelve al formulario para una nueva simulación
  void reiniciar() => state = const InformeState();
}

final informeProvider = NotifierProvider<InformeNotifier, InformeState>(
  InformeNotifier.new,
);
