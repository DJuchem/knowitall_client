import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/game_provider.dart';
import '../widgets/avatar_selector.dart';
import '../widgets/client_settings_dialog.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  // IMPORTANT: must match AvatarSelector.dart paths
  String _selectedAvatar = "assets/avatars/avatar_0.png";

  final String _serverUrl = "http://localhost:5074/ws";

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  bool _validateName(BuildContext context) {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a Nickname!"),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  String cleanPath(String path) {
    // Fix “assets/assets/..” on web
    if (path.startsWith("assets/assets/")) {
      return path.replaceFirst("assets/assets/", "assets/");
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => game.initMusic(),
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                cleanPath(game.wallpaper),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0F1221)),
              ),
            ),
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.6)),
            ),

            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.settings, color: Colors.white70, size: 36),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => ClientSettingsDialog(),
                ),
              ),
            ),

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    FadeInDown(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Image.asset(
                          cleanPath(game.config.logoPath),
                          height: 360,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.psychology,
                            size: 100,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    FadeInUp(
                      child: Container(
                        width: 600,
                        padding: const EdgeInsets.all(34),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withOpacity(0.90),
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
                            const SizedBox(height: 24),

                            AvatarSelector(
                              initialAvatar: cleanPath(_selectedAvatar),
                              onSelect: (val) {
                                setState(() => _selectedAvatar = cleanPath(val));
                              },
                            ),

                            const SizedBox(height: 28),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: game.themeColor),
                                onPressed: () async {
                                  if (!_validateName(context)) return;

                                  game.initMusic();
                                  game.setPlayerInfo(_nameController.text.trim(), cleanPath(_selectedAvatar));
                                  await game.connect(_serverUrl);
                                  game.setAppState(AppState.create);
                                },
                                child: const Text("CREATE NEW GAME"),
                              ),
                            ),

                            const SizedBox(height: 18),

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
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white10,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () async {
                                    if (!_validateName(context)) return;
                                    final code = _codeController.text.trim();
                                    if (code.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Enter a Game Code!"),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    game.initMusic();
                                    game.setPlayerInfo(_nameController.text.trim(), cleanPath(_selectedAvatar));

                                    await game.connect(_serverUrl);
                                    await game.joinLobby(
                                      code,
                                      _nameController.text.trim(),
                                      cleanPath(_selectedAvatar),
                                    );
                                  },
                                  child: const Icon(Icons.arrow_forward, color: Colors.white, size: 30),
                                )
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
}
