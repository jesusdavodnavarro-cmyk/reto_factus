import 'package:go_router/go_router.dart';
import '../../features/projects/presentation/screens/cliente_dashboard_screen.dart';

// Configuración global de rutas de la aplicación
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'cliente_dashboard',
      // Apunta a la pantalla principal que crearemos en el Bloque 5
      builder: (context, state) => const ClienteDashboardScreen(),
    ),
    // Aquí agregaremos luego las rutas del Contratista
  ],
);
