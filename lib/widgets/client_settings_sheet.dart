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

    return Container(
      // Standardize height and padding to match LobbySettingsSheet
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("APP SETTINGS", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(),

          // Use Flexible + SingleChildScrollView to ensure it fits mobile screens
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildSectionLabel("VISUAL SCHEME", theme),
                  _buildThemeSelector(game),
                  
                  const SizedBox(height: 24),
                  _buildSectionLabel("BACKGROUND", theme),
                  _buildDropdown(
                    value: game.wallpaper,
                    items: game.wallpaperOptions,
                    onChanged: (v) => game.updateTheme(bg: v),
                    theme: theme,
                  ),

                  const SizedBox(height: 24),
                  _buildSectionLabel("AUDIO", theme),
                  SwitchListTile(
                    title: const Text("Background Music"),
                    value: game.isMusicEnabled,
                    onChanged: (v) => game.toggleMusic(v),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, ThemeData theme) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
  );

  // Helper for the visual theme cards
  Widget _buildThemeSelector(GameProvider game) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: AppTheme.schemes.values.map((s) => GestureDetector(
          onTap: () => game.updateTheme(scheme: s.name),
          child: Container(
            width: 80,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: s.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: game.currentScheme == s.name ? s.primary : Colors.white10, width: 2),
            ),
            child: Icon(Icons.color_lens, color: s.primary),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildDropdown({required String value, required Map<String, String> items, required Function(String?) onChanged, required ThemeData theme}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: items.containsValue(value) ? value : items.values.first,
        isExpanded: true,
        underline: const SizedBox(),
        items: items.entries.map((e) => DropdownMenuItem(value: e.value, child: Text(e.key))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}