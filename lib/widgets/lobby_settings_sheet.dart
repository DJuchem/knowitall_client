import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class LobbySettingsSheet extends StatefulWidget {
  const LobbySettingsSheet({super.key});

  @override
  State<LobbySettingsSheet> createState() => _LobbySettingsSheetState();
}

class _LobbySettingsSheetState extends State<LobbySettingsSheet> {
  // Local state to hold changes before saving
  late String _mode;
  late double _questions; // Double for Slider
  late double _timer;     // Double for Slider
  late String _difficulty;

  @override
  void initState() {
    super.initState();
    final lobby = Provider.of<GameProvider>(context, listen: false).lobby;
    if (lobby != null) {
      _mode = lobby.mode;
      // ✅ FIX: Use quizData length or default to 10
      _questions = (lobby.quizData?.length ?? 10).toDouble();
      _timer = lobby.timer.toDouble();
      _difficulty = lobby.difficulty ?? "mixed";
    } else {
      // Fallbacks if lobby is null
      _mode = "general-knowledge";
      _questions = 10;
      _timer = 20;
      _difficulty = "mixed";
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
              Text("GAME SETTINGS", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildLabel("GAME MODE", theme),
                  _buildDropdown(
                    items: game.gameModes, 
                    value: _mode,
                    theme: theme,
                    onChange: (val) => setState(() => _mode = val ?? "general-knowledge"),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // QUESTIONS SLIDER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLabel("QUESTIONS", theme),
                      Text("${_questions.toInt()}", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  Slider(
                    value: _questions,
                    min: 5, max: 50, divisions: 9,
                    onChanged: (v) => setState(() => _questions = v),
                  ),

                  const SizedBox(height: 16),
                  
                  // TIMER SLIDER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLabel("TIMER (SEC)", theme),
                      Text("${_timer.toInt()}", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  Slider(
                    value: _timer,
                    min: 10, max: 60, divisions: 10,
                    onChanged: (v) => setState(() => _timer = v),
                  ),

                  const SizedBox(height: 16),
                  _buildLabel("DIFFICULTY", theme),
                  _buildDropdown(
                    items: const {"Mixed": "mixed", "Easy": "easy", "Medium": "medium", "Hard": "hard"},
                    value: _difficulty,
                    theme: theme,
                    onChange: (val) => setState(() => _difficulty = val ?? "mixed"),
                  ),
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        // ✅ FIX: Use correct GameProvider method signature
                        game.updateSettings(
                          _mode, 
                          _questions.toInt(), 
                          "", // Category (empty for mixed)
                          _timer.toInt(), 
                          _difficulty
                        );
                        Navigator.pop(context);
                      },
                      child: const Text("UPDATE SETTINGS", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, ThemeData theme) => Padding(
    padding: const EdgeInsets.only(bottom: 6.0),
    child: Text(text, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontWeight: FontWeight.bold, fontSize: 12)),
  );

  Widget _buildDropdown({required Map<String, String> items, required String value, required ThemeData theme, required ValueChanged<String?> onChange}) {
      final selected = items.containsValue(value) ? value : items.values.first;
      return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          dropdownColor: theme.cardColor,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary),
          style: theme.textTheme.bodyMedium,
          items: items.entries.map((e) => DropdownMenuItem(value: e.value, child: Text(e.key))).toList(),
          onChanged: onChange,
        ),
      ),
    );
  }
}