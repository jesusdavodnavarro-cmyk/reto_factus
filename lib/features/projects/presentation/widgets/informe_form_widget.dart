import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/informe_solar_entity.dart';
import '../providers/informe_provider.dart';

/// Formulario "Quiero mi proyecto solar".
/// Pide exactamente lo que valida POST /api/solicitudes (ver backend/requests/solicitudes.http).
class InformeFormWidget extends ConsumerStatefulWidget {
  const InformeFormWidget({super.key});

  @override
  ConsumerState<InformeFormWidget> createState() => _InformeFormWidgetState();
}

class _InformeFormWidgetState extends ConsumerState<InformeFormWidget> {
  final _formKey = GlobalKey<FormState>();

  // 1. Proyecto
  final _consumoCtrl = TextEditingController();
  final _presupuestoCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  bool _esPesos = true; // true = COP, false = kWh
  int _plazoMeses = 12;

  // 2. Facturación electrónica
  String _tipoPersona = 'natural'; // 'natural' | 'juridica'
  String _tipoDocumento = 'CC'; // CC | CE | PASAPORTE (natural) - NIT (jurídica)
  final _nombreCtrl = TextEditingController(); // nombres o razón social
  final _documentoCtrl = TextEditingController();
  final _dvCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  bool get _esJuridica => _tipoPersona == 'juridica';

  @override
  void dispose() {
    for (final c in [
      _consumoCtrl,
      _presupuestoCtrl,
      _areaCtrl,
      _nombreCtrl,
      _documentoCtrl,
      _dvCtrl,
      _direccionCtrl,
      _emailCtrl,
      _telefonoCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// "516.500" -> 516500 y "40,5" -> 40.5 (formato colombiano)
  double? _numero(String texto) {
    final limpio = texto
        .trim()
        .replaceAll('.', '')
        .replaceAll(' ', '')
        .replaceAll(',', '.');
    return double.tryParse(limpio);
  }

  // ---------- Validaciones rápidas (el backend valida todo de nuevo) ----------

  String? _requerido(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Este campo es obligatorio' : null;

  String? _mayorQueCero(String? v) {
    final error = _requerido(v);
    if (error != null) return error;
    final n = _numero(v!);
    if (n == null) return 'Ingresa un número válido';
    if (n <= 0) return 'Debe ser mayor a 0';
    return null;
  }

  String? _noNegativo(String? v) {
    final error = _requerido(v);
    if (error != null) return error;
    final n = _numero(v!);
    if (n == null) return 'Ingresa un número válido';
    if (n < 0) return 'No puede ser negativo';
    return null;
  }

  String? _minimoCaracteres(String? v, int minimo) {
    final error = _requerido(v);
    if (error != null) return error;
    return v!.trim().length < minimo ? 'Mínimo $minimo caracteres' : null;
  }

  String? _email(String? v) {
    final error = _requerido(v);
    if (error != null) return error;
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v!.trim());
    return ok ? null : 'Correo no válido';
  }

  String? _digitos(String? v, int min, int max) {
    final error = _requerido(v);
    if (error != null) return error;
    final largo = v!.trim().length;
    return (largo < min || largo > max) ? 'Entre $min y $max dígitos' : null;
  }

  // ---------- Envío ----------

  void _generar() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus(); // oculta el teclado

    final nombre = _nombreCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final telefono = _telefonoCtrl.text.trim();
    final dv = _dvCtrl.text.trim();

    final solicitud = InformeSolarEntity(
      consumo: Consumo(
        valor: _numero(_consumoCtrl.text)!,
        unidad: _esPesos ? 'COP' : 'kWh',
      ),
      presupuestoCop: _numero(_presupuestoCtrl.text)!,
      areaDisponibleM2: _numero(_areaCtrl.text)!,
      // MVP: el contacto es el mismo de facturación (formulario más corto)
      contacto: Contacto(nombre: nombre, email: email, telefono: telefono),
      facturacion: Facturacion(
        tipoPersona: _tipoPersona,
        tipoDocumento: _esJuridica ? 'NIT' : _tipoDocumento,
        numeroDocumento: _documentoCtrl.text.trim(),
        nombres: _esJuridica ? null : nombre,
        razonSocial: _esJuridica ? nombre : null,
        dv: (_esJuridica && dv.isNotEmpty) ? dv : null,
        direccion: _direccionCtrl.text.trim(),
        email: email,
        telefono: telefono,
        // municipioCodigo: el backend usa Montería (23001) por defecto
      ),
    );

    ref
        .read(informeProvider.notifier)
        .generarInforme(solicitud: solicitud, plazoMeses: _plazoMeses);
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(informeProvider);
    const espacio = SizedBox(height: 16);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _TituloSeccion('1. Tu consumo de energía'),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Pesos (COP)')),
              ButtonSegment(value: false, label: Text('Energía (kWh)')),
            ],
            selected: {_esPesos},
            onSelectionChanged: (seleccion) {
              setState(() {
                _esPesos = seleccion.first;
                _consumoCtrl.clear(); // limpiamos al cambiar la unidad
              });
            },
          ),
          espacio,
          TextFormField(
            controller: _consumoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: _esPesos
                  ? 'Valor promedio de tu factura de luz (COP)'
                  : 'Consumo promedio mensual (kWh)',
              helperText: _esPesos ? 'Ej: 516.500' : 'Ej: 500',
              prefixIcon: Icon(_esPesos ? Icons.attach_money : Icons.bolt),
            ),
            validator: _mayorQueCero,
          ),
          espacio,
          TextFormField(
            controller: _presupuestoCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Presupuesto disponible (COP)',
              prefixIcon: Icon(Icons.savings_outlined),
            ),
            validator: _noNegativo,
          ),
          espacio,
          TextFormField(
            controller: _areaCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Área disponible para paneles (m²)',
              helperText: 'Techo o terraza, aproximado',
              prefixIcon: Icon(Icons.roofing),
            ),
            validator: _mayorQueCero,
          ),
          espacio,
          DropdownButtonFormField<int>(
            initialValue: _plazoMeses,
            decoration: const InputDecoration(
              labelText: 'Plazo para pagar',
              prefixIcon: Icon(Icons.calendar_month),
            ),
            items: const [6, 12, 24, 36]
                .map((m) => DropdownMenuItem(value: m, child: Text('$m cuotas mensuales')))
                .toList(),
            onChanged: (m) => setState(() => _plazoMeses = m ?? 12),
          ),

          const SizedBox(height: 32),
          const _TituloSeccion('2. Datos para tu factura electrónica'),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'natural',
                label: Text('Persona'),
                icon: Icon(Icons.person_outline),
              ),
              ButtonSegment(
                value: 'juridica',
                label: Text('Empresa (NIT)'),
                icon: Icon(Icons.store_outlined),
              ),
            ],
            selected: {_tipoPersona},
            onSelectionChanged: (seleccion) {
              setState(() {
                _tipoPersona = seleccion.first;
                _tipoDocumento = _esJuridica ? 'NIT' : 'CC';
                _dvCtrl.clear();
              });
            },
          ),
          espacio,
          TextFormField(
            controller: _nombreCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: _esJuridica ? 'Razón social' : 'Nombre completo',
              prefixIcon: Icon(_esJuridica ? Icons.business : Icons.badge_outlined),
            ),
            validator: (v) => _minimoCaracteres(v, 3),
          ),
          espacio,
          if (!_esJuridica) ...[
            DropdownButtonFormField<String>(
              key: const ValueKey('tipoDocumento'),
              initialValue: _tipoDocumento,
              decoration: const InputDecoration(labelText: 'Tipo de documento'),
              items: const [
                DropdownMenuItem(value: 'CC', child: Text('Cédula de ciudadanía')),
                DropdownMenuItem(value: 'CE', child: Text('Cédula de extranjería')),
                DropdownMenuItem(value: 'PASAPORTE', child: Text('Pasaporte')),
              ],
              onChanged: (v) => setState(() => _tipoDocumento = v ?? 'CC'),
            ),
            espacio,
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _documentoCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: _esJuridica ? 'NIT (sin DV)' : 'Número de documento',
                    helperText: 'Solo números, sin puntos ni guiones',
                  ),
                  validator: (v) => _digitos(v, 5, 15),
                ),
              ),
              if (_esJuridica) ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    controller: _dvCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1),
                    ],
                    decoration: const InputDecoration(labelText: 'DV'),
                  ),
                ),
              ],
            ],
          ),
          espacio,
          TextFormField(
            controller: _direccionCtrl,
            decoration: const InputDecoration(
              labelText: 'Dirección',
              helperText: 'Montería, Córdoba',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            validator: (v) => _minimoCaracteres(v, 5),
          ),
          espacio,
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo (aquí llega la factura)',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: _email,
          ),
          espacio,
          TextFormField(
            controller: _telefonoCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: const InputDecoration(
              labelText: 'Celular',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: (v) => _digitos(v, 7, 10),
          ),

          const SizedBox(height: 24),
          if (estado.error != null) ...[
            _CajaError(mensaje: estado.error!, campos: estado.erroresCampos),
            espacio,
          ],
          ElevatedButton(
            onPressed: estado.isLoading ? null : _generar,
            child: estado.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Generar mi plan solar'),
          ),
        ],
      ),
    );
  }
}

class _TituloSeccion extends StatelessWidget {
  final String texto;
  const _TituloSeccion(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(texto, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

/// Nombres legibles para los campos que devuelve el backend en un 400
const _etiquetas = <String, String>{
  'consumo.valor': 'Consumo',
  'consumo.unidad': 'Unidad de consumo',
  'presupuestoCop': 'Presupuesto',
  'areaDisponibleM2': 'Área disponible',
  'contacto.nombre': 'Nombre',
  'contacto.email': 'Correo',
  'contacto.telefono': 'Celular',
  'facturacion.nombres': 'Nombre completo',
  'facturacion.razonSocial': 'Razón social',
  'facturacion.tipoDocumento': 'Tipo de documento',
  'facturacion.numeroDocumento': 'Número de documento',
  'facturacion.dv': 'DV',
  'facturacion.direccion': 'Dirección',
  'facturacion.email': 'Correo de facturación',
  'facturacion.telefono': 'Celular de facturación',
  'numeroCuotas': 'Plazo',
};

/// Muestra el error general y, si los hay, los campos que rechazó el backend
class _CajaError extends StatelessWidget {
  final String mensaje;
  final Map<String, String> campos;

  const _CajaError({required this.mensaje, required this.campos});

  @override
  Widget build(BuildContext context) {
    final colorError = Theme.of(context).colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorError.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorError.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: colorError),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mensaje,
                  style: TextStyle(color: colorError, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          for (final campo in campos.entries)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 32),
              child: Text('• ${_etiquetas[campo.key] ?? campo.key}: ${campo.value}'),
            ),
        ],
      ),
    );
  }
}
