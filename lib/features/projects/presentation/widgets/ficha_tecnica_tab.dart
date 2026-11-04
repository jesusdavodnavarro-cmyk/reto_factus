import 'package:flutter/material.dart';

class FichaTecnicaTab extends StatelessWidget {
  final double costoTotal;

  const FichaTecnicaTab({super.key, required this.costoTotal});

  @override
  Widget build(BuildContext context) {
    // Cálculo simulado para mostrar datos técnicos interesantes
    int panelesEstimados = (costoTotal / 1500000).ceil();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // Aquí está la corrección: Usamos Border.all()
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Especificaciones del Sistema',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          _buildItemRow(
            Icons.solar_power,
            'Paneles Solares Estimados',
            '$panelesEstimados unidades (550W c/u)',
          ),
          _buildItemRow(Icons.battery_charging_full, 'Inversor', 'Híbrido 5kW'),
          _buildItemRow(
            Icons.eco,
            'Reducción de CO2',
            '${(panelesEstimados * 0.8).toStringAsFixed(1)} Toneladas al año',
          ),
          _buildItemRow(
            Icons.shield,
            'Garantía',
            '10 años paneles / 5 años inversor',
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(value, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
