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
    // ✅ FIX 2: Reduced duration and disabled looping by default in build
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
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
      // If action succeeds and we forced lobby, ensure we switch state
      if (forceLobby && mounted) {
        Provider.of<GameProvider>(context, listen: false).setAppState(AppState.lobby);
      }
    } catch (e) {
      if (!mounted) return;
      
      // ✅ FIX 4: If we specifically want to go to lobby, ignore errors and Force UI switch.
      if (forceLobby) {
        Provider.of<GameProvider>(context, listen: false).setAppState(AppState.lobby);
        return;
      }

      // If connection drops completely, fallback to welcome
      if (e.toString().contains("Invocation canceled") || e.toString().contains("SocketException")) {
        Provider.of<GameProvider>(context, listen: false).setAppState(AppState.welcome);
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
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
    final rest = players.length > 3 ? players.sublist(3) : const <Player>[];

    return BaseScaffold(
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    
                    // 1. Fancy Title
                    FadeInDown(
                      duration: const Duration(milliseconds: 800),
                      child: Text(
                        "GAME OVER",
                        style: theme.textTheme.displayMedium?.copyWith(
                          letterSpacing: 4,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 20, spreadRadius: 5),
                            BoxShadow(color: Colors.purpleAccent.withOpacity(0.5), blurRadius: 20, spreadRadius: 5),
                          ]
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),

                    // 2. Podium 
                    // ✅ FIX 1: Adjusted child heights inside _PodiumBar to prevent RenderFlex overflow
                    SizedBox(
                      height: 340, 
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (second != null) 
                            FadeInUp(
                              delay: const Duration(milliseconds: 200), 
                              child: _PodiumBar(p: second, rank: 2, height: 100, color: Colors.grey)
                            ),
                          
                          if (winner != null) 
                            ZoomIn(
                              delay: const Duration(milliseconds: 400), 
                              child: _PodiumBar(p: winner, rank: 1, height: 140, color: Colors.amber, crown: true)
                            ),
                          
                          if (third != null) 
                            FadeInUp(
                              delay: const Duration(milliseconds: 600), 
                              child: _PodiumBar(p: third, rank: 3, height: 80, color: Colors.orange)
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 3. Rest of the list
                    if (rest.isNotEmpty)
                      Expanded(
                        child: FadeIn(
                          delay: const Duration(milliseconds: 1000),
                          child: GlassContainer(
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              itemCount: rest.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
                              itemBuilder: (ctx, i) {
                                final p = rest[i];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.white10,
                                    child: Text("#${i + 4}", style: const TextStyle(color: Colors.white)),
                                  ),
                                  title: Text(p.name, style: const TextStyle(color: Colors.white)),
                                  subtitle: Text("${p.score} pts", style: const TextStyle(color: Colors.white54)),
                                  trailing: GameAvatar(path: p.avatar ?? "", radius: 18),
                                );
                              },
                            ),
                          ),
                        ),
                      )
                    else
                      const Spacer(),

                    const SizedBox(height: 20),

                    // 4. Buttons
                    if (game.amIHost) ...[
                      // HOST CONTROLS
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.refresh, color: Colors.white),
                              label: const Text("PLAY AGAIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _safeAction(context, () async => await game.playAgain()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.settings_backup_restore, color: Colors.black87),
                              label: const Text("BACK TO LOBBY", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _safeAction(context, () async {
                                await game.resetToLobby();
                                // Manual state set handled in _safeAction if forceLobby is true
                              }, forceLobby: true), 
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // CLIENT CONTROLS
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.meeting_room, color: Colors.white),
                              label: const Text("RETURN TO WAITING ROOM", style: TextStyle(color: Colors.white)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white54),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                // Clients don't need to notify server to just switch UI to lobby
                                game.setAppState(AppState.lobby);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.exit_to_app, color: Colors.white),
                              label: const Text("LEAVE GAME", style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _safeAction(context, () async => await game.leaveLobby()),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
          
          // Confetti Overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false, // ✅ FIX 2: Stop Looping
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple, Colors.amber],
              emissionFrequency: 0.02, // ✅ FIX 2: Lower frequency
              numberOfParticles: 10,  // ✅ FIX 2: Fewer particles
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumBar extends StatelessWidget {
  final Player p;
  final int rank;
  final double height;
  final Color color;
  final bool crown;

  const _PodiumBar({
    required this.p, 
    required this.rank, 
    required this.height, 
    required this.color,
    this.crown = false,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ FIX 1: Reduced avatar radii and font sizes to fit 340px height
    final double avatarRadius = rank == 1 ? 35 : 25; 

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (crown)
             Pulse(
               infinite: true,
               child: const Padding(
                 padding: EdgeInsets.only(bottom: 4),
                 child: Text("👑", style: TextStyle(fontSize: 24)),
               ),
             ),

          GameAvatar(path: p.avatar ?? "", radius: avatarRadius),
          const SizedBox(height: 8),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 80), // Prevent wide names pushing layout
              child: Text(
                p.name, 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), 
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          const SizedBox(height: 4),
          Text("${p.score}", style: const TextStyle(color: Colors.white70, fontSize: 11)),
          
          const SizedBox(height: 8),
          
          Container(
            width: rank == 1 ? 90 : 70, // Slightly thinner bars
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withOpacity(0.9), color.withOpacity(0.4)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border.all(color: Colors.white30, width: 1),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.4), blurRadius: 15, spreadRadius: 1)
              ]
            ),
            alignment: Alignment.center,
            child: Text("#$rank", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)),
          )
        ],
      ),
    );
  }
}