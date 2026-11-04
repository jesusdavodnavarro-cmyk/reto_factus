import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/informe_provider.dart';
import '../../domain/entities/informe_solar_entity.dart';

class InformeFormWidget extends ConsumerStatefulWidget {
  const InformeFormWidget({super.key});

  @override
  ConsumerState<InformeFormWidget> createState() => _InformeFormWidgetState();
}

class _InformeFormWidgetState extends ConsumerState<InformeFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _consumoCtrl = TextEditingController();
  bool _esPesos = true; // true = COP, false = kWh

  @override
  void dispose() {
    _consumoCtrl.dispose();
    super.dispose();
  }

  void _generar() {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus(); // Oculta el teclado
      final consumo = double.parse(_consumoCtrl.text);

      // Simulamos los datos del cliente para el MVP (luego vendrán del Login)
      final clienteMock = Facturacion(
        tipoPersona: 'juridica',
        tipoDocumento: 'NIT',
        numeroDocumento: '900123456',
        razonSocial: 'Panadería El Sol SAS',
        direccion: 'Cra 2 # 40-10',
        email: 'facturacion@pan.co',
        telefono: '6047891234',
      );

      ref
          .read(informeProvider.notifier)
          .generarInforme(
            consumo: consumo,
            esPesos: _esPesos,
            plazoMeses: 12, // 12 meses por defecto para el MVP
            datosCliente: clienteMock,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(informeProvider).isLoading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selector de tipo de consumo (Diseño Material 3)
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Pesos (COP)')),
              ButtonSegment(value: false, label: Text('Energía (kWh)')),
            ],
            selected: {_esPesos},
            onSelectionChanged: (Set<bool> newSelection) {
              setState(() {
                _esPesos = newSelection.first;
                _consumoCtrl.clear(); // Limpiamos el input al cambiar la unidad
              });
            },
          ),
          const SizedBox(height: 24),

          // Input de Consumo
          TextFormField(
            controller: _consumoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: _esPesos
                  ? 'Consumo promedio mensual (COP)'
                  : 'Consumo promedio mensual (kWh)',
              prefixIcon: Icon(_esPesos ? Icons.attach_money : Icons.bolt),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es obligatorio';
              }
              if (double.tryParse(value) == null) {
                return 'Ingresa un valor numérico válido';
              }
              if (double.parse(value) <= 0) {
                return 'El consumo debe ser mayor a 0';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),

          // Botón Generar Informe
          ElevatedButton(
            onPressed: isLoading ? null : _generar,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Generar Informe'),
          ),
        ],
      ),
    );
  }
}
