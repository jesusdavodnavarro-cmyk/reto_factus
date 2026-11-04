import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // Constructor privado para evitar instanciación

  // Paleta inspirada en el Caribe (Córdoba) y energía renovable
  static const Color primaryGreen = Color(0xFF2E7D32); // Verde Sinú (Sabana)
  static const Color secondaryBlue = Color(0xFF0277BD); // Azul Río (Río Sinú)

  // Fondos y superficies
  static const Color background = Color(0xFFF5F7FA); // Gris Nube (Claridad)
  static const Color surface = Colors.white; // Tarjetas y contenedores

  // Tipografía y bordes
  static const Color textDark = Color(0xFF2D3748); // Gris Pizarra (Legibilidad)
  static const Color textLight = Color(0xFF718096); // Texto secundario
  static const Color border = Color(0xFFE2E8F0); // Líneas sutiles

  // Estados
  static const Color error = Color(0xFFE53935); // Alertas
  static const Color success = Color(0xFF43A047); // Éxito en pagos
}

class AppSizes {
  AppSizes._();

  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  static const double borderRadius = 12.0;
  static const double buttonHeight = 52.0;
}
