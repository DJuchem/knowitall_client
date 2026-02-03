import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/game_provider.dart';

class ClientSettingsDialog extends StatefulWidget {
  const ClientSettingsDialog({super.key});

  @override
  State<ClientSettingsDialog> createState() => _ClientSettingsDialogState();
}

class _ClientSettingsDialogState extends State<ClientSettingsDialog> {
  // Use local state for dropdowns if you want them to be selectable 
  // without immediately updating the provider (optional), 
  // but here we interact directly with the game provider for global settings.

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget sectionTitle(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        t,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 14,
        ),
      ),
    );

    BoxDecoration boxDeco() => BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: theme.colorScheme.surface,
      elevation: 10,
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
                  Text("APP SETTINGS", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              
              // APPEARANCE
              sectionTitle("APPEARANCE"),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Dark Mode"),
                secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: theme.colorScheme.secondary),
                value: isDark,
                onChanged: (val) => game.updateTheme(brightness: val ? Brightness.dark : Brightness.light),
              ),

              const SizedBox(height: 8),
              const Text("Wallpaper", style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: boxDeco(),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: game.wallpaperOptions.containsValue(game.wallpaper)
                        ? game.wallpaper
                        : game.wallpaperOptions.values.first,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
                    dropdownColor: theme.cardColor,
                    items: game.wallpaperOptions.entries
                        .map((e) => DropdownMenuItem(value: e.value, child: Text(e.key)))
                        .toList(),
                    onChanged: (v) => game.updateTheme(bg: v),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // AUDIO
              sectionTitle("AUDIO"),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Background Music"),
                secondary: Icon(game.isMusicEnabled ? Icons.music_note : Icons.music_off, color: theme.colorScheme.secondary),
                value: game.isMusicEnabled,
                onChanged: (val) => game.toggleMusic(val),
              ),

              if (game.isMusicEnabled) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: boxDeco(),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: game.musicOptions.containsValue(game.currentMusic)
                          ? game.currentMusic
                          : game.musicOptions.values.first,
                      isExpanded: true,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
                      dropdownColor: theme.cardColor,
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