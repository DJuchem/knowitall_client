import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'package:mobile_scanner/mobile_scanner.dart'; 

import '../providers/game_provider.dart';
import '../widgets/base_scaffold.dart';
import '../widgets/client_settings_sheet.dart';
import '../widgets/avatar_selection_sheet.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _tvCodeController = TextEditingController();
  String _selectedAvatar = "avatars/avatar10.webp";

String get _serverUrl {
  // HubConnectionBuilder.withUrl expects HTTP/HTTPS (it negotiates then upgrades to WS/WSS).
  if (kIsWeb) {
    // PROD: same origin (served by your backend/reverse proxy)
    if (kReleaseMode) {
      // ex: https://know-it-all.fun/ws
      return "${Uri.base.scheme}://${Uri.base.host}${Uri.base.hasPort ? ':${Uri.base.port}' : ''}/ws";
    }

    // DEV: Flutter web dev server runs on localhost:<random>, backend on 5074
    // Use 127.0.0.1 to avoid weird localhost resolution on some setups.
    return "http://127.0.0.1:5074/ws";
  }

  // Non-web dev (Android/iOS/Windows/macOS)
  return "http://127.0.0.1:5074/ws";
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
    await prefs.setString('avatar', _selectedAvatar);
  }

String _getAssetPath(String path) {
  if (path.isEmpty) return "";
  if (path.startsWith("data:") || path.startsWith("http")) return path;

  var p = path;
  if (p.startsWith("/")) p = p.substring(1);

  // DO NOT strip "assets/" segments (your project contains assets/assets/...)
  if (!p.startsWith("assets/")) p = "assets/$p";
  return p;
}


String _cleanPath(String path) {
  var p = path.trim();
  if (p.startsWith("/")) p = p.substring(1);

  // Keep the full key if it already starts with assets/ or assets/assets/
  if (p.startsWith("assets/")) return p;

  // Keep relative keys as-is (e.g. avatars/avatar_10.webp)
  return p;
}


  bool _validateInput(BuildContext context) {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text("Please enter a Nickname!"), 
          backgroundColor: Theme.of(context).colorScheme.error));
      return false;
    }
    return true;
  }

void _openAvatarSheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      String localSelected = _selectedAvatar;

      return StatefulBuilder(
        builder: (ctx, setModalState) {
          return AvatarSelectionSheet(
            currentAvatar: localSelected,
            onAvatarSelected: (newPath) {
              // Update immediately inside the modal
              setModalState(() => localSelected = newPath);

              // Persist selection back to the WelcomeScreen
              setState(() => _selectedAvatar = newPath);
            },
          );
        },
      );
    },
  );
}


  // ✅ FIX: Restored QR Scan functionality
  void _openCameraScanner(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 500,
        decoration: const BoxDecoration(color: Colors.black, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                      setState(() => _tvCodeController.text = code.toUpperCase());
                      Navigator.pop(context);
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("CONNECT TO TV"),
        content: TextField(
          controller: _tvCodeController,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 8),
          decoration: InputDecoration(
            hintText: "ABCD",
            border: const OutlineInputBorder(),
            // ✅ FIX: Restored Suffix Icon for QR Scanner
            suffixIcon: IconButton(
              icon: const Icon(Icons.qr_code_scanner, color: Colors.cyanAccent),
              onPressed: () {
                Navigator.pop(context); // Close dialog first
                _openCameraScanner(context); // Open scanner
              },
            ),
          ),
        ),
        actions: [
          TextButton(child: const Text("CANCEL"), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            onPressed: () async {
              if (_tvCodeController.text.isNotEmpty) {
                await game.linkTv(_tvCodeController.text);
                if (context.mounted) Navigator.pop(context);
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
    final isCustom = _selectedAvatar.startsWith("data:");
    final displayImage = isCustom 
        ? MemoryImage(base64Decode(_selectedAvatar.split(',')[1])) 
        : AssetImage(_getAssetPath(_selectedAvatar)) as ImageProvider;

    // Get screen height to size logo dynamically
    final screenHeight = MediaQuery.of(context).size.height;

    return BaseScaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.tv, color: Colors.white),
          onPressed: () => _showTvDialog(context, game),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => showModalBottomSheet(
              context: context, 
              isScrollControlled: true,
              backgroundColor: Colors.transparent, 
              builder: (_) => const ClientSettingsSheet()
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                
                // --- MODIFIED LOGO SECTION ---
                Hero(
                  tag: 'app_logo', 
                  child: Image.asset(
                    _getAssetPath(game.config.logoPath), 
                    // Use 25% of screen height (approx 200-250px on phones)
                    // This creates a large logo that scales with the device.
                    height: screenHeight * 0.25, 
                    width: double.infinity,
                    fit: BoxFit.contain 
                  )
                ),
                // -----------------------------

                const SizedBox(height: 30),

                // Glass Card
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5), 
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      const Text("EDIT AVATAR", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      const SizedBox(height: 16),
                      
                      GestureDetector(
                        onTap: _openAvatarSheet,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(radius: 55, backgroundColor: Colors.black26, backgroundImage: displayImage),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Color(0xFF2979FF), shape: BoxShape.circle),
                              child: const Icon(Icons.edit, size: 16, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TextField(
                          controller: _nameController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                          decoration: InputDecoration(
                            hintText: "NICKNAME", 
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontWeight: FontWeight.w900),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8E24AA),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            if (!_validateInput(context)) return;
                            await _saveUserPrefs();
                            game.setPlayerInfo(_nameController.text.trim(), _selectedAvatar);
                            await game.connect(_serverUrl);
                            game.setAppState(AppState.create);
                          },
                          child: const Text("CREATE GAME", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 55,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
                              child: TextField(
                                controller: _codeController,
                                textAlign: TextAlign.left,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: "CODE", 
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), letterSpacing: 1, fontWeight: FontWeight.bold)
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 55,
                            width: 100,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1565C0), 
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              onPressed: () async {
                                if (!_validateInput(context)) return;
                                final code = _codeController.text.trim();
                                if (code.isEmpty) return;
                                await _saveUserPrefs();
                                game.setPlayerInfo(_nameController.text.trim(), _selectedAvatar);
                                await game.connect(_serverUrl);
                                await game.joinLobby(code, _nameController.text.trim(), _selectedAvatar);
                              },
                              child: const Text("JOIN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                            ),
                          ),
                        ],
                      ),
                    ],
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