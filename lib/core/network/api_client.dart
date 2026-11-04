import 'package:dio/dio.dart';

/// URL del backend. Se cambia al ejecutar, sin tocar código:
///   flutter run -d chrome --dart-define=API_URL=http://localhost:3000/api
///
/// IMPORTANTE: esta app corre en el navegador; aquí NUNCA van credenciales
/// de Factus. Todo lo de Factus lo hace el backend.
const String apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:3000/api',
);

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
