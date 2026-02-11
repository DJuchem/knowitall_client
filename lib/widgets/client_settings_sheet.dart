import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class ClientSettingsSheet extends StatelessWidget {
  /// When opened standalone (not via the App Menu sub-pages), you may want a close (X) button.
  /// Inside the App Menu we rely on the AppBar back arrow.
  final bool showClose;

  const ClientSettingsSheet({super.key, this.showClose = false});

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75, // ✅ Fixed Height
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
              if (showClose)
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Align Left
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

                  // ✅ FIX: Restored Audio Settings
                  const SizedBox(height: 24),
                  _buildSectionLabel("AUDIO", theme),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Background Music"),
                    subtitle: const Text("Play music in lobby"),
                    value: game.isMusicEnabled,
                    onChanged: (v) => game.toggleMusic(v),
                  ),
                  if (game.isMusicEnabled) 
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: _buildDropdown(
                        value: game.currentMusic,
                        items: game.musicOptions,
                        onChanged: (v) => game.setMusicTrack(v!),
                        theme: theme,
                      ),
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
    final safeValue = items.containsValue(value) ? value : items.values.first;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          items: items.entries.map((e) => DropdownMenuItem(value: e.value, child: Text(e.key))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}