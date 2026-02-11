import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'account_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

import '../providers/game_provider.dart';
import '../widgets/base_scaffold.dart';
import '../widgets/avatar_selection_sheet.dart';

// ✅ MENU: unified menu button
import '../widgets/app_quick_menu.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _tvCodeController = TextEditingController();
  final _guestCodeController = TextEditingController();

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

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
      ),
    );

    _textSize = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.75, curve: Curves.easeInOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.6, curve: Curves.elasticOut),
      ),
    );

    _uiOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
    _uiSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOutQuad),
          ),
        );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _codeController.dispose();
    _tvCodeController.dispose();
    _guestCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    if (!Provider.of<GameProvider>(context, listen: false).isLoggedIn) {
      setState(() {
        if (prefs.containsKey('username')) {
          _nameController.text = prefs.getString('username')!;
        }
        if (prefs.containsKey('avatar')) {
          _selectedAvatar = _cleanPath(prefs.getString('avatar')!);
        }
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
    if (Provider.of<GameProvider>(context, listen: false).isLoggedIn)
      return true;

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter a Nickname!"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
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
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Scan TV QR Code",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final String? code = barcodes.first.rawValue;
                    if (code != null && code.length == 4) {
                      setState(
                        () => _tvCodeController.text = code.toUpperCase(),
                      );
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
        title: const Text(
          "CONNECT TO TV",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: _tvCodeController,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: "ABCD",
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.1)),
            border: const OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
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
          TextButton(
            child: const Text("CANCEL"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
            ),
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
        leading: null,
        actions: [
          FadeTransition(
            opacity: _uiOpacity,
            child: const AppQuickMenuButton(iconColor: Colors.white),
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
                ScaleTransition(
                  scale: _logoScale,
                  child: Hero(
                    tag: 'app_logo',
                    child: Image.asset(
                      _getAssetPath(game.config.logoPath),
                      height: screenHeight * 0.25,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.quiz,
                        size: 150,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                FadeTransition(
                  opacity: _uiOpacity,
                  child: SlideTransition(
                    position: _uiSlide,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 30,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (game.isLoggedIn) ...[
                            Text(
                              "WELCOME BACK",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              game.myName.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AccountScreen(),
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.colorScheme.primary,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.4),
                                      blurRadius: 15,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.black26,
                                  backgroundImage: displayImage,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ] else ...[
                            const Text(
                              "EDIT AVATAR",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: _openAvatarSheet,
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  CircleAvatar(
                                    radius: 55,
                                    backgroundColor: Colors.black26,
                                    backgroundImage: displayImage,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2979FF),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: TextField(
                                controller: _nameController,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                                decoration: InputDecoration(
                                  hintText: "NICKNAME",
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                    fontWeight: FontWeight.w900,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Guest gate: required to CREATE a game (joining is still allowed).
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: TextField(
                                controller: _guestCodeController,
                                textAlign: TextAlign.center,
                                obscureText: true,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                                decoration: InputDecoration(
                                  hintText: "GUEST ACCESS CODE (CREATE)",
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.25),
                                    fontWeight: FontWeight.w900,
                                  ),
                                  filled: true,
                                  fillColor: Colors.black.withOpacity(0.25),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.15),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.15),
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide(
                                        color: Colors.white.withOpacity(0.25),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const LoginScreen(),
                                      ),
                                    ),
                                    icon: const Icon(Icons.login),
                                    label: const Text(
                                      "Login",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.cyanAccent,
                                      side: BorderSide(
                                        color: Colors.cyanAccent.withOpacity(
                                          0.6,
                                        ),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterScreen(),
                                      ),
                                    ),
                                    icon: const Icon(Icons.person_add),
                                    label: const Text(
                                      "Register",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8E24AA),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 10,
                                shadowColor: const Color(
                                  0xFF8E24AA,
                                ).withOpacity(0.5),
                              ),
                              onPressed: () async {
                                if (!_validateInput(context)) return;

                                if (!game.isLoggedIn) {
                                  final ok = await game.authorizeGuestCreate(
                                    _guestCodeController.text,
                                  );
                                  if (!ok) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          "Guest access code required to create a game",
                                        ),
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                    );
                                    return;
                                  }

                                  await _saveUserPrefs();
                                  game.setPlayerInfo(
                                    _nameController.text.trim(),
                                    _selectedAvatar,
                                  );
                                }

                                await game.connect(_serverUrl);
                                game.setAppState(AppState.create);
                              },
                              child: const Text(
                                "CREATE NEW GAME",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Text(
                                  "OR JOIN",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Container(
                                  height: 56,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: TextField(
                                    controller: _codeController,
                                    textAlign: TextAlign.left,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 4,
                                      color: Colors.white,
                                    ),
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    decoration: InputDecoration(
                                      hintText: "CODE",
                                      hintStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.3),
                                        letterSpacing: 2,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                                      backgroundColor: const Color(0xFF1565C0),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: () async {
                                      if (!_validateInput(context)) return;
                                      final code = _codeController.text.trim();
                                      if (code.isEmpty) return;

                                      if (!game.isLoggedIn) {
                                        await _saveUserPrefs();
                                        game.setPlayerInfo(
                                          _nameController.text.trim(),
                                          _selectedAvatar,
                                        );
                                      }

                                      await game.connect(_serverUrl);
                                      await game.joinLobby(
                                        code,
                                        game.myName,
                                        game.myAvatar,
                                      );
                                    },
                                    child: const Text(
                                      "JOIN",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Optional shortcut if logged in (nice UX, but not required)
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
