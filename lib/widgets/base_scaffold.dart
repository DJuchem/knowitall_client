import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'app_quick_menu.dart';

class BaseScaffold extends StatelessWidget {
  final Widget body;
  final bool showSettings;
  final bool extendBodyBehindAppBar;
  final PreferredSizeWidget? appBar;
  final VoidCallback? onSettingsTap;

  // ✅ NEW: unified quick menu button on all screens by default
  final bool showQuickMenu;

  const BaseScaffold({
    super.key,
    required this.body,
    this.showSettings = false,
    this.extendBodyBehindAppBar = false,
    this.appBar,
    this.onSettingsTap,
    this.showQuickMenu = true,
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

    String bgPath = _ensureAssetKey(game.wallpaper);
    if (!bgPath.startsWith("assets/") &&
        !bgPath.startsWith("http") &&
        !bgPath.startsWith("data:")) {
      bgPath = "assets/$bgPath";
    }

    final effectiveAppBar =
        appBar ??
        (showSettings
            ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  if (showQuickMenu)
                    const AppQuickMenuButton(iconColor: Colors.white),
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: IconButton(
                      icon: const Icon(Icons.settings, size: 28),
                      onPressed: onSettingsTap,
                    ),
                  ),
                ],
              )
            : (showQuickMenu
                  ? AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      iconTheme: const IconThemeData(color: Colors.white),
                      actions: const [
                        AppQuickMenuButton(iconColor: Colors.white),
                      ],
                    )
                  : null));

    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar || effectiveAppBar != null,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: effectiveAppBar,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              bgPath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: Theme.of(context).scaffoldBackgroundColor),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.70)),
          ),
          SafeArea(
            top: !extendBodyBehindAppBar && effectiveAppBar == null,
            child: body,
          ),
        ],
      ),
    );
  }
}
