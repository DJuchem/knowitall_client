import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../models/lobby_data.dart';
import '../widgets/chat_sheet.dart';
import '../widgets/lobby_settings_sheet.dart';
import '../widgets/game_avatar.dart';
import '../widgets/base_scaffold.dart';

// ✅ ADD THIS (adjust path if your QuizScreen lives elsewhere)
import '../screens/quiz_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({Key? key}) : super(key: key);

  @override
  _LobbyScreenState createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  int _prevPlayerCount = 0;

  // ✅ Guard: prevents repeated pushReplacement during rebuild storms
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

  void _maybeNavigate(GameProvider game) {
    if (_didNavToQuiz) return;

    // ✅ Only navigate when provider says we are in quiz state
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
    final theme = Theme.of(context);

    if (lobby == null) {
      return const BaseScaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ✅ Trigger navigation if the game has started (appState changed)
    _maybeNavigate(game);

    // Snackbar Logic
    if (lobby.players.length < _prevPlayerCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("A player left the game."),
              backgroundColor: Colors.orange,
            ),
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

    return BaseScaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (isHost)
            IconButton(
              icon: Icon(Icons.settings, color: game.themeColor, size: 32),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => LobbySettingsSheet(),
              ),
            )
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 100),
              GestureDetector(
                onTap: () => Clipboard.setData(ClipboardData(text: lobby.code)),
                child: Column(
                  children: [
                    Text(
                      "LOBBY CODE",
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      lobby.code,
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Show button if enabled but blocked
                    if (game.isMusicEnabled && !game.isMusicPlaying)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        icon: const Icon(Icons.volume_off, color: Colors.white),
                        label: const Text(
                          "TAP TO ENABLE SOUND",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => game.initMusic(),
                      ),

                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: game.themeColor, width: 2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${lobby.mode.toUpperCase()}  •  ${lobby.timer}s  •  ${lobby.difficulty ?? 'Mixed'}",
                        style: TextStyle(
                          color: game.themeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: lobby.players.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final p = lobby.players[i];
                      bool ready = p.name == lobby.host || p.isReady;
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: ready ? Colors.green.withValues(alpha: 0.5) : Colors.white10,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: GameAvatar(path: p.avatar ?? "", radius: 28),
                          title: Text(p.name, style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white)),
                          trailing: Icon(
                            ready ? Icons.check_circle : Icons.hourglass_empty,
                            color: ready ? Colors.greenAccent : Colors.white24,
                            size: 30,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                child: isHost
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: allReady ? Colors.green : Colors.grey[800],
                          padding: const EdgeInsets.all(24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: allReady ? () => game.startGame() : null,
                        child: Text(
                          allReady ? "START GAME" : "WAITING ($readyCount/${lobby.players.length})",
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: iAmReady ? Colors.redAccent : Colors.green,
                          padding: const EdgeInsets.all(24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () => game.toggleReady(!iAmReady),
                        child: Text(
                          iAmReady ? "CANCEL READY" : "I'M READY",
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ),
              ),
            ],
          ),

          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => _confirmLeave(context, game),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.redAccent),
                ),
                child: const Icon(Icons.close, color: Colors.redAccent, size: 28),
              ),
            ),
          ),

          Align(alignment: Alignment.bottomCenter, child: ChatSheet())
        ],
      ),
    );
  }

  void _confirmLeave(BuildContext context, GameProvider game) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text("Leave Game?", style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text(
          game.amIHost ? "As host, this will end the game for everyone." : "Are you sure you want to leave?",
          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(child: const Text("Cancel"), onPressed: () => Navigator.pop(context)),
          TextButton(
            child: const Text("LEAVE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
