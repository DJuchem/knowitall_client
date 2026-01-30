import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/game_provider.dart';
import '../widgets/base_scaffold.dart';
import '../theme/app_theme.dart';


class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({super.key});

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  final _customCodeController = TextEditingController();

  // Defaults
  String _selectedMode = "general-knowledge";
  String _difficulty = "mixed";
  String _selectedCategory = "";
  int _questionCount = 10;
  bool _isLoading = false;

  // Categories
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
    _fetchCategories();
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      if (prefs.containsKey('cfg_mode')) _selectedMode = prefs.getString('cfg_mode')!;
      if (prefs.containsKey('cfg_diff')) _difficulty = prefs.getString('cfg_diff')!;
      if (prefs.containsKey('cfg_cat')) _selectedCategory = prefs.getString('cfg_cat')!;
      if (prefs.containsKey('cfg_count')) _questionCount = prefs.getInt('cfg_count')!;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cfg_mode', _selectedMode);
    await prefs.setString('cfg_diff', _difficulty);
    await prefs.setString('cfg_cat', _selectedCategory);
    await prefs.setInt('cfg_count', _questionCount);
  }

  @override
  void dispose() {
    _customCodeController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _catsLoading = true;
      _catsError = null;
    });

    try {
      final resp = await http.get(Uri.parse("https://opentdb.com/api_category.php"));
      if (resp.statusCode != 200) throw Exception("HTTP ${resp.statusCode}");

      final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
      final list = (decoded["trivia_categories"] as List?) ?? [];

      final Map<String, String> map = {"Any Category": ""};
      for (final item in list) {
        if (item is Map) {
          map[item["name"].toString()] = item["id"].toString();
        }
      }

      setState(() {
        _categories = map;
        if (!_categories.containsValue(_selectedCategory)) {
          _selectedCategory = "";
        }
      });
    } catch (e) {
      setState(() {
        _catsError = "Category fetch failed";
        _categories = const {"Any Category": ""};
      });
    } finally {
      if (mounted) setState(() => _catsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return BaseScaffold(
      extendBodyBehindAppBar: true, 
      showSettings: true,
      appBar: AppBar(
        title: Text(
          "CONFIGURE GAME",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: textColor),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => game.setAppState(AppState.welcome),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLabel("GAME MODE", textColor),
                    _buildDropdown(
                      items: _modes,
                      value: _selectedMode,
                      textColor: textColor,
                      onChange: (val) => setState(() => _selectedMode = val ?? "general-knowledge"),
                    ),

                    if (_selectedMode == "general-knowledge") ...[
                      const SizedBox(height: 16),
                      _buildLabel("TOPIC", textColor),

                      if (_catsLoading)
                        const LinearProgressIndicator(minHeight: 2),

                      if (_catsError != null)
                         Text(_catsError!, style: const TextStyle(color: Colors.red, fontSize: 12)),

                      _buildDropdown(
                        items: _categories,
                        value: _selectedCategory,
                        textColor: textColor,
                        onChange: (val) => setState(() => _selectedCategory = val ?? ""),
                      ),
                    ],

                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabel("QUESTIONS", textColor),
                        Text("$_questionCount", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    Slider(
                      value: _questionCount.toDouble(),
                      min: 5,
                      max: 50,
                      divisions: 9,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (v) => setState(() => _questionCount = v.toInt()),
                    ),

                    _buildLabel("DIFFICULTY", textColor),
                    _buildDropdown(
                      items: const {"Mixed": "mixed", "Easy": "easy", "Medium": "medium", "Hard": "hard"},
                      value: _difficulty,
                      textColor: textColor,
                      onChange: (val) => setState(() => _difficulty = val ?? "mixed"),
                    ),

                    const SizedBox(height: 16),
                    TextField(
                      controller: _customCodeController,
                      style: TextStyle(color: textColor, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: "CUSTOM CODE (OPTIONAL)",
                        labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: textColor.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    if (_isLoading)
                      Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          setState(() => _isLoading = true);
                          await _saveSettings();
                          try {
                            // Ensure 'game.myAvatar' exists in your GameProvider!
                            await game.createLobby(
                              game.myName,
                              game.myAvatar, 
                              _selectedMode,
                              _questionCount,
                              _selectedCategory,
                              30,
                              _difficulty,
                              _customCodeController.text.trim().toUpperCase(),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                            );
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        },
                        child: const Text("LAUNCH LOBBY", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 6.0),
        child: Text(
          text,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1.1,
          ),
        ),
      );

  Widget _buildDropdown({
    required Map<String, String> items,
    required String value,
    required Color textColor,
    required ValueChanged<String?> onChange,
  }) {
    final theme = Theme.of(context);
    final selected = items.containsValue(value) ? value : items.values.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          dropdownColor: theme.cardColor,
          isExpanded: true,
          style: TextStyle(color: textColor, fontSize: 16),
          items: items.entries
              .map((e) => DropdownMenuItem<String>(value: e.value, child: Text(e.key, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: onChange,
        ),
      ),
    );
  }
}