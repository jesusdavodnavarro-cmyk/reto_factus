import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../providers/informe_provider.dart';
import 'amortizacion_tab.dart';
import 'contrato_tab.dart';
import 'ficha_tecnica_tab.dart';

/// Resultado real que devolvió el backend: proyecto, subsidio y cuotas.
class InformeResultsWidget extends ConsumerStatefulWidget {
  const InformeResultsWidget({super.key});

  @override
  ConsumerState<InformeResultsWidget> createState() => _InformeResultsWidgetState();
}

class _InformeResultsWidgetState extends ConsumerState<InformeResultsWidget> {
  int _selectedIndex = 0; // 0: Plan de pagos, 1: Ficha técnica, 2: Contrato

  final _moneda = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(informeProvider);
    final proyecto = estado.proyecto;
    final tema = Theme.of(context);

    if (proyecto == null) return const SizedBox.shrink();

    final consumoKwh = estado.solicitudCreada?.consumoKwhMes ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Resumen financiero (todo viene del backend)
        Card(
          elevation: 0,
          color: tema.colorScheme.primary.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: tema.colorScheme.primary.withValues(alpha: 0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Proyecto ${proyecto.id} · Solicitud ${proyecto.solicitudId}',
                  style: tema.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Sistema de ${proyecto.potenciaKwp.toStringAsFixed(2)} kWp '
                  'para ${consumoKwh.toStringAsFixed(0)} kWh/mes',
                  style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _fila('Valor total del proyecto', _moneda.format(proyecto.valorTotalCop)),
                _fila(
                  'Subsidio Colombia Solar (${proyecto.subsidioPct.toStringAsFixed(0)} %)',
                  '− ${_moneda.format(proyecto.subsidioCop)}',
                  color: AppColors.success,
                ),
                const Divider(),
                _fila(
                  'Tú pagas en ${proyecto.cuotas.length} cuotas',
                  _moneda.format(proyecto.financiadoCop),
                  color: tema.colorScheme.primary,
                  negrita: true,
                ),
                const SizedBox(height: 8),
                // Conciliación en tiempo real (se recalcula en el backend con cada pago)
                _fila(
                  'Recaudado (${proyecto.resumen.cuotasPagadas}/${proyecto.resumen.cuotasTotales} cuotas)',
                  _moneda.format(proyecto.resumen.recaudadoCop),
                  color: AppColors.success,
                ),
                _fila('Pendiente', _moneda.format(proyecto.resumen.pendienteCop)),
                if (proyecto.resumen.enMoraCop > 0)
                  _fila(
                    'En mora',
                    _moneda.format(proyecto.resumen.enMoraCop),
                    color: AppColors.error,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        Wrap(
          spacing: 8,
          alignment: WrapAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('Plan de pagos'),
              selected: _selectedIndex == 0,
              onSelected: (_) => setState(() => _selectedIndex = 0),
            ),
            ChoiceChip(
              label: const Text('Ficha técnica'),
              selected: _selectedIndex == 1,
              onSelected: (_) => setState(() => _selectedIndex = 1),
            ),
            ChoiceChip(
              label: const Text('Contrato'),
              selected: _selectedIndex == 2,
              onSelected: (_) => setState(() => _selectedIndex = 2),
            ),
          ],
        ),
        const SizedBox(height: 24),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: KeyedSubtree(
            key: ValueKey(_selectedIndex),
            child: switch (_selectedIndex) {
              0 => AmortizacionTab(cuotas: proyecto.cuotas),
              1 => FichaTecnicaTab(
                  potenciaKwp: proyecto.potenciaKwp,
                  consumoKwhMes: consumoKwh,
                  areaDisponibleM2: estado.solicitud?.areaDisponibleM2,
                ),
              _ => ContratoTab(cliente: proyecto.cliente),
            },
          ),
        ),

        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => ref.read(informeProvider.notifier).reiniciar(),
          icon: const Icon(Icons.refresh),
          label: const Text('Nueva simulación'),
        ),
      ],
    );
  }

  Widget _fila(String etiqueta, String valor, {Color? color, bool negrita = false}) {
    final estilo = TextStyle(
      color: color,
      fontWeight: negrita ? FontWeight.bold : FontWeight.w500,
      fontSize: negrita ? 16 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(etiqueta, style: estilo)),
          Text(valor, style: estilo),
        ],
      ),
    );
  }
}
