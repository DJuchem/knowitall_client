import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'account_screen.dart';

import '../providers/game_provider.dart';
import '../widgets/base_scaffold.dart';
import '../widgets/client_settings_sheet.dart';
import '../widgets/avatar_selection_sheet.dart';
import 'login_screen.dart';
import 'register_screen.dart';

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
  late Animation<double> _textSize;
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
      duration: const Duration(milliseconds: 1500),
    );

    // 1. Text Fades In
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.25, curve: Curves.easeIn)),
    );

    // 2. Text Collapses/Removes
    _textSize = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 0.75, curve: Curves.easeInOut)),
    );

    // 3. Logo Bounces In
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.6, curve: Curves.elasticOut)),
    );

    // 4. UI Slides Up
    _uiOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0, curve: Curves.easeIn)),
    );
    _uiSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0, curve: Curves.easeOutQuad)),
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
    if (!Provider.of<GameProvider>(context, listen: false).isLoggedIn) {
      setState(() {
        if (prefs.containsKey('username')) _nameController.text = prefs.getString('username')!;
        if (prefs.containsKey('avatar')) _selectedAvatar = _cleanPath(prefs.getString('avatar')!);
      });
    }
  }

  Future<void> _saveUserPrefs() async {
    if (!Provider.of<GameProvider>(context, listen: false).isLoggedIn) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', _nameController.text.trim());
      await prefs.setString('avatar', _selectedAvatar);
    }
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
    if (Provider.of<GameProvider>(context, listen: false).isLoggedIn) return true;

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
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text("CONNECT TO TV", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _tvCodeController,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 8, color: Colors.white),
          decoration: InputDecoration(
            hintText: "ABCD",
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.1)),
            border: const OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
            onPressed: () async {
              if (_tvCodeController.text.isNotEmpty) {
                await game.linkTv(_tvCodeController.text.toUpperCase());
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    String avatarPath = game.isLoggedIn ? game.myAvatar : _selectedAvatar;
    bool isCustom = avatarPath.startsWith("data:");
    ImageProvider displayImage = isCustom
        ? MemoryImage(base64Decode(avatarPath.split(',')[1]))
        : AssetImage(_getAssetPath(avatarPath)) as ImageProvider;

    return BaseScaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // 🎬 Fade In Left Icons
        leading: FadeTransition(
          opacity: _uiOpacity,
          child: IconButton(
            icon: const Icon(Icons.tv, color: Colors.white),
            tooltip: "Connect TV",
            onPressed: () => _showTvDialog(context, game),
          ),
        ),
     actions: [
          // 🟢 AUTH BUTTONS
          FadeTransition(
            opacity: _uiOpacity,
            child: game.isLoggedIn 
              ? IconButton(
                  icon: const Icon(Icons.person, color: Colors.cyanAccent), // User Profile Icon
                  tooltip: "My Account",
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen())),
                )
              : Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.login, color: Colors.white),
                      tooltip: "Login",
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_add, color: Colors.cyanAccent),
                      tooltip: "Register",
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    ),
                  ],
                ),
          ),
          // Settings Icon
          FadeTransition(
            opacity: _uiOpacity,
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const ClientSettingsSheet(),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                
                // 🎬 PHASE 1: "WELCOME TO"
                SizeTransition(
                  sizeFactor: _textSize,
                  axisAlignment: 1.0,
                  child: FadeTransition(
                    opacity: _textSize,
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: Column(
                        children: [
                          Text(
                            "WELCOME TO",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              letterSpacing: 6.0,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),

                // 🎬 PHASE 2: LOGO FLY IN
                ScaleTransition(
                  scale: _logoScale,
                  child: Hero(
                    tag: 'app_logo',
                    child: Image.asset(
                      _getAssetPath(game.config.logoPath),
                      height: screenHeight * 0.25,
                      fit: BoxFit.contain,
                      errorBuilder: (_,__,___) => const Icon(Icons.quiz, size: 150, color: Colors.amber),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 🎬 PHASE 3: UI SLIDE UP
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
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, spreadRadius: 5),
                        ],
                      ),
                      child: Column(
                        children: [
                          // 🟢 DYNAMIC USER SECTION
                          if (game.isLoggedIn) ...[
                             Text("WELCOME BACK", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                             const SizedBox(height: 8),
                             Text(game.myName.toUpperCase(), style: const TextStyle(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                             const SizedBox(height: 16),
                             Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: theme.colorScheme.primary, width: 3),
                                  boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.4), blurRadius: 15)],
                                ),
                                child: CircleAvatar(radius: 50, backgroundColor: Colors.black26, backgroundImage: displayImage),
                             ),
                             const SizedBox(height: 24),
                          ] else ...[
                             // Guest Edit Mode
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
                          ],

                          // 🟢 CREATE GAME BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8E24AA), // Purple Accent
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 10,
                                shadowColor: const Color(0xFF8E24AA).withOpacity(0.5),
                              ),
                              onPressed: () async {
                                if (!_validateInput(context)) return;
                                if (!game.isLoggedIn) {
                                  await _saveUserPrefs();
                                  game.setPlayerInfo(_nameController.text.trim(), _selectedAvatar);
                                }
                                await game.connect(_serverUrl);
                                game.setAppState(AppState.create);
                              },
                              child: const Text("CREATE NEW GAME", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text("OR JOIN", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // 🟢 JOIN GAME ROW
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Container(
                                  height: 56,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
                                  child: TextField(
                                    controller: _codeController,
                                    textAlign: TextAlign.left,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 4, color: Colors.white),
                                    textCapitalization: TextCapitalization.characters,
                                    decoration: InputDecoration(
                                      hintText: "CODE",
                                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), letterSpacing: 2, fontWeight: FontWeight.bold),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1565C0), // Blue Accent
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      elevation: 0,
                                    ),
                                    onPressed: () async {
                                      if (!_validateInput(context)) return;
                                      final code = _codeController.text.trim();
                                      if (code.isEmpty) return;
                                      
                                      if (!game.isLoggedIn) {
                                        await _saveUserPrefs();
                                        game.setPlayerInfo(_nameController.text.trim(), _selectedAvatar);
                                      }
                                      
                                      await game.connect(_serverUrl);
                                      await game.joinLobby(code, game.myName, game.myAvatar);
                                    },
                                    child: const Text("JOIN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                                  ),
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