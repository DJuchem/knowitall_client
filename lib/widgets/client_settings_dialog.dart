import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class ClientSettingsDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: theme.colorScheme.surface, // Follows light/dark
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 450),
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
            Text("APPEARANCE", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            SwitchListTile(
              title: const Text("Dark Mode"),
              secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
              value: isDark,
              onChanged: (val) => game.updateTheme(brightness: val ? Brightness.dark : Brightness.light),
            ),
            
            const SizedBox(height: 10),
            Text("WALLPAPER", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: theme.inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: game.wallpaperOptions.containsValue(game.wallpaper) ? game.wallpaper : game.wallpaperOptions.values.first,
                  isExpanded: true,
                  style: theme.textTheme.bodyMedium, // Use legible text style
                  dropdownColor: theme.colorScheme.surface,
                  items: game.wallpaperOptions.entries.map((e) => DropdownMenuItem(value: e.value, child: Text(e.key))).toList(),
                  onChanged: (v) => game.updateTheme(bg: v),
                ),
              ),
            ),

            const SizedBox(height: 20),
            
            // AUDIO
            Text("AUDIO", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            SwitchListTile(
              title: const Text("Background Music"),
              value: game.isMusicEnabled,
              onChanged: (val) => game.toggleMusic(val),
            ),
            
            if (game.isMusicEnabled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: theme.inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: game.musicOptions.containsValue(game.currentMusic) ? game.currentMusic : game.musicOptions.values.first,
                    isExpanded: true,
                    style: theme.textTheme.bodyMedium,
                    dropdownColor: theme.colorScheme.surface,
                    items: game.musicOptions.entries.map((e) => DropdownMenuItem(value: e.value, child: Text(e.key))).toList(),
                    onChanged: (v) => game.setMusicTrack(v!),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}