import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/cuota_entity.dart';
import '../providers/informe_provider.dart';
import 'pago_dialog.dart';

/// Plan de pagos. Cada cuota muestra su referencia (PRY-001-C01) y su estado.
/// "Pagar" emite la factura (Factus) y crea el cobro (Factus Pay) en un paso.
class AmortizacionTab extends ConsumerWidget {
  final List<CuotaEntity> cuotas;

  const AmortizacionTab({super.key, required this.cuotas});

  static const _etiquetaEstado = {
    'pendiente': 'Pendiente',
    'facturada': 'Facturada',
    'cobrando': 'Esperando pago',
    'pagada': 'Pagada',
    'anulada': 'Anulada',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enProceso = ref.watch(informeProvider.select((s) => s.cuotaEnProceso));
    final formatoMoneda = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final formatoFecha = DateFormat('dd/MM/yyyy');

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cuotas.length,
      itemBuilder: (context, index) {
        final cuota = cuotas[index];
        final cargando = enProceso == cuota.id;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: cuota.enMora ? AppColors.error : Colors.grey.shade300,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: Text('${cuota.numero}'),
            ),
            title: Text(
              formatoMoneda.format(cuota.valorTotal),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${cuota.id} · Vence ${formatoFecha.format(cuota.fechaVencimiento)}\n'
              '${_etiquetaEstado[cuota.estado] ?? cuota.estado}'
              '${cuota.idFacturaFactus != null ? ' · ${cuota.idFacturaFactus}' : ''}'
              '${cuota.enMora ? ' · EN MORA' : ''}',
              style: cuota.enMora ? const TextStyle(color: AppColors.error) : null,
            ),
            isThreeLine: true,
            trailing: cuota.pagada
                ? IconButton(
                    tooltip: 'Ver detalle',
                    icon: const Icon(Icons.check_circle, color: AppColors.success),
                    onPressed: () => _abrirDialogo(context, cuota.id),
                  )
                : ElevatedButton(
                    onPressed: enProceso != null ? null : () => _pagar(context, ref, cuota),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(90, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: cargando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(cuota.tieneRecaudo ? 'Ver QR' : 'Pagar'),
                  ),
          ),
        );
      },
    );
  }

  Future<void> _pagar(BuildContext context, WidgetRef ref, CuotaEntity cuota) async {
    // Si ya tiene recaudo, solo mostramos el QR; si no, facturamos y cobramos
    if (!cuota.tieneRecaudo) {
      final ok = await ref.read(informeProvider.notifier).pagarCuota(cuota.id);
      if (!context.mounted) return;
      if (!ok) {
        final error = ref.read(informeProvider).errorPago ?? 'No se pudo generar el cobro';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        return;
      }
    }
    if (!context.mounted) return;
    _abrirDialogo(context, cuota.id);
  }

  void _abrirDialogo(BuildContext context, String cuotaId) {
    showDialog<void>(
      context: context,
      builder: (_) => PagoDialog(cuotaId: cuotaId),
    );
  }
}
