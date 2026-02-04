import 'package:flutter/material.dart';
import 'package:knowitall_client/widgets/client_settings_sheet.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/game_provider.dart';
import '../widgets/avatar_selector.dart';
import '../widgets/base_scaffold.dart';
import '../theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'package:mobile_scanner/mobile_scanner.dart'; 

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

  // ... (Keep existing _serverUrl, _loadUserPrefs, _saveUserPrefs, _cleanPath, _validateInput methods) ...
  // ... (Keep existing _openCameraScanner and _showTvDialog methods) ...
  
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
    String p = path;
    while (p.startsWith("assets/") || p.startsWith("/assets/")) {
      p = p.replaceFirst("assets/", "").replaceFirst("/assets/", "");
    }
    return p;
  }

  bool _validateInput(BuildContext context) {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Please enter a Nickname!"), backgroundColor: Theme.of(context).colorScheme.error));
      return false;
    }
    return true;
  }

  void _openCameraScanner(BuildContext context) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
            height: 500,
            decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))
            ),
            child: Column(
                children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("Scan TV QR Code", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                        child: MobileScanner(
                            onDetect: (capture) {
                                final List<Barcode> barcodes = capture.barcodes;
                                if (barcodes.isNotEmpty) {
                                    final String? code = barcodes.first.rawValue;
                                    if (code != null && code.length == 4) {
                                        setState(() {
                                            _tvCodeController.text = code.toUpperCase();
                                        });
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Code Scanned!"), backgroundColor: Colors.green));
                                    }
                                }
                            },
                        ),
                    ),
                ],
            ),
        ),
    );
  }

void _showTvDialog(BuildContext context, GameProvider game) {
  final theme = Theme.of(context);
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      title: Center(
        child: Text(
          "CONNECT TO TV",
          style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.tv, size: 60, color: Colors.white54),
          const SizedBox(height: 16),
          const Text(
            "Enter or Scan the 4-letter code displayed on the TV screen:",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _tvCodeController,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.secondary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              hintText: "ABCD",
              fillColor: theme.colorScheme.onSurface.withOpacity(0.05),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: Colors.cyanAccent),
                onPressed: () {
                  Navigator.pop(context);
                  _openCameraScanner(context);
                },
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(child: const Text("CANCEL"), onPressed: () => Navigator.pop(context)),
        ElevatedButton(
          onPressed: () async {
            final code = _tvCodeController.text.trim();
            if (code.isNotEmpty) {
              await game.linkTv(code);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("TV code saved — will link when you create/join a lobby."),
                    backgroundColor: theme.colorScheme.secondary,
                  ),
                );
              }
            }
          },
          child: const Text("CONNECT"),
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
      extendBodyBehindAppBar: true,
      // ✅ FIX: Icons moved to AppBar for perfect alignment
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.tv, color: Colors.white, size: 28),
          onPressed: () => _showTvDialog(context, game),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 28),
            onPressed: () => showModalBottomSheet(
              context: context, 
              backgroundColor: Colors.transparent, 
              builder: (_) => const ClientSettingsSheet()
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. LOGO (Flexible)
              Expanded(
                flex: 3,
                child: Center(
                  child: Hero(
                    tag: 'app_logo',
                    child: Image.asset(
                      _cleanPath(game.config.logoPath),
                      fit: BoxFit.contain,
                      // Ensure it doesn't get ridiculously large on tablets
                      width: 400, 
                      errorBuilder: (_,__,___) => const Icon(Icons.quiz, size: 80, color: Colors.white),
                    ),
                  ),
                ),
              ),

              // 2. PROFILE CARD (Expanded)
              Expanded(
                flex: 6,
                child: FadeInUp(
                  child: GlassContainer(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _nameController,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.person),
                            labelText: "NICKNAME",
                            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Avatar takes remaining space inside card
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
                        
                        const SizedBox(height: 12),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () async {
                              if (!_validateInput(context)) return;
                              await _saveUserPrefs();
                              game.initMusic();
                              game.setPlayerInfo(_nameController.text.trim(), _cleanPath(_selectedAvatar));
                              await game.connect(_serverUrl);
                              game.setAppState(AppState.create);
                            },
                            child: const Text("CREATE NEW GAME", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 3. JOIN GAME (Bottom Fixed)
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Column(
                    children: [
                      Text("OR JOIN A GAME", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: TextField(
                                controller: _codeController,
                                style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, letterSpacing: 3, fontSize: 20),
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: "CODE",
                                  hintStyle: TextStyle(color: Colors.white24),
                                  filled: true,
                                  fillColor: Colors.black38,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 50,
                            width: 60,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.secondary,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
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
                              child: const Icon(Icons.arrow_forward, color: Colors.white, size: 28),
                            ),
                          ),
                        ],
                      ),
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
}