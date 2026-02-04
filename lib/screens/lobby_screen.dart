import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../models/lobby_data.dart';
import '../widgets/chat_sheet.dart';
import '../widgets/lobby_settings_sheet.dart';
import '../widgets/game_avatar.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({Key? key}) : super(key: key);

  @override
  _LobbyScreenState createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  int _prevPlayerCount = 0;

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

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final lobby = game.lobby;
    
    if (lobby == null) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }

    // Dynamic Scaling Logic
    final int playerCount = lobby.players.length;
    final bool isCompact = playerCount > 6;
    final bool isVeryCompact = playerCount > 12;

    double verticalPadding = isVeryCompact ? 2 : (isCompact ? 4 : 8);
    double avatarRadius = isVeryCompact ? 20 : (isCompact ? 24 : 30);
    double nameSize = isVeryCompact ? 14 : (isCompact ? 16 : 18);
    double itemSpacing = isVeryCompact ? 6 : (isCompact ? 8 : 12);

    if (lobby.players.length < _prevPlayerCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("A player left."), backgroundColor: Colors.orange));
      });
    }
    _prevPlayerCount = lobby.players.length;

    bool isHost = game.amIHost;
    bool isPlayerReady(Player p) => (p.name == lobby.host) || p.isReady;
    int readyCount = lobby.players.where(isPlayerReady).length;
    bool allReady = lobby.players.isNotEmpty && readyCount == lobby.players.length;
    bool iAmReady = false;
    try { iAmReady = lobby.players.firstWhere((p) => p.name == game.myName).isReady; } catch (_) {}

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _confirmLeave(context, game);
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.meeting_room_rounded, color: Colors.redAccent, size: 32),
            onPressed: () => _confirmLeave(context, game),
          ),
          actions: [
            if (isHost)
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white, size: 32),
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const LobbySettingsSheet(), 
                ),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(game.wallpaper, fit: BoxFit.cover),
            Container(color: Colors.black.withOpacity(0.3)),

            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: lobby.code));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied!")));
                    },
                    child: Column(
                      children: [
                        Text("LOBBY CODE", style: TextStyle(color: Colors.white.withOpacity(0.8), letterSpacing: 2, fontSize: 14, fontWeight: FontWeight.bold)),
                        FittedBox(child: Text(lobby.code, style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4, height: 1.0))),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(30), border: Border.all(color: game.themeColor, width: 2)),
                    child: Text(
                      "${lobby.mode.toUpperCase()}  •  ${lobby.timer}s  •  ${lobby.difficulty ?? 'Mixed'}", 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 600),
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: playerCount,
                        separatorBuilder: (_, __) => SizedBox(height: itemSpacing),
                        itemBuilder: (ctx, i) {
                          final p = lobby.players[i];
                          bool ready = p.name == lobby.host || p.isReady;
                          bool isMe = p.name == game.myName;

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isMe ? game.themeColor : (ready ? Colors.green.withOpacity(0.8) : Colors.white12), 
                                width: isMe ? 2 : 1
                              ),
                            ),
                            child: ListTile(
                              dense: isCompact,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: verticalPadding),
                              leading: GameAvatar(path: p.avatar ?? "", radius: avatarRadius),
                              title: Text(
                                p.name + (p.name == lobby.host ? " (HOST)" : ""), 
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: nameSize)
                              ),
                              trailing: Icon(
                                ready ? Icons.check_circle : Icons.hourglass_empty, 
                                color: ready ? Colors.greenAccent : Colors.white24, 
                                size: isVeryCompact ? 24 : 32
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 500),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 160), 
                    child: SizedBox(
                      height: 60,
                      child: isHost
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: allReady ? Colors.green : Colors.grey[800], 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                            ),
                            onPressed: allReady ? () => game.startGame() : null,
                            child: Text(allReady ? "START GAME" : "WAITING ($readyCount/$playerCount)", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18)),
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: iAmReady ? Colors.redAccent : Colors.green, 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                            ),
                            onPressed: () => game.toggleReady(!iAmReady),
                            child: Text(iAmReady ? "CANCEL READY" : "I'M READY!", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 20)),
                          ),
                    ),
                  ),
                ],
              ),
            ),

            Align(alignment: Alignment.bottomCenter, child: ChatSheet())
          ],
        ),
      ),
    );
  }

  void _confirmLeave(BuildContext context, GameProvider game) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Leave Game?"),
        actions: [
          TextButton(child: const Text("Cancel"), onPressed: () => Navigator.pop(context)),
          TextButton(
            child: const Text("LEAVE"),
            onPressed: () async {
              Navigator.pop(context);
              await game.leaveLobby();
              game.setAppState(AppState.welcome);
            },
          ),
        ],
      ),
    );
  }
}