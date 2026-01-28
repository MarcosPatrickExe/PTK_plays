import 'package:flutter/material.dart';

class AppThemes {
  
  static const darkBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F2027),
      Color(0xFF203A43),
      Color(0xFF2C5364),
    ],
  );

  static const lightBackground = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [
      Color.fromARGB(31, 202, 215, 215),
      Color.fromARGB(255, 165, 171, 173),
      Color(0xFFDCE6EB),
    ],
  );

  static const darkCard = LinearGradient(
    colors: [
      Color(0xFF1A2A33),
      Color(0xFF243B55),
    ],
  );

  static const lightCard = LinearGradient(
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF1F5F9),
    ],
  );

  static const darkAccent = Color(0xFF00E5FF);
  static const lightAccent = Color(0xFF0066FF);
}
