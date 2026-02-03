import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class BaseScaffold extends StatelessWidget {
  final Widget body;
  final bool showSettings;
  final bool extendBodyBehindAppBar;
  final PreferredSizeWidget? appBar;
  final VoidCallback? onSettingsTap; // ✅ NEW: Callback for settings

  const BaseScaffold({
    super.key,
    required this.body,
    this.showSettings = false,
    this.extendBodyBehindAppBar = false,
    this.appBar,
    this.onSettingsTap, // ✅ NEW
  });

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final bgPath = game.wallpaper;

    // Clean path logic duplicated here just for safety, though Provider usually handles it
    String cleanBg = bgPath;
    while (cleanBg.startsWith("assets/") || cleanBg.startsWith("/assets/")) {
      cleanBg = cleanBg.replaceFirst("assets/", "").replaceFirst("/assets/", "");
    }

    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar || appBar != null,
      appBar: appBar ?? (showSettings
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white, size: 30),
                    // ✅ FIX: Call the passed function
                    onPressed: onSettingsTap, 
                  ),
                )
              ],
            )
          : null),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              "assets/$cleanBg",
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0F1221)),
            ),
          ),
          // Dark Overlay
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          // Content
          SafeArea(
            top: !extendBodyBehindAppBar && appBar == null, // Handle safe area manually if no appbar
            child: body,
          ),
        ],
      ),
    );
  }
}