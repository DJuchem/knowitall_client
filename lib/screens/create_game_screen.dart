import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/base_scaffold.dart';
import '../theme/app_theme.dart';
import 'lobby_screen.dart';

class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({Key? key}) : super(key: key);

  @override
  _CreateGameScreenState createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  final _customCodeController = TextEditingController();
  
  String _selectedMode = "general-knowledge";
  String _difficulty = "mixed";
  String _selectedCategory = ""; 
  int _questionCount = 10;
  bool _isLoading = false; 
  bool _isFetchingCats = true;

  final Map<String, String> _modes = { 
    "General Knowledge": "general-knowledge", 
    "Math Calculations": "calculations", 
    "Guess the Flag": "flags", 
    "Music Quiz": "music" 
  };
  
  Map<String, String> _categories = { "Any Category": "" };

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final res = await http.get(Uri.parse("https://opentdb.com/api_category.php"));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final cats = data['trivia_categories'] as List;
        final Map<String, String> newCats = { "Any Category": "" };
        for (var c in cats) newCats[c['name'].toString()] = c['id'].toString();
        if (mounted) setState(() { _categories = newCats; _isFetchingCats = false; });
      }
    } catch (e) { if (mounted) setState(() => _isFetchingCats = false); }
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return BaseScaffold(
      appBar: AppBar(title: Text("CONFIGURE GAME", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)), iconTheme: IconThemeData(color: textColor), backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: SingleChildScrollView(
          child: GlassContainer( 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLabel("GAME MODE", textColor),
                _buildDropdown(_modes, _selectedMode, textColor, (val) => setState(() => _selectedMode = val!)),

                if (_selectedMode == "general-knowledge") ...[
                  const SizedBox(height: 20),
                  _buildLabel("TOPIC", textColor),
                  if (_isFetchingCats) const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                  else _buildDropdown(_categories, _selectedCategory, textColor, (val) => setState(() => _selectedCategory = val!)),
                ],

                const SizedBox(height: 20),
                _buildLabel("QUESTIONS: $_questionCount", textColor),
                Slider(value: _questionCount.toDouble(), min: 5, max: 50, divisions: 45, activeColor: theme.colorScheme.primary, onChanged: (v) => setState(() => _questionCount = v.toInt())),

                _buildLabel("DIFFICULTY", textColor),
                _buildDropdown({"Mixed": "mixed", "Easy": "easy", "Medium": "medium", "Hard": "hard"}, _difficulty, textColor, (val) => setState(() => _difficulty = val!)),

                const SizedBox(height: 20),
                TextField(
                  controller: _customCodeController, 
                  style: TextStyle(color: textColor, fontSize: 18), 
                  decoration: InputDecoration(labelText: "CUSTOM CODE (OPTIONAL)", labelStyle: TextStyle(color: textColor.withOpacity(0.6)), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: textColor.withOpacity(0.3))))
                ),

                const SizedBox(height: 40),

                _isLoading 
                  ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, padding: const EdgeInsets.symmetric(vertical: 18)),
                      onPressed: () async {
                        setState(() => _isLoading = true);
                        try {
                          // FIX: Use the name already stored in provider (from Welcome Screen)
                          String hostName = game.myName.isEmpty ? "Host" : game.myName;
                          
                          await game.createLobby(
                            hostName, _selectedMode, _questionCount, 
                            _selectedCategory, 30, _difficulty, 
                            _customCodeController.text.trim()
                          );

                          if (!mounted) return;
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LobbyScreen()));
                          
                        } catch (e) {
                          if (mounted) {
                            setState(() => _isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                          }
                        }
                      },
                      child: const Text("LAUNCH LOBBY", style: TextStyle(color: Colors.white, fontSize: 20)),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) => Padding(padding: const EdgeInsets.only(bottom: 10.0), child: Text(text, style: TextStyle(color: color.withOpacity(0.8), fontWeight: FontWeight.bold, fontSize: 16)));
  Widget _buildDropdown(Map<String, String> items, String value, Color color, Function(String?) onChange) => Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Theme.of(context).cardColor.withOpacity(0.5), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.2))), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: items.containsValue(value) ? value : items.values.first, dropdownColor: Theme.of(context).cardColor, isExpanded: true, style: TextStyle(color: color, fontSize: 18), items: items.entries.map((e) => DropdownMenuItem(value: e.value, child: Text(e.key))).toList(), onChanged: onChange)));
}