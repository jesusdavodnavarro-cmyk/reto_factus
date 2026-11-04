import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/cuota_entity.dart';
import '../../domain/entities/informe_solar_entity.dart';

// 1. Estado inmutable que representa la pantalla del informe
class InformeState {
  final bool isLoading;
  final String? error;
  final InformeSolarEntity? solicitud; // Cambiado a InformeSolarEntity
  final double? costoTotal;
  final double? anticipo;
  final double? saldoFinanciar;
  final List<CuotaEntity>? tablaAmortizacion;

  InformeState({
    this.isLoading = false,
    this.error,
    this.solicitud,
    this.costoTotal,
    this.anticipo,
    this.saldoFinanciar,
    this.tablaAmortizacion,
  });

  InformeState copyWith({
    bool? isLoading,
    String? error,
    InformeSolarEntity? solicitud, // Cambiado a InformeSolarEntity
    double? costoTotal,
    double? anticipo,
    double? saldoFinanciar,
    List<CuotaEntity>? tablaAmortizacion,
  }) {
    return InformeState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      solicitud: solicitud ?? this.solicitud,
      costoTotal: costoTotal ?? this.costoTotal,
      anticipo: anticipo ?? this.anticipo,
      saldoFinanciar: saldoFinanciar ?? this.saldoFinanciar,
      tablaAmortizacion: tablaAmortizacion ?? this.tablaAmortizacion,
    );
  }
}

// 2. Notifier Moderno (Riverpod 2.x) que maneja la lógica matemática
class InformeNotifier extends Notifier<InformeState> {
  @override
  InformeState build() {
    return InformeState();
  }

  // Simulación de cálculo basado en el consumo
  void generarInforme({
    required double consumo,
    required bool esPesos, // true = COP, false = kWh
    required int plazoMeses,
    required Facturacion datosCliente, // Cambiado a Facturacion
  }) {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Reglas de negocio simuladas
      double costoProyecto = esPesos ? (consumo * 20) : (consumo * 10000);

      // El cliente debe dar 40% de anticipo
      double anticipoRequerido = costoProyecto * 0.40;
      double saldo = costoProyecto - anticipoRequerido;

      // Generar la tabla de amortización (Simulando cuotas fijas sin interés para simplificar)
      double valorCapitalPorCuota = saldo / plazoMeses;
      List<CuotaEntity> amortizacion = [];

      for (int i = 1; i <= plazoMeses; i++) {
        amortizacion.add(
          CuotaEntity(
            numero: i, // Cambiado a numero
            fechaVencimiento: DateTime.now().add(Duration(days: 30 * i)),
            valorCapital: valorCapitalPorCuota, // Nuevo campo requerido
            valorInteres: 0.0, // Simulado a 0 para el MVP
            valorTotal: valorCapitalPorCuota, // Nuevo campo requerido
            estado: 'pendiente',
          ),
        );
      }

      // Preparamos el objeto JSON para el Backend usando InformeSolarEntity
      final solicitudLista = InformeSolarEntity(
        consumo: Consumo(
          // Cambiado a Consumo
          valor: consumo,
          unidad: esPesos ? 'COP' : 'kWh',
        ),
        presupuestoCop: anticipoRequerido
            .roundToDouble(), // Aseguramos que sea double
        areaDisponibleM2: 0.0,
        contacto: Contacto(
          // Cambiado a Contacto
          nombre: datosCliente.nombres ?? datosCliente.razonSocial ?? '',
          email: datosCliente.email,
          telefono: datosCliente.telefono,
        ),
        facturacion: datosCliente,
      );

      // Actualizamos el estado con éxito
      state = state.copyWith(
        isLoading: false,
        solicitud: solicitudLista,
        costoTotal: costoProyecto,
        anticipo: anticipoRequerido,
        saldoFinanciar: saldo,
        tablaAmortizacion: amortizacion,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al calcular el proyecto: $e',
      );
    }
  }

  // TO DO: Conectar con el backend usando Dio
  Future<void> enviarSolicitudABackend() async {
    if (state.solicitud == null) return;

    state = state.copyWith(isLoading: true);
    // Aquí irá el POST a {{api}}/solicitudes
    await Future.delayed(const Duration(seconds: 2));
    state = state.copyWith(isLoading: false);
  }
}

// 3. Provider global usando la nueva sintaxis NotifierProvider
final informeProvider = NotifierProvider<InformeNotifier, InformeState>(() {
  return InformeNotifier();
});
