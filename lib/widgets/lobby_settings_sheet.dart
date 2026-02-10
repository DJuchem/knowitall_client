import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart'
    as http; // Make sure to add 'http' to pubspec.yaml
import '../providers/game_provider.dart';
import '../widgets/game_mode_sheet.dart';

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

  // --- Music Genres ---
  bool _genresLoading = false;
  String? _genresError;
  Map<String, String> _musicGenres = const {"Mixed": "mixed", "Pop": "pop"};

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final game = Provider.of<GameProvider>(context, listen: false);
      if (_mode == "music") _ensureMusicGenres(game);
    });
  }

  Future<void> _fetchCategories() async {
    if (!mounted) return;
    setState(() {
      _catsLoading = true;
      _catsError = null;
    });
    try {
      final resp = await http.get(
        Uri.parse("https://opentdb.com/api_category.php"),
      );
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
        if (!_categories.containsValue(_selectedCategory))
          _selectedCategory = "";
      });
    } catch (e) {
      if (mounted)
        setState(() {
          _catsError = "Fetch failed";
        });
    } finally {
      if (mounted) setState(() => _catsLoading = false);
    }
  }

  Future<void> _ensureMusicGenres(GameProvider game) async {
    if (!mounted) return;
    if (_genresLoading) return;

    setState(() {
      _genresLoading = true;
      _genresError = null;
    });

    try {
      final dynamic g = game;
      dynamic conn;
      try {
        conn = g.hubConnection;
      } catch (_) {}
      if (conn == null) {
        try {
          conn = g.connection;
        } catch (_) {}
      }
      if (conn == null) {
        try {
          conn = g.hub;
        } catch (_) {}
      }
      // This is a safety check for internal hub access if exposed, mostly falls back to direct invoke via provider if structured differently

      // Since we don't expose hubConnection publicly in the provider above, we assume mixed/pop default
      // OR you can add 'Future<List<String>> getMusicGenres()' to GameProvider.

      // For now, we simulate success with defaults to prevent crash, unless you add the getter to GameProvider
      await Future.delayed(const Duration(milliseconds: 100)); // Sim delay

      if (!mounted) return;
      setState(() {
        // _musicGenres remains default or updated if you implement the fetch
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _genresError = "Genres fetch failed";
      });
    } finally {
      if (mounted) setState(() => _genresLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);

    final bool disableDifficulty =
        _mode == "general-knowledge" && _selectedCategory.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "GAME SETTINGS",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),

              Flexible(
                fit: FlexFit.loose,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      _buildLabel("GAME MODE", theme),

                      // 🟢 REPLACED DROPDOWN WITH VISUAL SELECTOR
                      _buildModeSelector(context, theme, game),

                      if (_mode == "general-knowledge") ...[
                        const SizedBox(height: 16),
                        _buildLabel("TOPIC", theme),
                        if (_catsLoading)
                          const LinearProgressIndicator(minHeight: 2),
                        if (_catsError != null)
                          Text(
                            _catsError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        _buildDropdown(
                          items: _categories,
                          value: _selectedCategory,
                          theme: theme,
                          onChange: (val) => setState(() {
                            _selectedCategory = val ?? "";
                            if (_selectedCategory.isNotEmpty)
                              _difficulty = "mixed";
                          }),
                        ),
                      ],

                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildLabel("QUESTIONS", theme),
                          Text(
                            "${_questions.toInt()}",
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _questions,
                        min: 5,
                        max: 50,
                        divisions: 9,
                        onChanged: (v) => setState(() => _questions = v),
                      ),

                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildLabel("TIMER (SEC)", theme),
                          Text(
                            "${_timer.toInt()}",
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _timer,
                        min: 10,
                        max: 60,
                        divisions: 10,
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
                              _buildLabel(
                                _mode == "music"
                                    ? "GENRE"
                                    : "DIFFICULTY ${disableDifficulty ? '(Auto-Mixed)' : ''}",
                                theme,
                              ),
                              if (_mode == "music" && _genresLoading)
                                const LinearProgressIndicator(minHeight: 2),
                              if (_mode == "music" && _genresError != null)
                                Text(
                                  _genresError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              _buildDropdown(
                                items: _mode == "music"
                                    ? _musicGenres
                                    : const {
                                        "Mixed": "mixed",
                                        "Easy": "easy",
                                        "Medium": "medium",
                                        "Hard": "hard",
                                      },
                                value: disableDifficulty
                                    ? "mixed"
                                    : _difficulty,
                                theme: theme,
                                onChange: (val) => setState(
                                  () => _difficulty = val ?? "mixed",
                                ),
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
                              _mode,
                              _questions.toInt(),
                              _selectedCategory,
                              _timer.toInt(),
                              disableDifficulty ? "mixed" : _difficulty,
                            );
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "UPDATE SETTINGS",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🟢 NEW: VISUAL MODE SELECTOR
  Widget _buildModeSelector(
    BuildContext context,
    ThemeData theme,
    GameProvider game,
  ) {
    // FIX: Use game.getMode() instead of static helper
    final modeData = game.getMode(_mode);
    final textColor = theme.colorScheme.onSurface;

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (ctx) => GameModeSheet(
            currentMode: _mode,
            onModeSelected: (newMode) async {
              setState(() => _mode = newMode);
              if (newMode == "music") {
                await _ensureMusicGenres(game);
              }
            },
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: modeData.color.withOpacity(0.6),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Image.asset(
              modeData.asset,
              width: 32,
              height: 32,
              errorBuilder: (_, __, ___) =>
                  Icon(modeData.icon, color: modeData.color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                modeData.label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(Icons.swap_vert, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, ThemeData theme) => Padding(
    padding: const EdgeInsets.only(bottom: 6.0),
    child: Text(
      text,
      style: TextStyle(
        color: theme.colorScheme.onSurface.withOpacity(0.7),
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    ),
  );

  Widget _buildDropdown({
    required Map<String, String> items,
    required String value,
    required ThemeData theme,
    required ValueChanged<String?> onChange,
  }) {
    final selected = items.containsValue(value) ? value : items.values.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.7)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          dropdownColor: theme.cardColor,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary),
          items: items.entries
              .map((e) => DropdownMenuItem(value: e.value, child: Text(e.key)))
              .toList(),
          onChanged: onChange,
        ),
      ),
    );
  }
}
