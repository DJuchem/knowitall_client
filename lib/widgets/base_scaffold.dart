import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'client_settings_dialog.dart';

class BaseScaffold extends StatelessWidget {
  final Widget body;
  final AppBar? appBar;
  final Widget? floatingActionButton;
  final bool extendBodyBehindAppBar;
  final bool showSettings; // New flag

  const BaseScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.extendBodyBehindAppBar = false,
    this.showSettings = true, // Default to true
  });

  // HELPER: Sanitize path to prevent "assets/assets/..." error
  String _cleanPath(String path) {
    if (path.startsWith("assets/") && path.indexOf("assets/", 1) > -1) {
      return path.replaceFirst("assets/", "");
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBar ?? (showSettings ? AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Don't show back arrow by default here
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: isDark ? Colors.white70 : Colors.black87, size: 32),
            onPressed: () => showDialog(context: context, builder: (_) => ClientSettingsDialog()),
          )
        ],
      ) : null),
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          // 1. Wallpaper
          Positioned.fill(
            child: Image.asset(
              _cleanPath(game.wallpaper),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0F1221)),
            ),
          ),
          
          // 2. Tint
          Positioned.fill(
            child: Container(
              color: isDark 
                ? Colors.black.withValues(alpha: 0.6) 
                : Colors.white.withValues(alpha: 0.85),
            ),
          ),

          // 3. Settings Overlay (if using custom AppBar)
          if (showSettings && appBar != null)
            Positioned(
              top: 40, right: 20,
              child: IconButton(
                icon: Icon(Icons.settings, color: isDark ? Colors.white70 : Colors.black87, size: 32),
                onPressed: () => showDialog(context: context, builder: (_) => ClientSettingsDialog()),
              ),
            ),

          // 4. Body
          SafeArea(child: body),
        ],
      ),
    );
  }
}