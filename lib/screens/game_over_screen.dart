import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../models/lobby_data.dart';

class GameOverScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final lobby = game.lobby;

    if (lobby == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Sort players by score
    final players = List<Player>.from(lobby.players);
    players.sort((a, b) => b.score.compareTo(a.score));

    final winner = players.isNotEmpty ? players[0] : null;
    final second = players.length > 1 ? players[1] : null;
    final third = players.length > 2 ? players[2] : null;

    return Scaffold(
      body: CyberpunkBackground(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 60),
              const Text("GAME OVER", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 3)),
              const SizedBox(height: 40),

              // --- PODIUM (Fixed Overflow) ---
              SizedBox(
                height: 300, // INCREASED CONTAINER HEIGHT
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (second != null) _buildPodiumPlace(second, 2, 100, Colors.grey.shade400), // Reduced Height
                    if (winner != null) _buildPodiumPlace(winner, 1, 140, Colors.amber),        // Reduced Height
                    if (third != null) _buildPodiumPlace(third, 3, 70, Colors.brown.shade400),  // Reduced Height
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // --- REST OF PLAYERS ---
              if (players.length > 3)
                GlassContainer(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: players.sublist(3).map((p) => ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.white10, child: Text(p.name[0])),
                      title: Text(p.name, style: const TextStyle(color: Colors.white)),
                      trailing: Text("${p.score} pts", style: const TextStyle(color: AppTheme.accentPink, fontWeight: FontWeight.bold)),
                    )).toList(),
                  ),
                ),

              const SizedBox(height: 40),

              // --- CONTROLS ---
              if (game.amIHost) ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("PLAY AGAIN (Same Settings)"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(300, 50)),
                  onPressed: () => game.playAgain(),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  icon: const Icon(Icons.settings, color: Colors.white70),
                  label: const Text("Back to Lobby / Setup", style: TextStyle(color: Colors.white70)),
                  onPressed: () => game.resetToLobby(),
                ),
              ] else ...[
                const Text("Waiting for Host...", style: TextStyle(color: Colors.white54)),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    game.leaveLobby(); 
                  },
                  child: const Text("Leave Lobby", style: TextStyle(color: Colors.redAccent)),
                )
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumPlace(Player p, int rank, double height, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color.withValues(alpha: 0.2), // Fixed deprecated
            child: Text(p.name[0].toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 20)),
          ),
          const SizedBox(height: 10),
          Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text("${p.score} pts", style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            width: 80,
            height: height,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.8), // Fixed deprecated
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border.all(color: Colors.white30)
            ),
            alignment: Alignment.center,
            child: Text("$rank", style: const TextStyle(color: Colors.black54, fontSize: 40, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}