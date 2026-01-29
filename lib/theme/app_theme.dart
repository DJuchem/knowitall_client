import 'package:flutter/material.dart';
import 'dart:ui';

class AppTheme {
  static const Color primaryDark = Color(0xFF0F1221);
  static const Color primaryLight = Color(0xFFF0F2F5);
  static const Color accentPink = Color(0xFFFF58CC);
  static const Color accentBlue = Color(0xFF47C8FF);

  // --- DARK THEME ---
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryDark,
      primaryColor: primaryDark,
      colorScheme: const ColorScheme.dark(
        primary: accentPink,
        secondary: accentBlue,
        surface: Color(0xFF1E1E2C),
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 18, height: 1.4),
        bodyLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        labelLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  // --- LIGHT THEME ---
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: primaryLight,
      primaryColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF6200EA),
        secondary: accentPink,
        surface: Colors.white,
        onSurface: Colors.black87,
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 18, color: Colors.black87, height: 1.4),
        bodyLarge: TextStyle(fontSize: 22, color: Colors.black87, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.black),
        labelLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.black12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double blur;

  const GlassContainer({
    super.key,
    required this.child, 
    this.padding = const EdgeInsets.all(24), 
    this.margin = const EdgeInsets.all(16), 
    this.blur = 15
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.65), 
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}