import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class LobbySettingsSheet extends StatefulWidget {
  const LobbySettingsSheet({super.key});

  @override
  State<LobbySettingsSheet> createState() => _LobbySettingsSheetState();
}

class _LobbySettingsSheetState extends State<LobbySettingsSheet> {
  String _selectedMode = "general-knowledge";
  String _difficulty = "mixed";
  String _selectedCategory = "";
  int _questionCount = 10;
  int _timer = 30;

  bool _catsLoading = false;
  String? _catsError;
  Map<String, String> _categories = const {"Any Category": ""};

  final Map<String, String> _modes = const {
    "General Knowledge": "general-knowledge",
    "Math Calculations": "calculations",
    "Guess the Flag": "flags",
    "Music Quiz": "music",
    "Odd One Out": "odd_one_out",
    "True / False": "true_false",
    "Population": "population",
  };

  @override
  void initState() {
    super.initState();
    final game = Provider.of<GameProvider>(context, listen: false);
    final lobby = game.lobby;
    
    if (lobby != null) {
      _selectedMode = lobby.mode;
      _difficulty = lobby.difficulty ?? "mixed";
      _timer = lobby.timer;
      
      // ✅ FIX 1 & 2: These are commented out until you update 'lobby_data.dart' (see Step 3 below)
      // _selectedCategory = lobby.category ?? ""; 
      // _questionCount = lobby.questionCount;     
    }
    
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    if (!mounted) return;
    setState(() { _catsLoading = true; _catsError = null; });

    try {
      final resp = await http.get(Uri.parse("https://opentdb.com/api_category.php"));
      if (resp.statusCode != 200) throw Exception("HTTP ${resp.statusCode}");

      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      final list = (decoded["trivia_categories"] as List?) ?? [];

      final Map<String, String> map = {"Any Category": ""};
      for (final item in list) {
        if (item is Map) map[item["name"].toString()] = item["id"].toString();
      }

      if (!mounted) return;
      setState(() {
        _categories = map;
        if (!_categories.containsValue(_selectedCategory)) {
          _selectedCategory = "";
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _catsError = "Failed to load topics";
        _categories = const {"Any Category": ""};
      });
    } finally {
      if (mounted) setState(() => _catsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        // ✅ FIX 3: Removed invalid 'borderRadius' parameter. 
        // If you need rounding, wrap this GlassContainer in a ClipRRect.
        return GlassContainer(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40, height: 4, 
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.white54, borderRadius: BorderRadius.circular(2))
                )
              ),
              const Text("GAME SETTINGS", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 24),

              _buildLabel("GAME MODE"),
              _buildDropdown(
                items: _modes, 
                value: _selectedMode, 
                onChange: (v) => setState(() => _selectedMode = v ?? "general-knowledge")
              ),
              
              if (_selectedMode == "general-knowledge") ...[
                const SizedBox(height: 16),
                _buildLabel("TOPIC"),
                if (_catsLoading) const LinearProgressIndicator(minHeight: 2),
                if (_catsError != null) Text(_catsError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                _buildDropdown(
                  items: _categories, 
                  value: _selectedCategory, 
                  onChange: (v) => setState(() => _selectedCategory = v ?? "")
                ),
              ],

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel("QUESTIONS"),
                  Text("$_questionCount", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              Slider(
                value: _questionCount.toDouble(), min: 5, max: 50, divisions: 9, activeColor: Colors.amber,
                onChanged: (v) => setState(() => _questionCount = v.toInt()),
              ),

              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel("TIMER (SEC)"),
                  Text("$_timer", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              Slider(
                value: _timer.toDouble(), min: 10, max: 60, divisions: 5, activeColor: Colors.amber,
                onChanged: (v) => setState(() => _timer = v.toInt()),
              ),

              const SizedBox(height: 8),
              _buildLabel("DIFFICULTY"),
              _buildDropdown(
                items: const {"Mixed": "mixed", "Easy": "easy", "Medium": "medium", "Hard": "hard"}, 
                value: _difficulty, 
                onChange: (v) => setState(() => _difficulty = v ?? "mixed")
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, 
                  padding: const EdgeInsets.symmetric(vertical: 16), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                onPressed: () async {
                  await game.updateSettings(_selectedMode, _questionCount, _selectedCategory, _timer, _difficulty);
                  if (mounted) Navigator.pop(context);
                },
                child: const Text("UPDATE SETTINGS", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1)),
  );

  Widget _buildDropdown({required Map<String, String> items, required String value, required ValueChanged<String?> onChange}) {
    final selected = items.containsValue(value) ? value : items.values.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected, 
          dropdownColor: Colors.grey[900], 
          isExpanded: true, 
          style: const TextStyle(color: Colors.white, fontSize: 16),
          items: items.entries.map((e) => DropdownMenuItem(value: e.value, child: Text(e.key))).toList(),
          onChanged: onChange,
        ),
      ),
    );
  }
}