import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF000000),
    primaryColor: Colors.cyan[400],
    iconTheme: const IconThemeData(color: Colors.white),
    cardColor: const Color(0xFF141414),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFEEEEEE)), // text
      bodyMedium: TextStyle(color: Color(0xFFAAAAAA)), // subtext
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF2F2F7),
    primaryColor: Colors.blue[600],
    iconTheme: const IconThemeData(color: Colors.black),
    cardColor: const Color(0xFFFFFFFF),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF000000)), // text
      bodyMedium: TextStyle(color: Color(0xFF666666)), // subtext
    ),
  );
  
  // Custom colors that are not in standard ThemeData
  static const Color darkGlass = Color(0x1AFFFFFF); // #1AFFFFFF
  static const Color lightGlass = Color(0x99FFFFFF); // Opacity 0.6 -> 0x99
  
  static const Color darkAccent = Colors.cyanAccent; // closest to CYAN_400
  static const Color lightAccent = Colors.blue; 
}
