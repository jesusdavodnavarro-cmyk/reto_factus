import 'package:flutter/material.dart';

/// Ficha técnica derivada del tamaño del sistema que calculó el backend.
class FichaTecnicaTab extends StatelessWidget {
  final double potenciaKwp;
  final double consumoKwhMes;
  final double? areaDisponibleM2;

  const FichaTecnicaTab({
    super.key,
    required this.potenciaKwp,
    required this.consumoKwhMes,
    this.areaDisponibleM2,
  });

  static const _wattsPorPanel = 550;
  static const _m2PorPanel = 2.6; // panel de 550 W ≈ 2,3 x 1,1 m
  static const _kgCo2PorKwh = 0.126; // factor aproximado de la red eléctrica colombiana

  @override
  Widget build(BuildContext context) {
    final paneles = (potenciaKwp * 1000 / _wattsPorPanel).ceil();
    final areaRequerida = paneles * _m2PorPanel;
    final co2Toneladas = consumoKwhMes * 12 * _kgCo2PorKwh / 1000;
    final areaSuficiente = areaDisponibleM2 == null || areaDisponibleM2! >= areaRequerida;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Especificaciones del sistema',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          _fila(Icons.bolt, 'Potencia instalada', '${potenciaKwp.toStringAsFixed(2)} kWp'),
          _fila(Icons.solar_power, 'Paneles solares', '$paneles unidades de $_wattsPorPanel W'),
          _fila(
            Icons.roofing,
            'Área requerida',
            '${areaRequerida.toStringAsFixed(0)} m²'
                '${areaDisponibleM2 != null ? ' (tienes ${areaDisponibleM2!.toStringAsFixed(0)} m²)' : ''}',
            alerta: !areaSuficiente,
          ),
          _fila(Icons.electrical_services, 'Inversor', '${potenciaKwp.ceil()} kW on-grid'),
          _fila(Icons.eco, 'CO₂ evitado', '${co2Toneladas.toStringAsFixed(1)} toneladas al año'),
          _fila(Icons.shield, 'Garantía', '25 años paneles / 5 años inversor'),
        ],
      ),
    );
  }

  Widget _fila(IconData icon, String titulo, String valor, {bool alerta = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: alerta ? Colors.orange : Colors.blueGrey, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                Text(valor, style: const TextStyle(color: Colors.black54)),
                if (alerta)
                  const Text(
                    'El área disponible no alcanza: el contratista revisará opciones',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
