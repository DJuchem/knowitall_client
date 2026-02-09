import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
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

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _tvCodeController = TextEditingController();
  String _selectedAvatar = "avatars/avatar10.webp";

  // 🎬 Animation Controllers
  late AnimationController _controller;
  late Animation<double> _textOpacity;
  late Animation<double> _textSize; // To collapse the text space
  late Animation<double> _logoScale;
  late Animation<double> _uiOpacity;
  late Animation<Offset> _uiSlide;

  String get _serverUrl {
    if (kIsWeb) {
      if (kReleaseMode) {
        return "${Uri.base.scheme}://${Uri.base.host}${Uri.base.hasPort ? ':${Uri.base.port}' : ''}/ws";
      }
      return "http://127.0.0.1:5074/ws";
    }
    return "http://10.0.2.2:5074/ws"; // Android Emulator default
  }

  @override
  void initState() {
    super.initState();
    _loadUserPrefs();

    // 🎬 MASTER CINEMATIC SEQUENCE (2.5 Seconds Total)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // 1. Text Fades In (0s -> 0.6s)
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.25, curve: Curves.easeIn)),
    );

    // 2. Text Collapses/Removes (1.5s -> 1.8s) - THIS REMOVES IT
    _textSize = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 0.75, curve: Curves.easeInOut)),
    );

    // 3. Logo Bounces In (0.5s -> 1.5s)
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.6, curve: Curves.elasticOut)),
    );

    // 4. UI Slides Up (1.8s -> 2.5s)
    _uiOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.easeIn)),
    );
    _uiSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.easeOutQuad)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _codeController.dispose();
    _tvCodeController.dispose();
    super.dispose();
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
    if (!p.startsWith("assets/")) p = "assets/$p";
    return p;
  }

  String _cleanPath(String path) {
    var p = path.trim();
    if (p.startsWith("/")) p = p.substring(1);
    if (p.startsWith("assets/")) return p;
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
                setModalState(() => localSelected = newPath);
                setState(() => _selectedAvatar = newPath);
              },
            );
          },
        );
      },
    );
  }

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
            suffixIcon: IconButton(
              icon: const Icon(Icons.qr_code_scanner, color: Colors.cyanAccent),
              onPressed: () {
                Navigator.pop(context);
                _openCameraScanner(context);
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

    final screenHeight = MediaQuery.of(context).size.height;

    return BaseScaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // 🎬 AppBar Fades In with UI
        leading: FadeTransition(
          opacity: _uiOpacity,
          child: IconButton(
            icon: const Icon(Icons.tv, color: Colors.white),
            onPressed: () => _showTvDialog(context, game),
          ),
        ),
        actions: [
          FadeTransition(
            opacity: _uiOpacity,
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const ClientSettingsSheet()
              ),
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
                
           

                // 🎬 PHASE 2: LOGO FLY IN
                ScaleTransition(
                  scale: _logoScale,
                  child: Hero(
                    tag: 'app_logo',
                    child: Image.asset(
                      _getAssetPath(game.config.logoPath),
                      height: screenHeight * 0.25,
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 🎬 PHASE 3: UI SLIDE UP (Glass Card)
                FadeTransition(
                  opacity: _uiOpacity,
                  child: SlideTransition(
                    position: _uiSlide,
                    child: Container(
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