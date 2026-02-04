import 'package:flutter/material.dart';
import 'dart:ui';

class AppColorScheme {
  final String name;
  final Color primary;
  final Color secondary;
  final Color surface;
  final Color onBackground;
  final OutlinedBorder buttonShape;
  final InputBorder inputShape;
  final ShapeBorder cardShape;

  const AppColorScheme({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.onBackground,
    required this.buttonShape,
    required this.inputShape,
    required this.cardShape,
  });
}

class AppTheme {
  static final Map<String, AppColorScheme> schemes = {
    "Default": AppColorScheme(
      name: "Default",
      primary: const Color(0xFFE91E63), 
      secondary: const Color(0xFF2196F3), 
      surface: const Color(0xFF1E1E2C),
      onBackground: Colors.white,
      buttonShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      inputShape: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      cardShape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    "Cyberpunk": AppColorScheme(
      name: "Cyberpunk",
      primary: const Color(0xFFFF00FF), 
      secondary: const Color(0xFF00FFFF),
      surface: const Color(0xFF1E1E2C),
      onBackground: Colors.white,
      buttonShape: const BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
      inputShape: const CutCornerBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(10))),
      cardShape: const BeveledRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    ),
    "Matrix": AppColorScheme(
      name: "Matrix",
      primary: const Color(0xFF00FF41),
      secondary: const Color(0xFF008F11),
      surface: const Color(0xFF111111),
      onBackground: const Color(0xFFE0FFE0),
      buttonShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(2))),
      inputShape: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(2)), borderSide: BorderSide(color: Color(0xFF00FF41))),
      cardShape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(4))),
    ),
    "Galactic": AppColorScheme(
      name: "Galactic",
      primary: const Color(0xFF7C4DFF),
      secondary: const Color(0xFF00E5FF),
      surface: const Color(0xFF151529),
      onBackground: const Color(0xFFE8EAF6),
      buttonShape: const StadiumBorder(),
      inputShape: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      cardShape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
    ),
    "Inferno": AppColorScheme(
      name: "Inferno",
      primary: const Color(0xFFFF3D00),
      secondary: const Color(0xFFFF9100),
      surface: const Color(0xFF2D0C0C),
      onBackground: const Color(0xFFFFE0B2),
      buttonShape: const BeveledRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(15), bottomRight: Radius.circular(15))),
      inputShape: const OutlineInputBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(15), bottomRight: Radius.circular(15)), borderSide: BorderSide.none),
      cardShape: const BeveledRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    ),
    "Nature": AppColorScheme(
      name: "Nature",
      primary: const Color(0xFF66BB6A),
      secondary: const Color(0xFF8D6E63),
      surface: const Color(0xFF1B3A25),
      onBackground: const Color(0xFFE8F5E9),
      buttonShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      inputShape: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
      cardShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
    ),
    "Ocean": AppColorScheme(
      name: "Ocean",
      primary: const Color(0xFF00E5FF),
      secondary: const Color(0xFF2979FF),
      surface: const Color(0xFF102A43),
      onBackground: const Color(0xFFE3F2FD),
      buttonShape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(40)),
      inputShape: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      cardShape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(40)),
    ),
    "Royal": AppColorScheme(
      name: "Royal",
      primary: const Color(0xFFFFD700),
      secondary: const Color(0xFF7B1FA2),
      surface: const Color(0xFF2A0F35),
      onBackground: const Color(0xFFF3E5F5),
      buttonShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      inputShape: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      cardShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  };

  static ThemeData getTheme(String schemeName, Brightness brightness) {
    final scheme = schemes[schemeName] ?? schemes["Default"]!;
    final isDark = brightness == Brightness.dark;

    // Independent background fallback (Wallpaper is handled by BaseScaffold)
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF0F2F5); 
    final surfaceColor = isDark ? scheme.surface : const Color(0xFFFFFFFF);
    final textColor = isDark ? scheme.onBackground : Colors.black;
    final hintColor = isDark ? scheme.onBackground.withOpacity(0.5) : Colors.black54;

    final primaryColor = scheme.primary; 

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: bgColor,
      primaryColor: primaryColor,
      cardColor: surfaceColor,
      
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        onPrimary: isDark ? Colors.black : Colors.white,
        secondary: scheme.secondary,
        onSecondary: Colors.white,
        error: Colors.redAccent,
        onError: Colors.white,
        surface: surfaceColor,
        onSurface: textColor,
      ),

      fontFamily: 'Roboto',
      
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        shape: scheme.cardShape,
        modalBackgroundColor: surfaceColor,
      ),

      dialogBackgroundColor: surfaceColor,

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
        border: scheme.inputShape, 
        enabledBorder: scheme.inputShape.copyWith(borderSide: BorderSide(color: textColor.withOpacity(0.2))),
        focusedBorder: scheme.inputShape.copyWith(borderSide: BorderSide(color: primaryColor, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: TextStyle(color: hintColor),
        labelStyle: TextStyle(color: textColor),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: isDark ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
          shape: scheme.buttonShape,
          elevation: isDark ? 6 : 2,
        ),
      ),
      
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: textColor.withOpacity(0.2),
        thumbColor: primaryColor,
        overlayColor: primaryColor.withOpacity(0.2),
      ),

      iconTheme: IconThemeData(color: primaryColor),
      
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: textColor),
        bodyLarge: TextStyle(color: textColor),
        titleLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: textColor),
        labelLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      ).apply(bodyColor: textColor, displayColor: textColor),
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
        color: theme.colorScheme.surface.withOpacity(isDark ? 0.7 : 0.9), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), 
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