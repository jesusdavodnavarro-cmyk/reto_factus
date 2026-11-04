import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/cuota_entity.dart';

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
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              child: Text('${cuota.numero}'),
            ),
            title: Text(
              formatoMoneda.format(cuota.valorTotal),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Vence: ${formatoFecha.format(cuota.fechaVencimiento)}',
            ),
            trailing: ElevatedButton(
              onPressed: () {
                // TO DO: Conectar con Factus Pay y Facturación aquí
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Generando link de pago para cuota ${cuota.numero}...',
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
