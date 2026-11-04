import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

const String _apiUrlDefinida = String.fromEnvironment('API_URL');

/// URL del backend:
/// 1. Si se pasa al ejecutar, se usa esa:
///      flutter run -d chrome --dart-define=API_URL=http://192.168.1.76:3000/api
/// 2. En producción web (Render), la app la sirve el mismo backend:
///    misma URL del sitio + /api  (ej. https://sol-a-cuotas.onrender.com/api)
/// 3. Si no, el backend local.
///
/// IMPORTANTE: esta app corre en el navegador; aquí NUNCA van credenciales
/// de Factus. Todo lo de Factus lo hace el backend.
final String apiUrl = _apiUrlDefinida.isNotEmpty
    ? _apiUrlDefinida
    : (kIsWeb && kReleaseMode)
        ? '${Uri.base.origin}/api'
        : 'http://localhost:3000/api';

/// Error del backend ya traducido para mostrarlo en la UI.
class ApiException implements Exception {
  final String mensaje;

  /// Errores por campo cuando el backend responde 400.
  /// Ej: {'facturacion.email': 'Inválido dirección de correo electrónico'}
  final Map<String, String> campos;
  final int? status;

  const ApiException(this.mensaje, {this.campos = const {}, this.status});

  @override
  String toString() => mensaje;
}

/// Cliente HTTP único de la app.
Dio crearDio() {
  return Dio(
    BaseOptions(
      baseUrl: apiUrl,
      connectTimeout: const Duration(seconds: 10),
      // Facturar valida ante la DIAN: puede tardar varios segundos
      receiveTimeout: const Duration(seconds: 40),
      headers: {'Accept': 'application/json'},
    ),
  );
}

/// Convierte cualquier error (de Dio u otro) en un ApiException en español.
/// El backend responde { error, campos?: [{ campo, mensaje }] }.
ApiException traducirError(Object error) {
  if (error is ApiException) return error;

  if (error is DioException) {
    final response = error.response;
    if (response == null) {
      return const ApiException(
        'No hay conexión con el servidor. ¿Está corriendo el backend?',
      );
    }

    var mensaje = 'Error ${response.statusCode} del servidor';
    final campos = <String, String>{};
    final data = response.data;

    if (data is Map) {
      if (data['error'] is String) mensaje = data['error'] as String;
      final lista = data['campos'];
      if (lista is List) {
        for (final item in lista) {
          if (item is Map && item['campo'] != null) {
            campos[item['campo'].toString()] = item['mensaje'].toString();
          }
        }
      }
    }
    return ApiException(mensaje, campos: campos, status: response.statusCode);
  }

  return ApiException('Error inesperado: $error');
}
