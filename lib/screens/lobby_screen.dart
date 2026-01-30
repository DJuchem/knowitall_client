import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../models/lobby_data.dart';
import '../widgets/chat_sheet.dart';
import '../widgets/lobby_settings_sheet.dart';
import '../widgets/game_avatar.dart';
import '../screens/quiz_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({Key? key}) : super(key: key);

  @override
  _LobbyScreenState createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  int _prevPlayerCount = 0;
  bool _didNavToQuiz = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final game = Provider.of<GameProvider>(context, listen: false);
      if (game.lobby != null) {
        _prevPlayerCount = game.lobby!.players.length;
      }
    });
  }

  void _checkNavigation(GameProvider game) {
    // If lobby was deleted (host left), navigate back
    if (game.lobby == null && game.appState == AppState.welcome) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
      return;
    }

    // Navigate to Quiz
    if (_didNavToQuiz) return;
    if (game.appState == AppState.quiz) {
      _didNavToQuiz = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const QuizScreen()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final lobby = game.lobby;
    
    // Safety check
    if (lobby == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    _checkNavigation(game);

    // Snackbar for players leaving
    if (lobby.players.length < _prevPlayerCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("A player left the game."), backgroundColor: Colors.orange),
          );
        }
      });
    }
    _prevPlayerCount = lobby.players.length;

    bool isHost = game.amIHost;
    bool isPlayerReady(Player p) => (p.name == lobby.host) || p.isReady;
    int readyCount = lobby.players.where(isPlayerReady).length;
    bool allReady = lobby.players.isNotEmpty && readyCount == lobby.players.length;
    bool iAmReady = false;
    try {
      iAmReady = lobby.players.firstWhere((p) => p.name == game.myName).isReady;
    } catch (_) {}

    return Scaffold(
      extendBodyBehindAppBar: true, // ✅ Fix 3: No black bar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // We use custom close button
        actions: [
          if (isHost)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: IconButton(
                icon: Icon(Icons.settings, color: Colors.white, size: 32), // ✅ Mobile friendly size
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => LobbySettingsSheet(),
                ),
              ),
            )
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Image.asset(
            game.wallpaper,
            fit: BoxFit.cover,
          ),
          
          // Dark Overlay for readability
          Container(color: Colors.black.withOpacity(0.3)),

          // Main Content
          SafeArea(
            bottom: false, // We handle bottom padding for ChatSheet
            child: Column(
              children: [
                const SizedBox(height: 10), // Space from top

                // --- LOBBY CODE ---
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: lobby.code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Lobby Code Copied!")),
                    );
                  },
                  child: Column(
                    children: [
                      Text(
                        "LOBBY CODE",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          letterSpacing: 2,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          lobby.code,
                          style: const TextStyle(
                            fontSize: 72, // ✅ Bigger
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 4,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // --- INFO PILL ---
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: game.themeColor, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       if (game.isMusicEnabled && !game.isMusicPlaying) ...[
                        GestureDetector(
                          onTap: () => game.initMusic(),
                          child: Row(
                            children: const [
                              Icon(Icons.volume_off, color: Colors.redAccent, size: 20),
                              SizedBox(width: 8),
                              Text("TAP TO UNMUTE", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                              SizedBox(width: 12),
                              Text("|", style: TextStyle(color: Colors.white54)),
                              SizedBox(width: 12),
                            ],
                          ),
                        ),
                      ],
                      Text(
                        "${lobby.mode.toUpperCase()}  •  ${lobby.timer}s  •  ${lobby.difficulty ?? 'Mixed'}",
                        style: TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 16 // ✅ Legible size
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // --- PLAYER LIST ---
                Expanded(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 600), // Max width for tablets/desktop
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: lobby.players.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final p = lobby.players[i];
                        bool ready = p.name == lobby.host || p.isReady;
                        bool isMe = p.name == game.myName;

                        return Container(
                          decoration: BoxDecoration(
                            // ✅ Fix 2: Less transparent background
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isMe 
                                ? Colors.amber 
                                : (ready ? Colors.green.withOpacity(0.8) : Colors.white12),
                              width: isMe ? 2 : 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: GameAvatar(path: p.avatar ?? "", radius: 30), // ✅ Bigger avatar
                            title: Text(
                              p.name + (p.name == lobby.host ? " (HOST)" : ""),
                              style: const TextStyle(
                                color: Colors.white, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 18 // ✅ Bigger text
                              ),
                            ),
                            trailing: Icon(
                              ready ? Icons.check_circle : Icons.hourglass_empty,
                              color: ready ? Colors.greenAccent : Colors.white24,
                              size: 32,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // --- START BUTTON (With padding to clear Chat) ---
                // ✅ Fix 1: Added SafeArea bottom + padding
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 90), // Bottom 90px clears chat bar
                  child: SizedBox(
                    height: 60, // ✅ Mobile friendly button height
                    child: isHost
                      ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: allReady ? Colors.green : Colors.grey[800],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 8,
                          ),
                          onPressed: allReady ? () => game.startGame() : null,
                          child: Text(
                            allReady ? "START GAME" : "WAITING FOR PLAYERS ($readyCount/${lobby.players.length})",
                            style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18),
                          ),
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: iAmReady ? Colors.redAccent : Colors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 8,
                          ),
                          onPressed: () => game.toggleReady(!iAmReady),
                          child: Text(
                            iAmReady ? "CANCEL READY" : "I'M READY!",
                            style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 20),
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),

          // --- LEAVE BUTTON (Top Left) ---
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: GestureDetector(
              onTap: () => _confirmLeave(context, game),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9), // Solid red for visibility
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ),

          // --- CHAT SHEET (Bottom) ---
          Align(
            alignment: Alignment.bottomCenter,
            child: ChatSheet(),
          )
        ],
      ),
    );
  }

  void _confirmLeave(BuildContext context, GameProvider game) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Leave Game?", style: TextStyle(color: Colors.white)),
        content: Text(
          game.amIHost ? "As host, this will end the game for everyone." : "Are you sure you want to leave?",
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("LEAVE", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onPressed: () {
              game.leaveLobby();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}