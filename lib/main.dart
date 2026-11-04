import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ProviderScope es obligatorio para que Riverpod funcione en toda la app
  runApp(const ProviderScope(child: RetoFactusApp()));
}

class RetoFactusApp extends StatelessWidget {
  const RetoFactusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Colombia Solar Pymes',
      debugShowCheckedModeBanner: false, // Oculta la etiqueta de "DEBUG"
      theme: AppTheme.lightTheme, // Inyectamos nuestra estética
      routerConfig: appRouter, // Inyectamos la navegación
    );
  }
}
