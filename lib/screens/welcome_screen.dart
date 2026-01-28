import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_selector.dart';
import 'create_game_screen.dart'; 

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  String _selectedAvatar = "assets/avatars/avatar1.webp";
  
  // ⚠️ IMPORTANT: 
  // For Android Emulator use: "http://10.0.2.2:5074/ws"
  // For Web use: "http://localhost:5074/ws"
  final String _serverUrl = "http://localhost:5074/ws"; 

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context, listen: false);

    return Scaffold(
      // 1. New Styling Wrapper
      body: CyberpunkBackground( 
        child: Center(
          child: SingleChildScrollView(
            child: GlassContainer( // 2. Glass Card Wrapper
              margin: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text("KnowItAll", 
                    style: TextStyle(
                      fontSize: 32, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white,
                      shadows: [Shadow(color: AppTheme.accentBlue, blurRadius: 15)]
                    )
                  ),
                  const SizedBox(height: 30),
                  
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: "Player Name"),
                  ),
                  const SizedBox(height: 20),

                  AvatarSelector(onSelect: (val) => _selectedAvatar = val),
                  
                  const SizedBox(height: 30),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    onPressed: () async {
                      if (_nameController.text.isEmpty) return;
                      game.setPlayerInfo(_nameController.text, _selectedAvatar);
                      
                      try {
                        await game.connect(_serverUrl);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => CreateGameScreen()));
                      } catch (e) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Connection Failed: $e")));
                      }
                    },
                    child: const Text("Create New Game"),
                  ),
                  
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: "Lobby Code"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
                        onPressed: () async {
                          if (_nameController.text.isEmpty || _codeController.text.isEmpty) return;
                          game.setPlayerInfo(_nameController.text, _selectedAvatar);
                          await game.connect(_serverUrl);
                          game.joinLobby(_codeController.text, _nameController.text);
                        },
                        child: const Text("Join"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}