import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/lobby_data.dart';
import '../widgets/game_avatar.dart';
import '../widgets/base_scaffold.dart';

class GameOverScreen extends StatefulWidget {
  const GameOverScreen({super.key});

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> {
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

    return BaseScaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Text(
              "GAME OVER",
              style: theme.textTheme.titleLarge?.copyWith(letterSpacing: 3, color: Colors.white),
            ),
            const SizedBox(height: 40),

            SizedBox(
              height: 320,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (second != null) _buildPodiumPlace(second, 2, 110, Colors.grey.shade400),
                  if (winner != null) _buildPodiumPlace(winner, 1, 160, Colors.amber),
                  if (third != null) _buildPodiumPlace(third, 3, 85, Colors.brown.shade400),
                ],
              ),
            ),

            const SizedBox(height: 40),

            if (game.amIHost) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text("PLAY AGAIN", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(300, 50),
                ),
                onPressed: () => game.playAgain(),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                icon: Icon(Icons.settings, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                label: Text(
                  "Back to Lobby (Settings)",
                  style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
                onPressed: () => game.resetToLobby(),
              ),
            ] else ...[
              TextButton(
                onPressed: () => game.leaveLobby(),
                child: const Text("Leave Lobby", style: TextStyle(color: Colors.redAccent)),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumPlace(Player p, int rank, double height, Color color) {
    final medal = rank == 1 ? "🥇" : (rank == 2 ? "🥈" : "🥉");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Avatar + name + score
          Column(
            children: [
              GameAvatar(path: p.avatar ?? "", radius: rank == 1 ? 40 : 34),
              const SizedBox(height: 8),
              Text(
                "$medal ${p.name}",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "${p.score}",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16),
              ),
              const SizedBox(height: 10),
            ],
          ),

          // Podium block
          Container(
            width: 110,
            height: height,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white12),
            ),
            child: Center(
              child: Text(
                "#$rank",
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
