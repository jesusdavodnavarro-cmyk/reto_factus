import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/cuota_entity.dart';

/// Plan de pagos. Cada cuota muestra su referencia única (PRY-001-C01),
/// la misma que usarán Factus (factura) y Factus Pay (cobro).
class AmortizacionTab extends StatelessWidget {
  final List<CuotaEntity> cuotas;

  const AmortizacionTab({super.key, required this.cuotas});

  @override
  Widget build(BuildContext context) {
    final formatoMoneda = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    final formatoFecha = DateFormat('dd/MM/yyyy');

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cuotas.length,
      itemBuilder: (context, index) {
        final cuota = cuotas[index];
        final pagada = cuota.estado == 'pagada';

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
              '${cuota.id} · Vence ${formatoFecha.format(cuota.fechaVencimiento)}'
              '${cuota.enMora ? ' · EN MORA' : ''}',
              style: cuota.enMora ? const TextStyle(color: AppColors.error) : null,
            ),
            trailing: pagada
                ? const Icon(Icons.check_circle, color: AppColors.success)
                : ElevatedButton(
                    onPressed: () {
                      // Hito 3 y 4: facturar con Factus y cobrar con Factus Pay
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Cobro de ${cuota.id}: se conecta con Factus y Factus Pay en el siguiente hito',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(80, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('Pagar'),
                  ),
          ),
        );
      },
    );
  }
}
