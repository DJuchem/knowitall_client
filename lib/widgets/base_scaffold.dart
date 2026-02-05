import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class BaseScaffold extends StatelessWidget {
  final Widget body;
  final bool showSettings;
  final bool extendBodyBehindAppBar;
  final PreferredSizeWidget? appBar;
  final VoidCallback? onSettingsTap;

  const BaseScaffold({
    super.key,
    required this.body,
    this.showSettings = false,
    this.extendBodyBehindAppBar = false,
    this.appBar,
    this.onSettingsTap,
  });


String _ensureAssetKey(String raw) {
  if (raw.isEmpty) return raw;
  if (raw.startsWith("data:") || raw.startsWith("http")) return raw;
  var p = raw;
  if (p.startsWith("/")) p = p.substring(1);
  if (!p.startsWith("assets/")) p = "assets/$p";
  return p;
}

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    
    // ✅ FIX: Smart Asset Path Handling
    String bgPath = _ensureAssetKey(game.wallpaper);
    // If it doesn't start with assets/ and isn't a web url/data uri, add assets/
    if (!bgPath.startsWith("assets/") && !bgPath.startsWith("http") && !bgPath.startsWith("data:")) {
      bgPath = "assets/$bgPath";
    }
    // (Optional) If your asset keys in pubspec don't include 'assets/', adjust accordingly.
    // But usually in Flutter, the key IS 'assets/foo.png'.

    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar || appBar != null,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Fallback color
      appBar: appBar ?? (showSettings
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: IconButton(
                    icon: const Icon(Icons.settings, size: 30),
                    onPressed: onSettingsTap, 
                  ),
                )
              ],
            )
          : null),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              bgPath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                // Fail silently to background color
                return Container(color: Theme.of(context).scaffoldBackgroundColor);
              },
            ),
          ),
          // Dark Overlay for readability
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.7)),
          ),
          // Content
          SafeArea(
            top: !extendBodyBehindAppBar && appBar == null,
            child: body,
          ),
        ],
      ),  
    );
  }
}