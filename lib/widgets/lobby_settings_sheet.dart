import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/game_provider.dart';

class LobbySettingsSheet extends StatefulWidget {
  const LobbySettingsSheet({super.key});

  @override
  State<LobbySettingsSheet> createState() => _LobbySettingsSheetState();
}

class _LobbySettingsSheetState extends State<LobbySettingsSheet> {
  late String _mode;
  late double _questions;
  late double _timer;
  late String _difficulty;
  
  late String _selectedCategory;
  bool _catsLoading = false;
  String? _catsError;
  Map<String, String> _categories = {"Any Category": ""};

  @override
  void initState() {
    super.initState();
    final lobby = Provider.of<GameProvider>(context, listen: false).lobby;
    if (lobby != null) {
      _mode = lobby.mode;
      _questions = (lobby.quizData?.length ?? 10).toDouble();
      _timer = lobby.timer.toDouble();
      _difficulty = lobby.difficulty ?? "mixed";
      _selectedCategory = lobby.category ?? "";
    } else {
      _mode = "general-knowledge";
      _questions = 10;
      _timer = 20;
      _difficulty = "mixed";
      _selectedCategory = "";
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
        if (!_categories.containsValue(_selectedCategory)) _selectedCategory = "";
      });
    } catch (e) {
      if (mounted) setState(() { _catsError = "Fetch failed"; });
    } finally {
      if (mounted) setState(() => _catsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);
    
    final bool disableDifficulty = _selectedCategory.isNotEmpty;

    return Container(
      // ✅ FIX: Fixed height (75% of screen) to match other sheets
      height: MediaQuery.of(context).size.height * 0.75,
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
          // Drag Handle
          Center(
            child: Container(
              width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("GAME SETTINGS", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(),
          
          // ✅ FIX: Use Expanded so the list takes all remaining space
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  _buildLabel("GAME MODE", theme),
                  _buildDropdown(
                    items: game.gameModes, 
                    value: _mode,
                    theme: theme,
                    onChange: (val) => setState(() => _mode = val ?? "general-knowledge"),
                  ),

                  if (_mode == "general-knowledge") ...[
                    const SizedBox(height: 16),
                    _buildLabel("TOPIC", theme),
                    if (_catsLoading) const LinearProgressIndicator(minHeight: 2),
                    _buildDropdown(
                      items: _categories,
                      value: _selectedCategory,
                      theme: theme,
                      onChange: (val) => setState(() {
                        _selectedCategory = val ?? "";
                        if (_selectedCategory.isNotEmpty) _difficulty = "mixed";
                      }),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
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
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: disableDifficulty ? 0.4 : 1.0,
                    child: IgnorePointer(
                      ignoring: disableDifficulty,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildLabel("DIFFICULTY ${disableDifficulty ? '(Auto-Mixed)' : ''}", theme),
                          _buildDropdown(
                            items: const {"Mixed": "mixed", "Easy": "easy", "Medium": "medium", "Hard": "hard"},
                            value: disableDifficulty ? "mixed" : _difficulty,
                            theme: theme,
                            onChange: (val) => setState(() => _difficulty = val ?? "mixed"),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        game.updateSettings(
                          _mode, _questions.toInt(), _selectedCategory, _timer.toInt(), 
                          disableDifficulty ? "mixed" : _difficulty
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
          items: items.entries.map((e) => DropdownMenuItem(value: e.value, child: Text(e.key, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: onChange,
        ),
      ),
    );
  }
}