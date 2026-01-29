import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart'; 
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_selector.dart';
import 'create_game_screen.dart'; 

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GameProvider>(context, listen: false).initMusic();
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.primaryColor, // Fallback color
      body: Stack(
        children: [
          // 1. Dynamic Background with Fallback
          Positioned.fill(
            child: Image.asset(
              game.wallpaper,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(color: AppTheme.primaryColor), // Handle 404 gracefully
            ),
          ),
          
          // 2. Dark Gradient Overlay (Readability)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),

          // 3. Main Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- LOGO ANIMATION ---
                  BounceInDown(
                    duration: const Duration(milliseconds: 1000),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: game.themeColor, width: 2),
                        boxShadow: [BoxShadow(color: game.themeColor.withOpacity(0.5), blurRadius: 30)]
                      ),
                      child: const Icon(Icons.flash_on, size: 60, color: Colors.white),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  FadeIn(
                    delay: const Duration(milliseconds: 500),
                    child: Text("KNOW IT ALL", 
                      style: TextStyle(
                        fontFamily: 'Orbitron', // Ensure font is in pubspec or remove this line
                        fontSize: 40, 
                        fontWeight: FontWeight.w900, 
                        color: Colors.white,
                        letterSpacing: 3,
                        shadows: [Shadow(color: game.themeColor, blurRadius: 10)]
                      )
                    ),
                  ),

                  const SizedBox(height: 40),

                  // --- INPUT CARD ---
                  FadeInUp(
                    delay: const Duration(milliseconds: 800),
                    child: GlassContainer(
                      child: Column(
                        children: [
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.person, color: game.themeColor),
                              labelText: "Enter Your Nickname",
                              labelStyle: const TextStyle(color: Colors.white60),
                              filled: true,
                              fillColor: Colors.black26,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Dynamic Avatar Scanner
                          AvatarSelector(
                            initialAvatar: _selectedAvatar,
                            onSelect: (val) => setState(() => _selectedAvatar = val)
                          ),
                          
                          const SizedBox(height: 30),

                          // NEW GAME BUTTON
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: game.themeColor,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 10,
                                shadowColor: game.themeColor.withOpacity(0.5),
                              ),
                              onPressed: () async {
                                if (_nameController.text.isEmpty) return;
                                game.setPlayerInfo(_nameController.text, _selectedAvatar);
                                await game.connect(_serverUrl);
                                Navigator.push(context, MaterialPageRoute(builder: (_) => CreateGameScreen()));
                              },
                              child: const Text("CREATE NEW GAME", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white)),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Expanded(child: Divider(color: Colors.white24)),
                              const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("OR", style: TextStyle(color: Colors.white54))),
                              const Expanded(child: Divider(color: Colors.white24)),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // JOIN ROW
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _codeController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: "Lobby Code",
                                    prefixIcon: const Icon(Icons.tag, color: Colors.white54),
                                    filled: true, fillColor: Colors.black26,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white10,
                                  padding: const EdgeInsets.all(20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                ),
                                onPressed: () async {
                                  if (_nameController.text.isEmpty || _codeController.text.isEmpty) return;
                                  game.setPlayerInfo(_nameController.text, _selectedAvatar);
                                  await game.connect(_serverUrl);
                                  game.joinLobby(_codeController.text, _nameController.text, _selectedAvatar);
                                },
                                child: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.white),
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
    );
  }
}