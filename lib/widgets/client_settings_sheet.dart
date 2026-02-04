import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class ClientSettingsSheet extends StatelessWidget {
  const ClientSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Helper for section titles
    Widget sectionTitle(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: Text(
        t,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 12,
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 50)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("SETTINGS", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // VISUALS
                  sectionTitle("VISUAL STYLE"),
                  
                  // Horizontal Theme Selector
                  SizedBox(
                    height: 90,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: AppTheme.schemes.values.map((scheme) {
                        final isSelected = game.currentScheme == scheme.name;
                        return GestureDetector(
                          onTap: () => game.updateTheme(scheme: scheme.name),
                          child: Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: scheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? scheme.primary : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: scheme.primary.withOpacity(0.4), blurRadius: 8)]
                                  : [],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(backgroundColor: scheme.primary, radius: 14),
                                const SizedBox(height: 8),
                                Text(
                                  scheme.name,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.black87,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Dark Mode", style: TextStyle(fontWeight: FontWeight.bold)),
                    secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                    value: isDark,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (val) => game.updateTheme(brightness: val ? Brightness.dark : Brightness.light),
                  ),

                  // WALLPAPER
                  sectionTitle("WALLPAPER"),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: game.wallpaperOptions.containsValue(game.wallpaper)
                            ? game.wallpaper
                            : game.wallpaperOptions.values.first,
                        isExpanded: true,
                        dropdownColor: theme.cardColor,
                        icon: const Icon(Icons.image),
                        items: game.wallpaperOptions.entries
                            .map((e) => DropdownMenuItem(value: e.value, child: Text(e.key)))
                            .toList(),
                        onChanged: (v) => game.updateTheme(bg: v),
                      ),
                    ),
                  ),

                  // AUDIO
                  sectionTitle("AUDIO"),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Background Music", style: TextStyle(fontWeight: FontWeight.bold)),
                    secondary: Icon(game.isMusicEnabled ? Icons.music_note : Icons.music_off, color: theme.colorScheme.secondary),
                    value: game.isMusicEnabled,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (val) => game.toggleMusic(val),
                  ),

                  if (game.isMusicEnabled) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black26 : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: game.musicOptions.containsValue(game.currentMusic)
                              ? game.currentMusic
                              : game.musicOptions.values.first,
                          isExpanded: true,
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
        ],
      ),
    );
  }
}