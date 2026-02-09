import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemes {
  
  static ThemeData lightTheme = ThemeData(
      primaryColor: Color(0xFF0479FF),
      shadowColor: Color(0x883F3F3F),
      brightness: Brightness.light,
      fontFamily: GoogleFonts.goldman(  textStyle: TextStyle( fontWeight: FontWeight.bold, fontSize: 22.0, color: const Color(0xFF235525), ) ).fontFamily,
      useMaterial3: true,
      textTheme: TextTheme(
        titleLarge: TextStyle( fontSize: 12.0 )
      )
  );
  
  static ThemeData darkTheme = ThemeData(
      primaryColor: Color(0xFFDEDEDE),
      shadowColor: Color(0x86161616),
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.abhayaLibre( textStyle: TextStyle( fontWeight: FontWeight.bold, fontSize: 12.0, color: Colors.purple) ).fontFamily,
      useMaterial3: true,
  );
  
  
  
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
      Color(0xA3E2E2E2),
      Color(0xFFCDD1D2),
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
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFE6E6E6),
      Color(0xFFF1F5F9),
    ],
  );

  static const darkAccent = Color(0xFF00E5FF);
  static const lightAccent = Color(0xFF0066FF);
}
