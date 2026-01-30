import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class ClientSettingsDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget sectionTitle(String t) => Text(
          t,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        );

    BoxDecoration boxDeco() => BoxDecoration(
          color: theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
        );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: theme.colorScheme.surface,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 450),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("SETTINGS", style: theme.textTheme.titleLarge?.copyWith(fontSize: 24)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),

              // APPEARANCE
              sectionTitle("APPEARANCE"),
              SwitchListTile(
                title: const Text("Dark Mode"),
                secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                value: isDark,
                onChanged: (val) => game.updateTheme(brightness: val ? Brightness.dark : Brightness.light),
              ),

              const SizedBox(height: 10),
              sectionTitle("WALLPAPER"),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: boxDeco(),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: game.wallpaperOptions.containsValue(game.wallpaper)
                        ? game.wallpaper
                        : game.wallpaperOptions.values.first,
                    isExpanded: true,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
                    dropdownColor: theme.colorScheme.surface,
                    items: game.wallpaperOptions.entries
                        .map((e) => DropdownMenuItem(value: e.value, child: Text(e.key)))
                        .toList(),
                    onChanged: (v) => game.updateTheme(bg: v),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // AUDIO
              sectionTitle("AUDIO"),
              SwitchListTile(
                title: const Text("Background Music"),
                value: game.isMusicEnabled,
                onChanged: (val) => game.toggleMusic(val),
              ),

              if (game.isMusicEnabled) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: boxDeco(),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: game.musicOptions.containsValue(game.currentMusic)
                          ? game.currentMusic
                          : game.musicOptions.values.first,
                      isExpanded: true,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
                      dropdownColor: theme.colorScheme.surface,
                      items: game.musicOptions.entries
                          .map((e) => DropdownMenuItem(value: e.value, child: Text(e.key)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) game.setMusicTrack(v);
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
