import 'dart:ui';
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF0F1221);
  static const Color accentPink = Color(0xFFFF58CC);
  static const Color accentBlue = Color(0xFF47C8FF);
  static const Color surfaceColor = Color(0xFF1E1E2C); 

  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryColor,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: accentPink,
        secondary: accentBlue,
        surface: surfaceColor,
      ),
      fontFamily: 'Roboto',
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // Fixed: Use withValues(alpha:) instead of withOpacity()
        fillColor: Colors.black.withValues(alpha: 0.3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. The Background (Mimics CSS Radial Gradients)
// ---------------------------------------------------------------------------
class CyberpunkBackground extends StatelessWidget {
  final Widget child;
  const CyberpunkBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark Base
        Container(color: AppTheme.primaryColor),
        
        // Top-Left Pink Glow
        Positioned(
          top: -100, left: -100,
          child: Container(
            width: 400, height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.accentPink.withValues(alpha: 0.15), // Fixed
                  Colors.transparent
                ],
              ),
            ),
          ),
        ),
        
        // Bottom-Right Blue Glow
        Positioned(
          bottom: -100, right: -100,
          child: Container(
            width: 400, height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.accentBlue.withValues(alpha: 0.15), // Fixed
                  Colors.transparent
                ],
              ),
            ),
          ),
        ),
        
        // The actual content wrapped in SafeArea
        SafeArea(child: child),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 2. The Glass Card (Mimics backdrop-filter: blur)
// ---------------------------------------------------------------------------
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const GlassContainer({
    Key? key, 
    required this.child, 
    this.padding = const EdgeInsets.all(24),
    this.margin = const EdgeInsets.all(16)
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)), // Fixed
        color: Colors.white.withValues(alpha: 0.05), // Fixed
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // The Real Blur
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}