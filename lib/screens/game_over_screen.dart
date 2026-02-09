import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart'; 
import 'package:animate_do/animate_do.dart'; 
import '../providers/game_provider.dart';
import '../models/lobby_data.dart';
import '../widgets/game_avatar.dart';
import '../widgets/base_scaffold.dart';
import '../theme/app_theme.dart'; 

class GameOverScreen extends StatefulWidget {
  const GameOverScreen({super.key});

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _safeAction(BuildContext context, Future<void> Function() action, {bool forceLobby = false}) async {
    try {
      await action();
      if (forceLobby && mounted) {
        Provider.of<GameProvider>(context, listen: false).setAppState(AppState.lobby);
      }
    } catch (e) {
      if (!mounted) return;
      if (forceLobby) {
        Provider.of<GameProvider>(context, listen: false).setAppState(AppState.lobby);
        return;
      }
      if (e.toString().contains("Invocation canceled") || e.toString().contains("SocketException")) {
        Provider.of<GameProvider>(context, listen: false).setAppState(AppState.welcome);
      }
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

    final players = List<Player>.from(lobby.players);
    players.sort((a, b) => b.score.compareTo(a.score));

    final winner = players.isNotEmpty ? players[0] : null;
    final second = players.length > 1 ? players[1] : null;
    final third = players.length > 2 ? players[2] : null;

    return BaseScaffold(
      body: Stack(
        children: [
          // 🟢 SCROLL VIEW PREVENTS OVERFLOW ON SMALL SCREENS
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 1000,
                  minHeight: MediaQuery.of(context).size.height - 40, 
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 1. HEADER
                      Column(
                        children: [
                          const SizedBox(height: 20),
                          FadeInDown(
                            duration: const Duration(milliseconds: 800),
                            child: Column(
                              children: [
                                Text("GAME OVER", 
                                  style: theme.textTheme.displayMedium?.copyWith(
                                    fontWeight: FontWeight.w900, 
                                    color: Colors.white,
                                    letterSpacing: 4,
                                    shadows: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.8), blurRadius: 30)]
                                  )
                                ),
                                if (winner != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text("Winner: ${winner.name}", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 18, letterSpacing: 2)),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      // 2. THE PODIUM (Centered)
                      // 🟢 INCREASED HEIGHT TO 450 TO PREVENT OVERFLOW
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: SizedBox(
                          height: 450, 
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end, 
                            children: [
                              // 🥈 2ND PLACE
                              if (second != null) 
                                _PodiumColumn(p: second, rank: 2, color: const Color(0xFFC0C0C0), delay: 200, width: 75),
                              
                              const SizedBox(width: 12),

                              // 🥇 1ST PLACE
                              if (winner != null) 
                                _PodiumColumn(p: winner, rank: 1, color: const Color(0xFFFFD700), delay: 600, isWinner: true, width: 95),
                              
                              const SizedBox(width: 12),

                              // 🥉 3RD PLACE
                              if (third != null) 
                                _PodiumColumn(p: third, rank: 3, color: const Color(0xFFCD7F32), delay: 400, width: 75),
                            ],
                          ),
                        ),
                      ),

                      // 3. BUTTONS (Pinned Bottom)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child: Column(
                          children: [
                            if (game.amIHost) ...[
                              SizedBox(
                                height: 90, // 🟢 MEGA BUTTON HEIGHT
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.refresh_rounded, size: 36),
                                        label: const Text("PLAY AGAIN", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF00E676), 
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          elevation: 8,
                                        ),
                                        onPressed: () => _safeAction(context, () async => await game.playAgain()),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.home_rounded, size: 36, color: Colors.white),
                                        label: const Text("LOBBY", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white.withOpacity(0.15),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          side: const BorderSide(color: Colors.white30, width: 2),
                                          elevation: 0,
                                        ),
                                        onPressed: () => _safeAction(context, () async {
                                          await game.resetToLobby();
                                        }, forceLobby: true),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              SizedBox(
                                width: double.infinity,
                                height: 90, // 🟢 MEGA BUTTON HEIGHT
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.exit_to_app_rounded, size: 36),
                                  label: const Text("LEAVE GAME", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.redAccent, width: 2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  onPressed: () => _safeAction(context, () async => await game.leaveLobby()),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.cyan, Colors.purple, Colors.amber, Colors.green],
              gravity: 0.2,
              numberOfParticles: 30,
            ),
          ),
        ],
      ),
    );
  }
}

// 🏛️ CRASH-PROOF PODIUM COLUMN
class _PodiumColumn extends StatelessWidget {
  final Player p;
  final int rank;
  final Color color;
  final int delay;
  final bool isWinner;
  final double width;

  const _PodiumColumn({
    required this.p,
    required this.rank,
    required this.color,
    required this.delay,
    required this.width,
    this.isWinner = false,
  });

  @override
  Widget build(BuildContext context) {
    // 🟢 REDUCED PERCENTAGES to give avatars more room at the top
    final double blockHeightPercentage = isWinner ? 0.45 : (rank == 2 ? 0.35 : 0.25);

    return SizedBox(
      width: width, 
      child: LayoutBuilder(
        builder: (context, constraints) {
          final blockHeight = constraints.maxHeight * blockHeightPercentage;
          
          // 🟢 ElasticInUp creates the "Climb/Jump" effect from bottom
          return ElasticInUp( 
            delay: Duration(milliseconds: delay),
            duration: const Duration(milliseconds: 1500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Avatar Section
                Column(
                  children: [
                    if (isWinner)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Bounce( 
                          delay: Duration(milliseconds: delay + 800),
                          child: const Text("👑", style: TextStyle(fontSize: 32)),
                        ),
                      ),
                    
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 2),
                        boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 10)],
                      ),
                      child: GameAvatar(path: p.avatar ?? "", radius: isWinner ? 35 : 25),
                    ),
                    
                    const SizedBox(height: 6),
                    
                    Text(
                      p.name, 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                    ),
                    
                    Text(
                      "${p.score}", 
                      style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14)
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),

                // 🟢 THE FIX: Stacked Container approach to solve BorderRadius exception
                Stack(
                  children: [
                    // 1. Base Gradient Block (Rounded Top)
                    Container(
                      width: double.infinity,
                      height: blockHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color.withOpacity(0.8), 
                            color.withOpacity(0.3), 
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        // Uniform thin border is safe
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                        ],
                      ),
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        "#$rank", 
                        style: TextStyle(
                          fontSize: isWinner ? 28 : 22, 
                          fontWeight: FontWeight.w900, 
                          color: Colors.white.withOpacity(0.9)
                        ),
                      ),
                    ),
                    
                    // 2. Neon Top Cap (Overlay)
                    Positioned(
                      top: 0, left: 0, right: 0,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          boxShadow: [
                            BoxShadow(color: color.withOpacity(0.8), blurRadius: 8, spreadRadius: 1)
                          ]
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          );
        }
      ),
    );
  }
}