import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/game_provider.dart';
import '../widgets/avatar_selector.dart';
import '../widgets/client_settings_dialog.dart';
import '../widgets/game_avatar.dart'; 
import 'create_game_screen.dart';
import 'lobby_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  
  // Set your server URL here
  final String _serverUrl = "http://localhost:5271/quizhub"; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final game = Provider.of<GameProvider>(context, listen: false);
      if (game.myName.isNotEmpty && game.myName != "Player") {
        setState(() => _nameController.text = game.myName);
      }
      game.connect(_serverUrl);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);

    if (game.appState == AppState.lobby) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LobbyScreen()));
      });
    }

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // Background
            Positioned.fill(
              child: Image.asset(game.wallpaper, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.black)),
            ),
            Positioned.fill(child: Container(color: Colors.black.withOpacity(0.5))),

            // Settings
            Positioned(
              top: 50, right: 20,
              child: IconButton(
                icon: const Icon(Icons.settings, color: Colors.white70, size: 32),
                onPressed: () => showDialog(context: context, builder: (_) => const ClientSettingsDialog()),
              ),
            ),

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeInDown(
                      child: const Text(
                        "KNOW IT ALL",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                          shadows: [Shadow(color: Colors.purpleAccent, blurRadius: 40)]
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Avatar
                    FadeInDown(
                      delay: const Duration(milliseconds: 200),
                      child: GestureDetector(
                        onTap: () => _showAvatarPicker(context, game),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 15)],
                              ),
                              child: GameAvatar(path: game.myAvatar, radius: 60),
                            ),
                            const SizedBox(height: 12),
                            const Text("TAP TO EDIT", style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.5)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Input Box
                    FadeInUp(
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 400),
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white12),
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _nameController,
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                labelText: "NICKNAME",
                                labelStyle: const TextStyle(color: Colors.white54),
                                floatingLabelBehavior: FloatingLabelBehavior.auto,
                                filled: true,
                                fillColor: Colors.black26,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                              ),
                              onChanged: (val) => game.saveUser(val, game.myAvatar),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // CREATE BUTTON
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purpleAccent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 4,
                                ),
                                onPressed: () {
                                  if (_nameController.text.trim().isEmpty) return;
                                  game.saveUser(_nameController.text.trim(), game.myAvatar);
                                  game.setAppState(AppState.create);
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGameScreen()));
                                },
                                child: const Text("CREATE GAME", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // JOIN ROW
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _codeController,
                                    style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 2),
                                    textAlign: TextAlign.center,
                                    textCapitalization: TextCapitalization.characters,
                                    decoration: InputDecoration(
                                      hintText: "CODE",
                                      hintStyle: const TextStyle(color: Colors.white30),
                                      filled: true,
                                      fillColor: Colors.black26,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  height: 56,
                                  width: 100,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      elevation: 4,
                                    ),
                                    onPressed: () async {
                                      if (_nameController.text.trim().isEmpty || _codeController.text.trim().length < 4) return;
                                      game.saveUser(_nameController.text.trim(), game.myAvatar);
                                      await game.joinLobby(_codeController.text.trim().toUpperCase(), _nameController.text.trim(), game.myAvatar);
                                    },
                                    child: const Text("JOIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
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
          ],
        ),
      ),
    );
  }

  void _showAvatarPicker(BuildContext context, GameProvider game) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: 450,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const Text("CHOOSE AVATAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            
            // Upload button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54), padding: const EdgeInsets.symmetric(vertical: 14)),
                icon: const Icon(Icons.upload),
                label: const Text("UPLOAD IMAGE"),
                onPressed: () { game.pickAvatar(); Navigator.pop(context); },
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 16, mainAxisSpacing: 16),
                itemCount: game.scannedAvatars.length,
                itemBuilder: (ctx, i) {
                  final path = game.scannedAvatars[i];
                  return GestureDetector(
                    onTap: () {
                      game.saveUser(game.myName, path);
                      Navigator.pop(context);
                    },
                    child: GameAvatar(path: path, radius: 30),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}