import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class CreateGameScreen extends StatefulWidget {
  @override
  _CreateGameScreenState createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  final _countController = TextEditingController(text: "10");
  final _timerController = TextEditingController(text: "30");
  final _customCodeController = TextEditingController();

  String _selectedMode = "general-knowledge";
  String _difficulty = "mixed";
  String _selectedCategory = ""; 
  int _questionCount = 10;
  bool _isLoading = false; 

  final Map<String, String> _modes = { "General Knowledge": "general-knowledge", "Math Calculations": "calculations" };
  final Map<String, String> _categories = { "Any Category": "", "Books": "10", "Film": "11", "Music": "12", "Video Games": "15", "Science": "17", "Computers": "18" };

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);

    return Scaffold(
      body: CyberpunkBackground( 
        child: Center(
          child: SingleChildScrollView(
            child: GlassContainer( 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("Create Lobby", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                  const SizedBox(height: 24),

                  _buildLabel("Game Mode"),
                  _buildDropdown(_modes, _selectedMode, (val) => setState(() => _selectedMode = val!)),

                  if (_selectedMode == "general-knowledge") ...[
                    const SizedBox(height: 16),
                    _buildLabel("Topic"),
                    _buildDropdown(_categories, _selectedCategory, (val) => setState(() => _selectedCategory = val!)),
                  ],

                  const SizedBox(height: 16),
                  _buildLabel("Questions: $_questionCount"),
                  Slider(
                    value: _questionCount.toDouble(), min: 5, max: 20, divisions: 3,
                    activeColor: AppTheme.accentPink,
                    onChanged: (v) => setState(() => _questionCount = v.toInt()),
                  ),

                  _buildLabel("Difficulty"),
                  _buildDropdown({"Mixed": "mixed", "Easy": "easy", "Medium": "medium", "Hard": "hard"}, _difficulty, (val) => setState(() => _difficulty = val!)),

                  const SizedBox(height: 16),
                  TextField(controller: _customCodeController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Custom Code (Opt)", labelStyle: TextStyle(color: Colors.white54))),

                  const SizedBox(height: 32),

                  _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.accentPink))
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPink, padding: const EdgeInsets.symmetric(vertical: 16)),
                        onPressed: () async {
                          setState(() => _isLoading = true);
                          try {
                            await game.createLobby(
                              game.myName,
                              _selectedMode,
                              _questionCount,
                              _selectedCategory,
                              30, 
                              _difficulty,
                              _customCodeController.text.trim()
                            );
                            if (mounted) Navigator.pop(context); // FIX: GO BACK TO LOBBY
                          } catch (e) {
                            if (mounted) {
                              setState(() => _isLoading = false);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                            }
                          }
                        },
                        child: const Text("START GAME", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                  
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Back", style: TextStyle(color: Colors.white54))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(text, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)));
  Widget _buildDropdown(Map<String, String> items, String value, Function(String?) onChange) => Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: value, dropdownColor: const Color(0xFF1A1A2E), isExpanded: true, style: const TextStyle(color: Colors.white), items: items.entries.map((e) => DropdownMenuItem(value: e.value, child: Text(e.key))).toList(), onChanged: onChange)));
}