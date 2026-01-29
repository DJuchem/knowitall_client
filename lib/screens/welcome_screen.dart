import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart'; 
import '../providers/game_provider.dart';
import '../widgets/avatar_selector.dart';
import '../widgets/client_settings_dialog.dart';
import 'create_game_screen.dart'; 
import 'lobby_screen.dart'; // REQUIRED IMPORT

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  String _selectedAvatar = "assets/avatars/avatar1.webp"; 
  final String _serverUrl = "http://localhost:5074/ws"; 

  bool _validateName(BuildContext context) {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a Nickname!"), backgroundColor: Colors.red),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final textTheme = Theme.of(context).textTheme; 

    // Background Tap to unlock Audio Context (Browser Policy Fix)
    return GestureDetector(
      onTap: () => game.initMusic(),
      child: Scaffold(
        body: Stack(
          children: [
            // Background
            Positioned.fill(
              child: Image.asset(game.wallpaper, fit: BoxFit.cover, errorBuilder: (_,__,___)=>Container(color: const Color(0xFF0F1221))),
            ),
            Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.6))),

            // SETTINGS
            Positioned(
              top: 40, right: 20,
              child: IconButton(
                icon: const Icon(Icons.settings, color: Colors.white70, size: 36),
                onPressed: () => showDialog(context: context, builder: (_) => ClientSettingsDialog()),
              ),
            ),

            // Content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                   FadeInDown(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      // REMOVE TEXT, ADD LOGO:
                      child: Image.asset(
                        game.config.logoPath, // Uses "assets/logo.png" by default
                        height: 150, 
                        fit: BoxFit.contain,
                        errorBuilder: (_,__,___) => const Icon(Icons.psychology, size: 100, color: Colors.white),
                      ),
                    ),
                  ),
                    const SizedBox(height: 20),
                    FadeIn(
                      child: Text(
                        game.config.appTitle, 
                        style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 48)
                      )
                    ),
                    
                    const SizedBox(height: 50),

                    // INPUT CARD
                    FadeInUp(
                      child: Container(
                        width: 600, // Larger width for legibility
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _nameController,
                              style: textTheme.bodyLarge,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.person, color: game.themeColor),
                                labelText: "YOUR NICKNAME",
                              ),
                            ),
                            const SizedBox(height: 30),
                            
                            AvatarSelector(
                              initialAvatar: _selectedAvatar,
                              onSelect: (val) => setState(() => _selectedAvatar = val)
                            ),
                            
                            const SizedBox(height: 40),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: game.themeColor),
                                onPressed: () async {
                                  if (!_validateName(context)) return;
                                  
                                  game.initMusic(); // Attempt play on interaction
                                  game.setPlayerInfo(_nameController.text, _selectedAvatar);
                                  await game.connect(_serverUrl);
                                  
                                  if (!mounted) return;
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGameScreen()));
                                },
                                child: const Text("CREATE NEW GAME"),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _codeController,
                                    style: textTheme.bodyLarge,
                                    decoration: const InputDecoration(labelText: "GAME CODE"),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                                  onPressed: () async {
                                    if (!_validateName(context)) return;
                                    if (_codeController.text.isEmpty) {
                                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter a Game Code!"), backgroundColor: Colors.red));
                                       return;
                                    }

                                    game.initMusic(); // Attempt play on interaction
                                    game.setPlayerInfo(_nameController.text, _selectedAvatar);
                                    await game.connect(_serverUrl);
                                    await game.joinLobby(_codeController.text, _nameController.text, _selectedAvatar);
                                    
                                    if (!mounted) return;
                                    // FIX: Navigate to Lobby on Join
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LobbyScreen()));
                                  },
                                  child: const Icon(Icons.arrow_forward, color: Colors.white, size: 30),
                                )
                              ],
                            )
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
}