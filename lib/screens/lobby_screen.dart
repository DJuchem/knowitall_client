import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for Clipboard
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class LobbyScreen extends StatelessWidget {
  final TextEditingController _chatCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final lobby = game.lobby;

    if (lobby == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Disconnect if they leave lobby
            // game.disconnect(); // Implement if needed
            Navigator.pop(context);
          },
        ),
      ),
      body: CyberpunkBackground(
        child: Column(
          children: [
            const SizedBox(height: 80), 
            
            // --- 1. BIG LOBBY CODE DISPLAY ---
            Column(
              children: [
                const Text("LOBBY CODE", style: TextStyle(color: Colors.white54, letterSpacing: 2, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: lobby.code));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Code copied!")));
                  },
                  child: GlassContainer(
                    margin: const EdgeInsets.symmetric(horizontal: 60),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          lobby.code,
                          style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: AppTheme.accentPink, letterSpacing: 4),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.copy, color: Colors.white30, size: 20)
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // --- Player List ---
            Expanded(
              flex: 2,
              child: GlassContainer(
                margin: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Players", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("${lobby.players.length} Joined", style: const TextStyle(color: Colors.greenAccent)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: lobby.players.length,
                        itemBuilder: (ctx, i) {
                          final p = lobby.players[i];
                          final String initial = p.name.isNotEmpty ? p.name[0].toUpperCase() : "?";
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.accentPink,
                                child: Text(initial, style: const TextStyle(color: Colors.white)),
                              ),
                              title: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text("${p.score} pts", style: const TextStyle(color: Colors.white70)),
                              trailing: Icon(Icons.circle, size: 12, color: p.isOnline ? Colors.greenAccent : Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- Game Controls (Host Only) ---
            if (game.amIHost)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("START GAME"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, 
                    minimumSize: const Size(double.infinity, 50)
                  ),
                  onPressed: () async {
                     await game.startGame(); 
                  },
                ),
              ),
            
            // --- Chat Area (Simplified) ---
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}