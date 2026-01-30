import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'client_settings_dialog.dart';

class BaseScaffold extends StatelessWidget {
  final Widget body;
  final AppBar? appBar;
  final Widget? floatingActionButton;
  final bool extendBodyBehindAppBar;
  final bool showSettings;

  const BaseScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.extendBodyBehindAppBar = false,
    this.showSettings = true,
  });

  String cleanPath(String path) {
    if (path.startsWith("assets/") && path.indexOf("assets/", 1) > -1) {
      return path.replaceFirst("assets/", "");
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final AppBar? effectiveAppBar = appBar ??
        (showSettings
            ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: IconButton(
                      icon: Icon(
                        Icons.settings,
                        color: isDark ? Colors.white70 : Colors.black87,
                        size: 30,
                      ),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => ClientSettingsDialog(), // ← FIXED
                      ),
                    ),
                  ),
                ],
              )
            : null);

    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: effectiveAppBar,
      floatingActionButton: floatingActionButton,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Wallpaper
          Positioned.fill(
            child: Image.asset(
              cleanPath(game.wallpaper),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: Color(0xFF0F1221)),
            ),
          ),

          // Tint
          Positioned.fill(
            child: Container(
              color: isDark
                  ? Colors.black.withOpacity(0.6)
                  : Colors.white.withOpacity(0.85),
            ),
          ),

          // Content (safe from AppBar)
          SafeArea(
            top: !extendBodyBehindAppBar,
            bottom: true,
            child: body,
          ),
        ],
      ),
    );
  }
}
