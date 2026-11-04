import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../providers/informe_provider.dart';

/// Simulador oficial de pagos del sandbox de Factus Pay
const _urlSimulador = 'https://pay-api-sandbox.factus.com.co/simulator';

/// Diálogo de pago de una cuota: factura emitida, QR y llave Bre-B del recaudo,
/// y botón para verificar el pago. Se actualiza solo porque observa el provider.
class PagoDialog extends ConsumerWidget {
  final String cuotaId;

  const PagoDialog({super.key, required this.cuotaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(informeProvider);
    final cuota = estado.cuota(cuotaId);
    final verificando = estado.cuotaEnProceso == cuotaId;
    final moneda = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    if (cuota == null) return const SizedBox.shrink();

    final qr = _qrBytes(cuota.qrDataUri);

    return AlertDialog(
      title: Text('Cuota ${cuota.numero} · ${moneda.format(cuota.valorTotal)}'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Factura electrónica
              if (cuota.idFacturaFactus != null)
                _Paso(
                  icono: Icons.receipt_long,
                  titulo: 'Factura ${cuota.idFacturaFactus} validada por la DIAN',
                  detalle: cuota.urlFactura,
                ),

              // 2. Pago
              if (cuota.pagada)
                const _Paso(
                  icono: Icons.check_circle,
                  color: AppColors.success,
                  titulo: 'Pago recibido y conciliado con su factura',
                )
              else ...[
                const SizedBox(height: 8),
                const Text(
                  'Escanea el QR con la app de tu banco o paga con la llave Bre-B:',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                if (qr != null)
                  Center(
                    child: Image.memory(
                      qr,
                      width: 220,
                      height: 220,
                      errorBuilder: (context, error, stack) =>
                          const Text('No se pudo mostrar el QR'),
                    ),
                  ),
                if (cuota.llaveBreB != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SelectableText(
                        cuota.llaveBreB!,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        tooltip: 'Copiar llave',
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () => Clipboard.setData(ClipboardData(text: cuota.llaveBreB!)),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Referencia: ${cuota.referencia}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                // Ayuda para la demo en sandbox
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    children: [
                      Text('Sandbox: paga con el simulador de Factus Pay', textAlign: TextAlign.center),
                      SelectableText(_urlSimulador, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ],

              if (estado.errorPago != null) ...[
                const SizedBox(height: 12),
                Text(
                  estado.errorPago!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
        if (!cuota.pagada)
          FilledButton.icon(
            onPressed: verificando
                ? null
                : () => ref.read(informeProvider.notifier).verificarPago(cuotaId),
            icon: verificando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.verified),
            label: const Text('Ya pagué, verificar'),
          ),
      ],
    );
  }

  /// "data:image/png;base64,iVBOR..." -> bytes de la imagen
  static Uint8List? _qrBytes(String? dataUri) {
    if (dataUri == null) return null;
    final coma = dataUri.indexOf(',');
    try {
      return base64Decode(coma >= 0 ? dataUri.substring(coma + 1) : dataUri);
    } catch (_) {
      return null;
    }
  }
}

class _Paso extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? detalle;
  final Color? color;

  const _Paso({required this.icono, required this.titulo, this.detalle, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color ?? Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (detalle != null)
                  SelectableText(detalle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
