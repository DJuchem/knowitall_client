import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/lobby_data.dart';
import '../widgets/game_avatar.dart';
import 'lobby_screen.dart'; // To navigate back
import 'quiz_screen.dart'; // ✅ To navigate if restart happens

class GameOverScreen extends StatefulWidget {
  const GameOverScreen({super.key});

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> {
  bool _in = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _in = true);
      
      // ✅ Resume Music if stopped
      final game = Provider.of<GameProvider>(context, listen: false);
      if (game.isMusicEnabled && !game.isMusicPlaying) {
        game.initMusic();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final lobby = game.lobby;
    
    // ✅ FIX: LISTEN FOR STATE CHANGE TO NAVIGATE AWAY
    if (game.appState == AppState.quiz) {
       // Host clicked Play Again -> Game started instantly
       WidgetsBinding.instance.addPostFrameCallback((_) {
         Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const QuizScreen()));
      });
    } else if (game.appState == AppState.lobby) {
       // Host clicked Reset -> Back to Lobby
       WidgetsBinding.instance.addPostFrameCallback((_) {
         Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LobbyScreen()));
      });
    }

    if (lobby == null) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }

    // Sort players by score
    final sortedPlayers = List<Player>.from(lobby.players)..sort((a, b) => b.score.compareTo(a.score));
    final winner = sortedPlayers.isNotEmpty ? sortedPlayers.first : null;
    final runnerUp = sortedPlayers.length > 1 ? sortedPlayers[1] : null;
    final third = sortedPlayers.length > 2 ? sortedPlayers[2] : null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("GAME OVER", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(game.wallpaper, fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.7)), // Darker overlay

          Column(
            children: [
              const SizedBox(height: 100),
              
              // 🏆 WINNER
              if (winner != null) ...[
                AnimatedScale(
                  scale: _in ? 1.0 : 0.5,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  child: Column(
                    children: [
                      const Text("🏆 WINNER 🏆", style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.amber, boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 20)]),
                        child: GameAvatar(path: winner.avatar ?? "", radius: 80),
                      ),
                      const SizedBox(height: 15),
                      Text(winner.name, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                      Text("${winner.score} PTS", style: const TextStyle(color: Colors.amberAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 50),

              // 🥈 RUNNERS UP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (runnerUp != null) _buildMiniRank(runnerUp, 2),
                  const SizedBox(width: 40),
                  if (third != null) _buildMiniRank(third, 3),
                ],
              ),

              const Spacer(),

              // ✅ ACTION BUTTONS (Host Only)
              if (game.amIHost) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                          ),
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: const Text("PLAY AGAIN", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          onPressed: () => game.playAgain(), // Triggers reset logic
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: Colors.white70),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text("BACK TO LOBBY", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: () => game.resetToLobby(), // Triggers lobby logic
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 50),
                  child: Text("Waiting for Host...", style: TextStyle(color: Colors.white54, fontSize: 16)),
                ),
              ],
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMiniRank(Player p, int rank) {
    return Column(children: [
      Text(rank == 2 ? "🥈 2nd" : "🥉 3rd", style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      GameAvatar(path: p.avatar ?? "", radius: 30),
      const SizedBox(height: 8),
      Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      Text("${p.score}", style: const TextStyle(color: Colors.white54)),
    ]);
  }
}