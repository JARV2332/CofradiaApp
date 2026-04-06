import 'package:flutter/material.dart';

class CofradiaTheme {
  // Colores de la Cofradía
  static const Color azulCofradia = Color(0xFF1565C0); // Azul principal
  static const Color amarilloCofradia = Color(0xFFFFD700); // Amarillo dorado
  static const Color rojoCofradia = Color(0xFFD32F2F); // Rojo intenso
  static const Color blancoCofradia = Color(0xFFFFFFFF); // Blanco puro
  
  // Colores secundarios y variaciones
  static const Color azulOscuro = Color(0xFF0D47A1);
  static const Color azulClaro = Color(0xFF42A5F5);
  static const Color amarilloClaro = Color(0xFFFFF176);
  static const Color rojoClaro = Color(0xFFE57373);
  static const Color grisClaro = Color(0xFFF5F5F5);
  static const Color grisMedio = Color(0xFF9E9E9E);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      // Esquema de colores principal
      colorScheme: ColorScheme.fromSeed(
        seedColor: azulCofradia,
        primary: azulCofradia,
        secondary: amarilloCofradia,
        tertiary: rojoCofradia,
        surface: blancoCofradia,
        brightness: Brightness.light,
      ),
      
      // AppBar personalizada
      appBarTheme: AppBarTheme(
        backgroundColor: azulCofradia,
        foregroundColor: blancoCofradia,
        elevation: 4,
        shadowColor: azulOscuro.withOpacity(0.3),
        titleTextStyle: const TextStyle(
          color: blancoCofradia,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: blancoCofradia),
      ),

      // FloatingActionButton
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: rojoCofradia,
        foregroundColor: blancoCofradia,
        elevation: 8,
        focusElevation: 12,
        hoverElevation: 10,
        splashColor: rojoClaro,
      ),

      // Cards
      cardTheme: CardThemeData(
        color: blancoCofradia,
        elevation: 3,
        shadowColor: azulCofradia.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: azulClaro.withOpacity(0.3), width: 1),
        ),
      ),

      // Botones
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: azulCofradia,
          foregroundColor: blancoCofradia,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: azulCofradia,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: azulCofradia,
          side: const BorderSide(color: azulCofradia, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // Formularios
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: azulClaro),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: azulClaro.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: azulCofradia, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: rojoCofradia, width: 2),
        ),
        labelStyle: const TextStyle(color: azulCofradia),
        prefixIconColor: azulCofradia,
        suffixIconColor: azulCofradia,
      ),

      // Dropdowns
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: const TextStyle(color: azulCofradia),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(blancoCofradia),
          elevation: WidgetStateProperty.all(8),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),

      // Diálogos
      dialogTheme: DialogThemeData(
        backgroundColor: blancoCofradia,
        elevation: 16,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          color: azulCofradia,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
        ),
      ),

      // SnackBars
      snackBarTheme: SnackBarThemeData(
        backgroundColor: azulOscuro,
        contentTextStyle: const TextStyle(color: blancoCofradia),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),

      // PopupMenu
      popupMenuTheme: PopupMenuThemeData(
        color: blancoCofradia,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(color: azulCofradia),
      ),

      // Scaffold
      scaffoldBackgroundColor: grisClaro,

      // Iconos
      iconTheme: const IconThemeData(color: azulCofradia),

      // Dividers
      dividerTheme: DividerThemeData(
        color: azulClaro.withOpacity(0.3),
        thickness: 1,
      ),

      // ListTiles
      listTileTheme: ListTileThemeData(
        iconColor: azulCofradia,
        textColor: Colors.black87,
        tileColor: blancoCofradia,
        selectedTileColor: azulClaro.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Método para obtener gradientes de la cofradía
  static LinearGradient get gradientePrincipal {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [azulCofradia, azulClaro],
      stops: [0.0, 1.0],
    );
  }

  static LinearGradient get gradienteSecundario {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [amarilloCofradia, amarilloClaro],
      stops: [0.0, 1.0],
    );
  }

  static LinearGradient get gradienteAccento {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [rojoCofradia, rojoClaro],
      stops: [0.0, 1.0],
    );
  }

  // Colores para estados específicos
  static Color get colorExito => const Color(0xFF4CAF50);
  static Color get colorAdvertencia => amarilloCofradia;
  static Color get colorError => rojoCofradia;
  static Color get colorInfo => azulCofradia;
}