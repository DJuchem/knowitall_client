import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/lobby_data.dart';
import '../widgets/chat_sheet.dart';
import '../widgets/lobby_settings_sheet.dart';
import '../theme/app_theme.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final lobby = game.lobby;

    if (lobby == null) return const Scaffold(backgroundColor: AppTheme.primaryColor, body: Center(child: CircularProgressIndicator()));

    bool isHost = game.amIHost;
    bool isPlayerReady(Player p) => (p.name == lobby.host) || p.isReady;
    int readyCount = lobby.players.where(isPlayerReady).length;
    bool allReady = lobby.players.isNotEmpty && readyCount == lobby.players.length;
    
    // Safety check for self
    bool iAmReady = false;
    try {
      iAmReady = lobby.players.firstWhere((p) => p.name == game.myName).isReady;
    } catch (_) {}

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // --- 3. LEAVE GAME BUTTON ---
        leading: IconButton(
          icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
          tooltip: "Leave Game",
          onPressed: () => _confirmLeave(context, game),
        ),
        actions: [
          if (isHost)
            IconButton(
              icon: Icon(Icons.settings, color: game.themeColor), 
              onPressed: () => showModalBottomSheet(
                context: context, 
                isScrollControlled: true, 
                backgroundColor: Colors.transparent,
                builder: (_) => LobbySettingsSheet()
              )
            )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(game.wallpaper), 
            fit: BoxFit.cover, 
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.7), BlendMode.darken),
            onError: (_, __) {} // Fallback handled by scaffold color
          )
        ),
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 100),
                GestureDetector(
                  onTap: () => Clipboard.setData(ClipboardData(text: lobby.code)),
                  child: Column(
                    children: [
                      Text("LOBBY CODE", style: TextStyle(color: Colors.white54, letterSpacing: 2, fontSize: 12)),
                      Text(lobby.code, style: const TextStyle(fontSize: 50, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(border: Border.all(color: game.themeColor), borderRadius: BorderRadius.circular(20)),
                        child: Text("${lobby.mode.toUpperCase()}  •  ${lobby.timer}s  •  ${lobby.difficulty ?? 'Mixed'}", style: TextStyle(color: game.themeColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Player List
                Expanded(
                  child: GlassContainer(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: lobby.players.length,
                      separatorBuilder: (_,__) => const Divider(color: Colors.white10),
                      itemBuilder: (ctx, i) {
                        final p = lobby.players[i];
                        bool ready = p.name == lobby.host || p.isReady;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: AssetImage(p.avatar ?? "assets/avatars/avatar1.webp"),
                            radius: 22,
                            backgroundColor: Colors.grey[800],
                          ),
                          title: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          trailing: Icon(ready ? Icons.check_circle : Icons.hourglass_empty, color: ready ? Colors.greenAccent : Colors.white24),
                        );
                      },
                    ),
                  ),
                ),
                
                // Action Button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  child: isHost 
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: allReady ? Colors.green : Colors.grey[800], 
                          padding: const EdgeInsets.all(20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                        ),
                        onPressed: allReady ? () => game.startGame() : null,
                        child: Text(allReady ? "START GAME" : "WAITING FOR PLAYERS ($readyCount/${lobby.players.length})", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: iAmReady ? Colors.redAccent : Colors.green, 
                          padding: const EdgeInsets.all(20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                        ),
                        onPressed: () => game.toggleReady(!iAmReady),
                        child: Text(iAmReady ? "CANCEL READY" : "I'M READY", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                )
              ],
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
        backgroundColor: AppTheme.surfaceColor,
        title: const Text("Leave Game?", style: TextStyle(color: Colors.white)),
        content: Text(game.amIHost ? "As host, this will end the game for everyone." : "Are you sure you want to leave?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(child: const Text("Cancel"), onPressed: () => Navigator.pop(context)),
          TextButton(
            child: const Text("LEAVE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), 
            onPressed: () { 
              game.leaveLobby(); 
              Navigator.pop(context); 
            }
          ),
        ],
      )
    );
  }
}