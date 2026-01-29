import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../widgets/base_scaffold.dart';
import '../theme/app_theme.dart';

class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({super.key});

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  final _nameCtrl = TextEditingController(text: "Host");
  final _codeCtrl = TextEditingController();

  String _mode = "general-knowledge";
  int _qCount = 10;
  int _timer = 30;
  String _difficulty = "mixed";

  // OpenTDB categories
  bool _loadingCats = true;
  List<Map<String, dynamic>> _cats = [];
  String _catId = "";

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    setState(() => _loadingCats = true);
    try {
      final res = await http.get(Uri.parse("https://opentdb.com/api_category.php"));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (data["trivia_categories"] as List).cast<Map<String, dynamic>>();
      setState(() {
        _cats = list;
        _loadingCats = false;
      });
    } catch (_) {
      setState(() {
        _cats = [];
        _loadingCats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);

    return BaseScaffold(
      showSettings: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => game.goToWelcome(), // no Navigator
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("Create Game",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        )),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: "Host name"),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _codeCtrl,
                      decoration: const InputDecoration(labelText: "Custom code (optional)"),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _mode,
                      decoration: const InputDecoration(labelText: "Mode"),
                      items: game.config.enabledModes
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (v) => setState(() => _mode = v ?? "general-knowledge"),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _qCount,
                            decoration: const InputDecoration(labelText: "Questions"),
                            items: const [5, 10, 15, 20]
                                .map((n) => DropdownMenuItem(value: n, child: Text("$n")))
                                .toList(),
                            onChanged: (v) => setState(() => _qCount = v ?? 10),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 140,
                          child: DropdownButtonFormField<int>(
                            value: _timer,
                            decoration: const InputDecoration(labelText: "Timer"),
                            items: const [15, 20, 30, 45, 60]
                                .map((n) => DropdownMenuItem(value: n, child: Text("${n}s")))
                                .toList(),
                            onChanged: (v) => setState(() => _timer = v ?? 30),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _difficulty,
                      decoration: const InputDecoration(labelText: "Difficulty"),
                      items: const ["mixed", "easy", "medium", "hard"]
                          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (v) => setState(() => _difficulty = v ?? "mixed"),
                    ),
                    const SizedBox(height: 12),

                    // Category only relevant for OpenTDB mode
                    if (_mode == "general-knowledge") ...[
                      _loadingCats
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : DropdownButtonFormField<String>(
                              value: _catId.isEmpty ? "" : _catId,
                              decoration: const InputDecoration(labelText: "Category (OpenTDB)"),
                              items: [
                                const DropdownMenuItem(value: "", child: Text("Any")),
                                ..._cats.map((c) => DropdownMenuItem(
                                      value: "${c['id']}",
                                      child: Text("${c['name']}"),
                                    )),
                              ],
                              onChanged: (v) => setState(() => _catId = v ?? ""),
                            ),
                      const SizedBox(height: 12),
                    ],

                    const SizedBox(height: 10),

                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          final host = _nameCtrl.text.trim();
                          if (host.isEmpty) return;

                          await game.createLobby(
                            host,
                            _mode,
                            _qCount,
                            _catId, // OpenTDB category id (or "")
                            _timer,
                            _difficulty,
                            _codeCtrl.text.trim().toUpperCase(),
                          );
                          // No navigation. Server will emit game_created/lobby_update and provider sets AppState.lobby.
                        },
                        child: const Text("CREATE", style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
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
}
