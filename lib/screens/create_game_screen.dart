import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class CreateGameScreen extends StatefulWidget {
  @override
  _CreateGameScreenState createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  // --- STATE ---
  String _selectedMode = "general-knowledge";
  String _difficulty = "mixed";
  String _selectedCategory = ""; // Empty string = "Any Category"
  int _questionCount = 10;
  bool _isLoading = false;

  // --- 1. RESTORED GAME MODES (Flags, etc.) ---
  final Map<String, String> _modes = {
    "General Knowledge": "general-knowledge",
    "Math Calculations": "calculations",
    "Flags of the World": "flags", 
    "Capital Cities": "capitals",
  };

  // --- 2. OPENTDB CATEGORIES (Only for General Knowledge) ---
  final Map<String, String> _categories = {
    "Any Category": "",
    "General Knowledge": "9",
    "Books": "10",
    "Film": "11",
    "Music": "12",
    "Musicals & Theatres": "13",
    "Television": "14",
    "Video Games": "15",
    "Board Games": "16",
    "Science & Nature": "17",
    "Computers": "18",
    "Mathematics": "19",
    "Mythology": "20",
    "Sports": "21",
    "Geography": "22",
    "History": "23",
    "Politics": "24",
    "Art": "25",
    "Celebrities": "26",
    "Animals": "27",
    "Vehicles": "28",
    "Comics": "29",
    "Gadgets": "30",
    "Anime & Manga": "31",
    "Cartoon & Animations": "32",
  };

  @override
  Widget build(BuildContext context) {
    // Access provider (don't listen here to avoid rebuild loops on state change)
    final game = Provider.of<GameProvider>(context, listen: false);

    return Scaffold(
      body: CyberpunkBackground(
        child: Center(
          child: SingleChildScrollView(
            child: GlassContainer(
              margin: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text("Create Lobby", 
                    style: TextStyle(
                      fontSize: 28, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white,
                      shadows: [Shadow(color: AppTheme.accentPink, blurRadius: 10)]
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // --- GAME MODE SELECTOR ---
                  _buildLabel("Game Mode"),
                  _buildDropdown(_modes, _selectedMode, (val) {
                    setState(() {
                      _selectedMode = val!;
                      // Reset category if switching away from Gen Knowledge
                      if (_selectedMode != 'general-knowledge') {
                        _selectedCategory = ""; 
                      }
                    });
                  }),

                  // --- CONDITIONAL CATEGORY SELECTOR ---
                  // Only shows if "General Knowledge" is selected
                  if (_selectedMode == "general-knowledge") ...[
                    const SizedBox(height: 16),
                    _buildLabel("Topic"),
                    _buildDropdown(_categories, _selectedCategory, (val) {
                      setState(() => _selectedCategory = val!);
                    }),
                  ],

                  // --- QUESTION COUNT SLIDER ---
                  const SizedBox(height: 16),
                  _buildLabel("Questions: $_questionCount"),
                  Slider(
                    value: _questionCount.toDouble(),
                    min: 5, max: 20, divisions: 3,
                    activeColor: AppTheme.accentPink,
                    onChanged: (v) => setState(() => _questionCount = v.toInt()),
                  ),

                  // --- DIFFICULTY SELECTOR ---
                  _buildLabel("Difficulty"),
                  _buildDropdown({
                    "Mixed": "mixed", "Easy": "easy", "Medium": "medium", "Hard": "hard"
                  }, _difficulty, (val) => setState(() => _difficulty = val!)),

                  const SizedBox(height: 32),

                  // --- START BUTTON ---
                  _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.accentPink))
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentPink,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 8,
                          shadowColor: AppTheme.accentPink.withOpacity(0.5),
                        ),
                        onPressed: _handleStart,
                        child: const Text("START GAME", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                  
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Back", style: TextStyle(color: Colors.white54)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleStart() async {
   setState(() => _isLoading = true); 
    final game = Provider.of<GameProvider>(context, listen: false);

    try {
      await game.createLobby(
        game.myName,
        _selectedMode,
        _questionCount,
        _selectedCategory,
        _difficulty
      ).timeout(const Duration(seconds: 5));

      // --- ADD THIS LINE ---
      // This closes the "Create" window so you see the Lobby underneath
      if (mounted) Navigator.of(context).pop(); 
      
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDropdown(Map<String, String> items, String value, Function(String?) onChange) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF1A1A2E), // Dark background for menu
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: AppTheme.accentPink),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          // Ensure unique values mapping
          items: items.entries.map((e) => DropdownMenuItem(
            value: e.value,
            child: Text(e.key),
          )).toList(),
          onChanged: onChange,
        ),
      ),
    );
  }
}