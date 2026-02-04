import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/game_provider.dart';
import '../widgets/avatar_selector.dart';
import '../widgets/client_settings_sheet.dart'; // ✅ CHANGED IMPORT
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
    if (kReleaseMode && kIsWeb) {
      final location = html.window.location;
      return "${location.protocol}//${location.host}/ws";
    }
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
    return path.replaceAll("assets/", "").replaceAll("/assets/", "");
  }

  bool _validateInput(BuildContext context) {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text("Please enter a Nickname!"), backgroundColor: Theme.of(context).colorScheme.error)
      );
      return false;
    }
    return true;
  }

  void _showTvDialog(BuildContext context, GameProvider game) {
    // ... (Keep existing TV dialog logic, it works fine)
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Connect TV"),
        content: TextField(controller: _tvCodeController, decoration: const InputDecoration(hintText: "TV CODE")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
             onPressed: () { 
               game.linkTv(_tvCodeController.text); 
               Navigator.pop(context); 
             }, 
             child: const Text("OK")
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);

    // ✅ Replaced Dialog with BottomSheet
    void openSettings() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const ClientSettingsSheet(),
      );
    }

    return BaseScaffold(
      showSettings: true,
      extendBodyBehindAppBar: true,
      onSettingsTap: openSettings, // ✅ CONNECTED
      body: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          
          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500), 
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start, // ✅ Top Alignment
                    children: [
                      
                      // 1. SPACER (Push content up slightly, but not too much)
                      const SizedBox(height: 20),

                      // 2. LOGO (Bigger and Higher)
                      Flexible(
                        flex: 4, // Increased flex
                        child: FadeInDown(
                          child: Hero(
                            tag: 'app_logo',
                            child: Image.asset(
                              _cleanPath(game.config.logoPath),
                              fit: BoxFit.contain,
                              // ✅ Increased size logic
                              width: double.infinity, 
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),

                      // 3. MAIN CARD (Moved Up via Flex)
                      Expanded(
                        flex: 7, 
                        child: FadeInUp(
                          child: GlassContainer(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // NICKNAME
                                TextField(
                                  controller: _nameController,
                                  style: TextStyle(color: theme.colorScheme.onSurface),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.person),
                                    labelText: "NICKNAME",
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // AVATAR SELECTOR
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.onSurface.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(16)
                                    ),
                                    child: AvatarSelector(
                                      initialAvatar: _cleanPath(_selectedAvatar),
                                      onSelect: (val) => setState(() => _selectedAvatar = _cleanPath(val)),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // CREATE BUTTON (Uses Theme Shape automatically)
                                SizedBox(
                                  width: double.infinity,
                                  height: 60,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (!_validateInput(context)) return;
                                      await _saveUserPrefs();
                                      game.initMusic();
                                      game.setPlayerInfo(_nameController.text.trim(), _cleanPath(_selectedAvatar));
                                      await game.connect(_serverUrl);
                                      game.setAppState(AppState.create);
                                    },
                                    child: const Text("CREATE NEW GAME"),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),

                      // 4. JOIN & TV (Bottom)
                      FadeInUp(
                        delay: const Duration(milliseconds: 200),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 60,
                                    child: TextField(
                                      controller: _codeController,
                                      style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, letterSpacing: 3, fontSize: 20),
                                      textAlign: TextAlign.center,
                                      decoration: const InputDecoration(
                                        hintText: "GAME CODE",
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  height: 60,
                                  width: 70,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.colorScheme.secondary,
                                      padding: EdgeInsets.zero,
                                    ),
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
                                    child: const Icon(Icons.arrow_forward, color: Colors.white, size: 30),
                                  ),
                                ),
                              ],
                            ),
                            
                            TextButton.icon(
                              onPressed: () => _showTvDialog(context, game),
                              icon: Icon(Icons.tv, color: theme.colorScheme.secondary),
                              label: Text("CONNECT TO TV", style: TextStyle(color: theme.colorScheme.secondary)),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}