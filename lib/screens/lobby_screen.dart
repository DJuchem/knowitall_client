import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_sheet.dart';
import '../models/lobby_data.dart';

class LobbyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final lobby = game.lobby;

    if (lobby == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    bool isHost = game.amIHost;
    bool isPlayerReady(Player p) => (p.name == lobby.host) || p.isReady;
    int readyCount = lobby.players.where(isPlayerReady).length;
    bool allReady = lobby.players.isNotEmpty && readyCount == lobby.players.length;

    Player? me;
    try {
      me = lobby.players.firstWhere(
        (p) => p.name.toLowerCase() == game.myName.toLowerCase(),
        orElse: () => lobby.players.first
      );
    } catch (_) {}
    bool iAmReady = (me?.isReady ?? false);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _confirmLeave(context, game),
        ),
        actions: [
          if (isHost)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showSettingsDialog(context, game), // --- NEW SETTINGS DIALOG
            )
        ],
      ),
      body: CyberpunkBackground(
        child: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  const SizedBox(height: 100),
                  GestureDetector(
                    onTap: () => Clipboard.setData(ClipboardData(text: lobby.code)),
                    child: Column(
                      children: [
                        const Text("LOBBY CODE", style: TextStyle(color: Colors.white54, letterSpacing: 2, fontWeight: FontWeight.bold)),
                        Text(lobby.code, style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 5),
                        Text("${lobby.mode.toUpperCase()} • ${lobby.timer}s", style: const TextStyle(color: AppTheme.accentPink)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GlassContainer(
                      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: lobby.players.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
                        itemBuilder: (ctx, i) {
                          final p = lobby.players[i];
                          bool visualReady = isPlayerReady(p);
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: visualReady ? Colors.green : Colors.grey,
                              child: Icon(visualReady ? Icons.check : Icons.hourglass_empty, color: Colors.white, size: 16),
                            ),
                            title: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            trailing: p.name == lobby.host ? const Icon(Icons.star, color: Colors.amber) : null,
                          );
                        },
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    child: isHost 
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: allReady ? Colors.green : Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 8,
                        ),
                        onPressed: allReady ? () => game.startGame() : null,
                        child: Text(
                          allReady ? "START GAME" : "WAITING FOR READY ($readyCount/${lobby.players.length})", 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: allReady ? Colors.white : Colors.white54)
                        ),
                      )
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: iAmReady ? Colors.redAccent : Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 8,
                        ),
                        icon: Icon(iAmReady ? Icons.close : Icons.check),
                        label: Text(
                          iAmReady ? "NOT READY" : "I'M READY",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                        ),
                        onPressed: () => game.toggleReady(!iAmReady),
                      ),
                  ),
                ],
              ),
            ),
            Align(alignment: Alignment.bottomCenter, child: ChatSheet()),
          ],
        ),
      ),
    );
  }
  
  void _confirmLeave(BuildContext context, GameProvider game) {
    showDialog(
      context: context, 
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.primaryColor,
        title: const Text("Leave Lobby?", style: TextStyle(color: Colors.white)),
        content: Text(game.amIHost ? "This will DELETE the lobby for everyone." : "You will leave the game.", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(child: const Text("Cancel"), onPressed: () => Navigator.pop(context)),
          TextButton(
            child: const Text("Leave", style: TextStyle(color: Colors.red)), 
            onPressed: () { game.leaveLobby(); Navigator.pop(context); }
          ),
        ],
      )
    );
  }

  // --- SETTINGS DIALOG ---
  void _showSettingsDialog(BuildContext context, GameProvider game) {
    String selectedMode = game.lobby!.mode;
    String timerStr = game.lobby!.timer.toString();
    String difficulty = game.lobby!.difficulty ?? "medium";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.primaryColor,
        title: const Text("Lobby Settings", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedMode,
              dropdownColor: const Color(0xFF1E1E2C),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Mode"),
              items: const [
                DropdownMenuItem(value: "general-knowledge", child: Text("General Knowledge")),
                DropdownMenuItem(value: "calculations", child: Text("Math")),
              ],
              onChanged: (v) => selectedMode = v!,
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: timerStr,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Timer (s)"),
              onChanged: (v) => timerStr = v,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: difficulty,
              dropdownColor: const Color(0xFF1E1E2C),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Difficulty"),
              items: const [
                DropdownMenuItem(value: "mixed", child: Text("Mixed")),
                DropdownMenuItem(value: "easy", child: Text("Easy")),
                DropdownMenuItem(value: "medium", child: Text("Medium")),
                DropdownMenuItem(value: "hard", child: Text("Hard")),
              ],
              onChanged: (v) => difficulty = v!,
            ),
          ],
        ),
        actions: [
          TextButton(child: const Text("Cancel"), onPressed: () => Navigator.pop(ctx)),
          ElevatedButton(
            child: const Text("Update"),
            onPressed: () {
              int t = int.tryParse(timerStr) ?? 30;
              game.updateSettings(selectedMode, t, difficulty);
              Navigator.pop(ctx);
            },
          )
        ],
      )
    );
  }
}