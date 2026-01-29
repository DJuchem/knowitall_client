import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/lobby_data.dart';
import '../widgets/chat_sheet.dart';
import '../widgets/game_avatar.dart';
import '../widgets/base_scaffold.dart';
import 'welcome_screen.dart';
import 'quiz_screen.dart'; 

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
    final theme = Theme.of(context);

    if (game.appState == AppState.quiz && lobby?.quizData != null && lobby!.quizData!.isNotEmpty) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
         Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const QuizScreen()));
       });
       return const BaseScaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (game.appState == AppState.welcome) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
         Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const WelcomeScreen()), (r) => false);
       });
       return const BaseScaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (lobby == null) return const BaseScaffold(body: Center(child: CircularProgressIndicator()));

    if (lobby.players.length < _prevPlayerCount) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
           if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("A player left the game."), backgroundColor: Colors.orange));
        });
    }
    _prevPlayerCount = lobby.players.length;

    // --- HOST LOGIC ---
    bool isHost = game.amIHost;
    bool isPlayerReady(Player p) => (p.name == lobby.host) || p.isReady;
    int readyCount = lobby.players.where(isPlayerReady).length;
    bool allReady = lobby.players.isNotEmpty && readyCount == lobby.players.length;
    
    bool iAmReady = false;
    try { iAmReady = lobby.players.firstWhere((p) => p.name == game.myName).isReady; } catch (_) {}

    return BaseScaffold(
      showSettings: isHost, 
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 100),
              GestureDetector(
                onTap: () => Clipboard.setData(ClipboardData(text: lobby.code)),
                child: Column(
                  children: [
                    Text("LOBBY CODE", style: theme.textTheme.labelLarge?.copyWith(color: Colors.white.withOpacity(0.7), letterSpacing: 2)),
                    Text(lobby.code, style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(border: Border.all(color: game.themeColor, width: 2), borderRadius: BorderRadius.circular(20)),
                      child: Text("${lobby.mode.toUpperCase()}  •  ${lobby.timer}s  •  ${lobby.difficulty ?? 'Mixed'}", style: TextStyle(color: game.themeColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, childAspectRatio: 2.5, crossAxisSpacing: 10, mainAxisSpacing: 10
                    ),
                    itemCount: lobby.players.length,
                    itemBuilder: (ctx, i) {
                      final p = lobby.players[i];
                      bool ready = p.name == lobby.host || p.isReady;
                      return Container(
                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16), border: Border.all(color: ready ? Colors.green : Colors.transparent)),
                        child: Row(
                          children: [
                            Padding(padding: const EdgeInsets.all(8.0), child: GameAvatar(path: p.avatar ?? "", radius: 24)),
                            Expanded(child: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                            if(ready) const Padding(padding: EdgeInsets.only(right:8), child: Icon(Icons.check_circle, color: Colors.green, size: 20))
                          ],
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
                      style: ElevatedButton.styleFrom(backgroundColor: allReady ? Colors.green : Colors.grey[800], padding: const EdgeInsets.all(24)),
                      onPressed: allReady ? () => game.startGame() : null,
                      child: Text(allReady ? "START GAME" : "WAITING (${readyCount}/${lobby.players.length})", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 20)),
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: iAmReady ? Colors.redAccent : Colors.green, padding: const EdgeInsets.all(24)),
                      onPressed: () => game.toggleReady(!iAmReady),
                      child: Text(iAmReady ? "CANCEL READY" : "I'M READY", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 20)),
                    ),
              )
            ],
          ),
          Positioned(top: 50, left: 20, child: GestureDetector(onTap: () => _confirmLeave(context, game), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: Colors.redAccent)), child: const Icon(Icons.close, color: Colors.redAccent, size: 28)))),
          Align(alignment: Alignment.bottomCenter, child: ChatSheet())
        ],
      ),
    );
  }

  void _confirmLeave(BuildContext context, GameProvider game) {
    showDialog(context: context, builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900], title: const Text("Leave?", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(child: const Text("Cancel"), onPressed: () => Navigator.pop(context)),
          TextButton(child: const Text("LEAVE", style: TextStyle(color: Colors.red)), onPressed: () { game.leaveLobby(); Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const WelcomeScreen()), (r) => false); }),
        ],
    ));
  }
}