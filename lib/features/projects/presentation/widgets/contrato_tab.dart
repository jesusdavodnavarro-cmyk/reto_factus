import 'package:flutter/material.dart';

class ContratoTab extends StatelessWidget {
  final String cliente;

  const ContratoTab({super.key, required this.cliente});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        // Aquí está la corrección: Usamos Border.all()
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.gavel, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Acuerdo de Prestación de Servicios',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'El presente documento resume las condiciones de instalación para el cliente $cliente. '
            'Al proceder con el pago del anticipo o de la primera cuota de amortización, el cliente '
            'acepta los términos técnicos descritos en la Ficha Técnica, así como las condiciones '
            'de recaudo y facturación electrónica a través de la plataforma Factus.',
            style: const TextStyle(fontSize: 14, height: 1.5),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 16),
          // Botón estético para simular firma
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.draw),
            label: const Text('Firmar Digitalmente (Próximamente)'),
          ),
        ],
      ),
    );
  }
}
