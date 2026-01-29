import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../models/lobby_data.dart';
import '../widgets/game_avatar.dart';
import '../widgets/base_scaffold.dart'; // Import BaseScaffold

class GameOverScreen extends StatelessWidget {
  // FIX: Key constructor
  const GameOverScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final lobby = game.lobby;
    final theme = Theme.of(context);

    if (lobby == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final players = List<Player>.from(lobby.players);
    players.sort((a, b) => b.score.compareTo(a.score));

    final winner = players.isNotEmpty ? players[0] : null;
    final second = players.length > 1 ? players[1] : null;
    final third = players.length > 2 ? players[2] : null;

    // FIX: Use BaseScaffold
    return BaseScaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Text("GAME OVER", style: theme.textTheme.titleLarge?.copyWith(letterSpacing: 3, color: Colors.white)),
            const SizedBox(height: 40),

            SizedBox(
              height: 300, 
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (second != null) _buildPodiumPlace(second, 2, 100, Colors.grey.shade400), 
                  if (winner != null) _buildPodiumPlace(winner, 1, 140, Colors.amber),        
                  if (third != null) _buildPodiumPlace(third, 3, 70, Colors.brown.shade400),
                ],
              ),
            ),

            const SizedBox(height: 40),

            if (players.length > 3)
              GlassContainer(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: players.sublist(3).map((p) => ListTile(
                    leading: GameAvatar(path: p.avatar ?? "", radius: 18), 
                    title: Text(p.name, style: TextStyle(color: theme.colorScheme.onSurface)),
                    trailing: Text("${p.score} pts", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                  )).toList(),
                ),
              ),

            const SizedBox(height: 40),

            if (game.amIHost) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text("PLAY AGAIN", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(300, 50)),
                onPressed: () => game.playAgain(),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                icon: Icon(Icons.settings, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                label: Text("Back to Lobby", style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                onPressed: () => game.resetToLobby(),
              ),
            ] else
              TextButton(
                onPressed: () => game.leaveLobby(),
                child: const Text("Leave Lobby", style: TextStyle(color: Colors.redAccent)),
              ),
            const SizedBox(height: 40),
          ],
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
          GameAvatar(
            path: p.avatar ?? "assets/avatars/avatar1.webp",
            radius: rank == 1 ? 40 : 30,
            borderColor: color,
          ),
          const SizedBox(height: 10),
          Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text("${p.score} pts", style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            width: 80,
            height: height,
            decoration: BoxDecoration(
              // FIX: withValues
              color: color.withValues(alpha: 0.8),
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