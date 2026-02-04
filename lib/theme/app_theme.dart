import 'package:flutter/material.dart';
import 'dart:ui';

class AppColorScheme {
  final String name;
  final Color primary;
  final Color secondary;
  final Color surface;
  final Color background;
  final Color onBackground;
  final OutlinedBorder buttonShape;
  final InputBorder inputShape;

  const AppColorScheme({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.background,
    required this.onBackground,
    required this.buttonShape,
    required this.inputShape,
  });
}

class AppTheme {
  // --- DEFINED THEMES ---
  static final Map<String, AppColorScheme> schemes = {
    "Cyberpunk": AppColorScheme(
      name: "Cyberpunk",
      primary: const Color(0xFFFF00FF), // Neon Pink
      secondary: const Color(0xFF00FFFF), // Cyan
      surface: const Color(0xFF1E1E2C),
      background: const Color(0xFF050510),
      onBackground: Colors.white,
      buttonShape: const BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
      inputShape: const CutCornerBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(10))),
    ),
    "Inferno": AppColorScheme( // 🔥 NEW COOLER THEME
      name: "Inferno",
      primary: const Color(0xFFFF3D00), // Magma Red
      secondary: const Color(0xFFFF9100), // Ember Orange
      surface: const Color(0xFF2D0C0C), // Dark Red/Brown
      background: const Color(0xFF140505), // Charred Black
      onBackground: const Color(0xFFFFE0B2),
      // Aggressive sharp angles
      buttonShape: const BeveledRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(15), bottomRight: Radius.circular(15))),
      inputShape: const OutlineInputBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(15), bottomRight: Radius.circular(15)), borderSide: BorderSide.none),
    ),
    "Galactic": AppColorScheme( // 🌌 NEW COOLER THEME
      name: "Galactic",
      primary: const Color(0xFF7C4DFF), // Nebula Purple
      secondary: const Color(0xFF00E5FF), // Starlight Blue
      surface: const Color(0xFF151529), 
      background: const Color(0xFF080812), // Deep Space
      onBackground: const Color(0xFFE8EAF6),
      // Smooth, futuristic pill shapes
      buttonShape: const StadiumBorder(),
      inputShape: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
    ),
    "Matrix": AppColorScheme(
      name: "Matrix",
      primary: const Color(0xFF00FF41),
      secondary: const Color(0xFF008F11),
      surface: const Color(0xFF111111),
      background: const Color(0xFF000000),
      onBackground: const Color(0xFFE0FFE0),
      buttonShape: const BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
      inputShape: OutlineInputBorder(borderRadius: BorderRadius.circular(0), borderSide: const BorderSide(color: Color(0xFF00FF41))),
    ),
    "Nature": AppColorScheme(
      name: "Nature",
      primary: const Color(0xFF66BB6A),
      secondary: const Color(0xFF8D6E63),
      surface: const Color(0xFF1B3A25),
      background: const Color(0xFF0C1C11),
      onBackground: const Color(0xFFE8F5E9),
      buttonShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      inputShape: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
    ),
    "Ocean": AppColorScheme(
      name: "Ocean",
      primary: const Color(0xFF00E5FF),
      secondary: const Color(0xFF2979FF),
      surface: const Color(0xFF102A43),
      background: const Color(0xFF081221),
      onBackground: const Color(0xFFE3F2FD),
      buttonShape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(40)),
      inputShape: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    ),
    "Royal": AppColorScheme(
      name: "Royal",
      primary: const Color(0xFFFFD700),
      secondary: const Color(0xFF7B1FA2),
      surface: const Color(0xFF2A0F35),
      background: const Color(0xFF15041D),
      onBackground: const Color(0xFFF3E5F5),
      buttonShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      inputShape: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    ),
  };

  static ThemeData getTheme(String schemeName, Brightness brightness) {
    final scheme = schemes[schemeName] ?? schemes["Cyberpunk"]!;
    final isDark = brightness == Brightness.dark;

    final bgColor = isDark ? scheme.background : const Color(0xFFF2F5F8);
    final surfaceColor = isDark ? scheme.surface : Colors.white;
    final textColor = isDark ? scheme.onBackground : Colors.black87;

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: bgColor,
      primaryColor: scheme.primary,
      
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: scheme.primary,
        onPrimary: isDark ? Colors.black : Colors.white,
        secondary: scheme.secondary,
        onSecondary: isDark ? Colors.black : Colors.white,
        error: Colors.redAccent,
        onError: Colors.white,
        surface: surfaceColor,
        onSurface: textColor,
      ),

      fontFamily: 'Roboto',
      
      textTheme: TextTheme(
        bodyMedium: TextStyle(fontSize: 16, height: 1.4, color: textColor),
        bodyLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
        titleLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: textColor),
        labelLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
        border: scheme.inputShape, 
        enabledBorder: scheme.inputShape.copyWith(borderSide: BorderSide(color: textColor.withOpacity(0.1))),
        focusedBorder: scheme.inputShape.copyWith(borderSide: BorderSide(color: scheme.primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: TextStyle(color: textColor.withOpacity(0.5), fontSize: 16),
        prefixIconColor: scheme.primary,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: isDark ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
          shape: scheme.buttonShape,
          elevation: 6,
          shadowColor: scheme.primary.withOpacity(0.5),
        ),
      ),

      iconTheme: IconThemeData(color: scheme.primary),
    );
  }
}

class CutCornerBorder extends OutlineInputBorder {
  const CutCornerBorder({super.borderSide, super.borderRadius});
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
    this.margin = EdgeInsets.zero, 
    this.blur = 12
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
        color: theme.colorScheme.surface.withOpacity(0.7), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), 
            blurRadius: 20, 
            spreadRadius: 2, 
            offset: const Offset(0, 8)
          )
        ],
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