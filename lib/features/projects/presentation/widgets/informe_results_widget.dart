import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/informe_provider.dart';
import 'amortizacion_tab.dart';
import 'ficha_tecnica_tab.dart';
import 'contrato_tab.dart';

class InformeResultsWidget extends ConsumerStatefulWidget {
  const InformeResultsWidget({super.key});

  @override
  ConsumerState<InformeResultsWidget> createState() =>
      _InformeResultsWidgetState();
}

class _InformeResultsWidgetState extends ConsumerState<InformeResultsWidget> {
  int _selectedIndex = 0; // 0: Amortización, 1: Ficha, 2: Contrato

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(informeProvider);
    final tema = Theme.of(context);
    final formatoMoneda = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    if (estado.solicitud == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Resumen Financiero Rápido
        Card(
          elevation: 0,
          color: tema.colorScheme.primary.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: tema.colorScheme.primary.withValues(alpha: 0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Presupuesto Inicial (40%): ${formatoMoneda.format(estado.anticipo)}',
                  style: tema.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: tema.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Saldo a Financiar: ${formatoMoneda.format(estado.saldoFinanciar)}',
                  style: tema.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Costo Total Proyecto: ${formatoMoneda.format(estado.costoTotal)}',
                  style: tema.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Orquestador de Pestañas (Chips)
        Wrap(
          spacing: 8.0,
          alignment: WrapAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('Tabla de Amortización'),
              selected: _selectedIndex == 0,
              onSelected: (val) => setState(() => _selectedIndex = 0),
            ),
            ChoiceChip(
              label: const Text('Ficha Técnica'),
              selected: _selectedIndex == 1,
              onSelected: (val) => setState(() => _selectedIndex = 1),
            ),
            ChoiceChip(
              label: const Text('Contrato'),
              selected: _selectedIndex == 2,
              onSelected: (val) => setState(() => _selectedIndex = 2),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Renderizado condicional de la pestaña seleccionada
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _construirPestanaActual(estado),
        ),
      ],
    );
  }

  Widget _construirPestanaActual(InformeState estado) {
    switch (_selectedIndex) {
      case 0:
        return AmortizacionTab(cuotas: estado.tablaAmortizacion ?? []);
      case 1:
        return FichaTecnicaTab(costoTotal: estado.costoTotal ?? 0);
      case 2:
        return ContratoTab(
          cliente:
              estado.solicitud?.facturacion.razonSocial ??
              estado.solicitud?.facturacion.nombres ??
              '',
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
