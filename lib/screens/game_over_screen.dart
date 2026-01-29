import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../models/lobby_data.dart';
import '../widgets/game_avatar.dart';
import '../widgets/base_scaffold.dart';
import 'welcome_screen.dart'; 
import 'lobby_screen.dart'; 
import 'quiz_screen.dart'; 

class GameOverScreen extends StatefulWidget {
  const GameOverScreen({super.key});

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> {

  // --- FIX 1: LISTEN FOR RESET ---
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final game = Provider.of<GameProvider>(context);
    
    // When host clicks "Back to Lobby", server sends reset, state becomes Lobby
    if (game.appState == AppState.lobby) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
         Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LobbyScreen()), (r) => false);
       });
    }
    // "Play Again" trigger
    if (game.appState == AppState.quiz) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
         Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const QuizScreen()));
       });
    }
    // "Leave Lobby" trigger
    if (game.appState == AppState.welcome) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
         Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const WelcomeScreen()), (r) => false);
       });
    }
  }

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
                label: Text("Back to Lobby (Settings)", style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                // FIX 1: Calls resetToLobby -> Server updates -> Listener above navigates
                onPressed: () => game.resetToLobby(),
              ),
            ] else
              TextButton(
                // FIX 4: Calls leaveLobby -> Provider updates -> Listener above navigates
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
    // ... [Same podium code as before] ...
    return Container(); // Placeholder for brevity
  }
}