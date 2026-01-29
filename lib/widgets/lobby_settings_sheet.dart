import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class LobbySettingsSheet extends StatefulWidget {
  @override
  _LobbySettingsSheetState createState() => _LobbySettingsSheetState();
}

class _LobbySettingsSheetState extends State<LobbySettingsSheet> {
  // State mirroring CreateGameScreen
  late String _selectedMode;
  late String _difficulty;
  late String _selectedCategory;
  late int _questionCount;
  late int _timer;

  final Map<String, String> _modes = { 
    "General Knowledge": "general-knowledge", 
    "Math Calculations": "calculations",
    "Guess the Flag": "flags",
    "Music Quiz": "music", // New Mode
  };
  
  final Map<String, String> _categories = { "Any": "", "Books": "10", "Film": "11", "Music": "12", "Video Games": "15" };

  @override
  void initState() {
    super.initState();
    final lobby = Provider.of<GameProvider>(context, listen: false).lobby!;
    _selectedMode = lobby.mode;
    _difficulty = lobby.difficulty ?? "mixed";
    _selectedCategory = ""; // LobbyData might need to store this if you want persistence
    _questionCount = 10; // Default or fetch from lobby if you add it to LobbyData
    _timer = lobby.timer;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Lobby Settings", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            _buildDropdown("Game Mode", _modes, _selectedMode, (v) => setState(() => _selectedMode = v!)),
            
            if (_selectedMode == "general-knowledge")
              _buildDropdown("Category", _categories, _selectedCategory, (v) => setState(() => _selectedCategory = v!)),

            const SizedBox(height: 15),
            Text("Questions: $_questionCount", style: const TextStyle(color: Colors.white70)),
            Slider(
              value: _questionCount.toDouble(), min: 5, max: 100, divisions: 19, // UP TO 100
              activeColor: AppTheme.accentPink,
              onChanged: (v) => setState(() => _questionCount = v.toInt()),
            ),

            Text("Timer: ${_timer}s", style: const TextStyle(color: Colors.white70)),
            Slider(
              value: _timer.toDouble(), min: 10, max: 120, divisions: 11,
              activeColor: Colors.blueAccent,
              onChanged: (v) => setState(() => _timer = v.toInt()),
            ),

            _buildDropdown("Difficulty", {"Mixed": "mixed", "Easy": "easy", "Medium": "medium", "Hard": "hard"}, _difficulty, (v) => setState(() => _difficulty = v!)),

            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: () {
                Provider.of<GameProvider>(context, listen: false).updateSettings(
                  _selectedMode, _questionCount, _selectedCategory, _timer, _difficulty
                );
                Navigator.pop(context);
              },
              child: const Text("UPDATE SETTINGS", style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, Map<String, String> items, String value, Function(String?) onChange) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: items.containsValue(value) ? value : items.values.first, // Safety
        decoration: InputDecoration(labelText: label, filled: true, fillColor: Colors.black26),
        dropdownColor: const Color(0xFF2A2A40),
        style: const TextStyle(color: Colors.white),
        items: items.entries.map((e) => DropdownMenuItem(value: e.value, child: Text(e.key))).toList(),
        onChanged: onChange,
      ),
    );
  }
}