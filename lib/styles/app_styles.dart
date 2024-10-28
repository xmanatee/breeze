import 'package:flutter/material.dart';

class AppStyles {
  static const double borderRadius = 16.0;

  static ThemeData appTheme = _buildTheme();

  // Updated colors
  static Color primaryColor = const Color(0xFF38D5FF);
  static Color secondaryColor = const Color(0xFF36C2FF);
  static Color accentColor = const Color(0xFF34B0FF);
  static Color darkGrey = const Color(0xFF2C2C2C);
  static Color lightGrey = const Color(0xFFF2F2F2);
  static Color pastelYellow = const Color(0xFFFFF9C4);
  static Color backgroundColor = const Color(0xFFFFFFFF);
  static Color textColor = const Color(0xFF333333);

  static ThemeData _buildTheme() {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: secondaryColor,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: textColor,
      error: Colors.redAccent,
      onError: Colors.white,
    );

    return ThemeData(
      colorScheme: colorScheme,
      primaryColor: colorScheme.primary,
      scaffoldBackgroundColor: colorScheme.surface,
      fontFamily: 'Roboto',
      textTheme: TextTheme(
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: colorScheme.onSurface,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  static TextStyle headingTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static TextStyle bodyTextStyle = TextStyle(
    fontSize: 14,
    color: textColor,
  );
}
