import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/informe_provider.dart';
import '../widgets/informe_form_widget.dart';
import '../widgets/informe_results_widget.dart';

class ClienteDashboardScreen extends ConsumerWidget {
  const ClienteDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estadoInforme = ref.watch(informeProvider);
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Colombia Solar Pymes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Perfil del Cliente',
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Simulador de Proyecto Solar',
                style: tema.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Calcula el costo, tabla de amortización y beneficios técnicos de tu sistema.',
                style: tema.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              // Lógica de renderizado limpia y DRY
              // Sin proyecto todavía -> formulario; con proyecto -> resultados
              if (!estadoInforme.tieneResultado)
                const InformeFormWidget()
              else
                const InformeResultsWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
