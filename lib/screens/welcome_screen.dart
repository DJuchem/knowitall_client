import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/game_provider.dart';
import '../widgets/avatar_selector.dart';
import '../widgets/client_settings_dialog.dart';
import '../widgets/base_scaffold.dart';
import '../theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _tvCodeController = TextEditingController();
  
  String _selectedAvatar = "avatars/avatar_0.png";

  String get _serverUrl {
    // 1. PRODUCTION (Docker / Release Build)
    // Only use the browser URL if we are actually deployed
    if (kReleaseMode && kIsWeb) {
      final location = html.window.location;
      final protocol = location.protocol.contains("https") ? "wss:" : "ws:";
      return "$protocol//${location.host}/ws";
    }
    
    // 2. DEVELOPMENT (Localhost Debugging)
    // Force the address of your .NET server.
    // Use 'localhost:5074' for Windows/Mac or '11111' if using Docker locally
    return "http://localhost:5074/ws"; 
  }

  @override
  void initState() {
    super.initState();
    _loadUserPrefs();
  }

  Future<void> _loadUserPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      if (prefs.containsKey('username')) _nameController.text = prefs.getString('username')!;
      if (prefs.containsKey('avatar')) _selectedAvatar = _cleanPath(prefs.getString('avatar')!);
    });
  }

  Future<void> _saveUserPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', _nameController.text.trim());
    await prefs.setString('avatar', _cleanPath(_selectedAvatar));
  }

  String _cleanPath(String path) {
    if (path.isEmpty) return "";
    String p = path;
    while (p.startsWith("assets/") || p.startsWith("/assets/")) {
      p = p.replaceFirst("assets/", "").replaceFirst("/assets/", "");
    }
    return p;
  }

  bool _validateInput(BuildContext context) {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a Nickname!"), backgroundColor: Colors.red));
      return false;
    }
    return true;
  }

  void _showTvDialog(BuildContext context, GameProvider game) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Connect to TV Spectator", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter the 4-letter code displayed on your TV:", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            TextField(
              controller: _tvCodeController,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4),
              decoration: InputDecoration(
                hintText: "CODE",
                filled: true,
                fillColor: Colors.black54,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(child: const Text("CANCEL"), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
            onPressed: () async {
              final code = _tvCodeController.text.trim();
              if (code.isNotEmpty) {
                await game.linkTv(code);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("TV Connected!"), backgroundColor: Colors.green));
                }
              }
            },
            child: const Text("CONNECT TV", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);

    return BaseScaffold(
      showSettings: true,
      extendBodyBehindAppBar: true,
      onSettingsTap: () => showDialog(context: context, builder: (_) => const ClientSettingsDialog()),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                FadeInDown(
                  child: Image.asset(
                    _cleanPath(game.config.logoPath),
                    height: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.quiz, size: 100, color: Colors.white),
                  ),
                ),
                
                const SizedBox(height: 32),

                FadeInUp(
                  child: GlassContainer(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text("YOUR PROFILE", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        const SizedBox(height: 12),
                        
                        TextField(
                          controller: _nameController,
                          style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.person, color: game.themeColor),
                            labelText: "NICKNAME",
                            labelStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: Colors.black26,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        AvatarSelector(
                          initialAvatar: _cleanPath(_selectedAvatar),
                          onSelect: (val) => setState(() => _selectedAvatar = _cleanPath(val)),
                        ),

                        const SizedBox(height: 32),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: game.themeColor,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                            shadowColor: game.themeColor.withOpacity(0.5),
                          ),
                          onPressed: () async {
                            if (!_validateInput(context)) return;
                            await _saveUserPrefs();
                            game.initMusic();
                            game.setPlayerInfo(_nameController.text.trim(), _cleanPath(_selectedAvatar));
                            await game.connect(_serverUrl);
                            game.setAppState(AppState.create);
                          },
                          child: const Text("CREATE NEW GAME", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ),

                        const SizedBox(height: 20),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 20),

                        // JOIN GAME ROW - WITH OVERFLOW FIX
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _codeController,
                                style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  labelText: "ENTER GAME CODE",
                                  labelStyle: const TextStyle(color: Colors.white54, letterSpacing: 0, fontSize: 14),
                                  filled: true,
                                  fillColor: Colors.black26,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // ✅ FIX: Wrapped in Flexible to prevent overflow crashes
                            Flexible(
                              flex: 0, 
                              child: Container(
                                height: 56,
                                width: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                                  onPressed: () async {
                                    if (!_validateInput(context)) return;
                                    final code = _codeController.text.trim();
                                    if (code.isEmpty) return;
                                    
                                    await _saveUserPrefs();
                                    game.initMusic();
                                    game.setPlayerInfo(_nameController.text.trim(), _cleanPath(_selectedAvatar));
                                    await game.connect(_serverUrl);
                                    await game.joinLobby(code, _nameController.text.trim(), _cleanPath(_selectedAvatar));
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: TextButton.icon(
                    onPressed: () => _showTvDialog(context, game),
                    icon: const Icon(Icons.tv, color: Colors.cyanAccent),
                    label: const Text("CONNECT TO TV", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}