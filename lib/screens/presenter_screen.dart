import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/base_scaffold.dart';
import '../theme/app_theme.dart';

class PresenterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final lobby = game.lobby;

    if (lobby == null) return const BaseScaffold(body: Center(child: Text("Waiting for Game...", style: TextStyle(color: Colors.white))));

    // Determine State
    String mainText = "";
    String subText = "";
    
    if (!lobby.started) {
      mainText = "JOIN NOW";
      subText = "Code: ${lobby.code}";
    } else if (game.appState == AppState.results) {
      mainText = "ROUND OVER";
      subText = "Check the Leaderboard";
    } else {
      // Quiz Mode
      final q = lobby.quizData![lobby.currentQuestionIndex];
      mainText = q['Question'] ?? "";
      subText = "Time Remaining";
    }

    return BaseScaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // BIG CODE DISPLAY
            Text("LOBBY: ${lobby.code}", style: const TextStyle(fontSize: 30, color: Colors.white54, letterSpacing: 5)),
            const SizedBox(height: 40),
            
            // BIG CONTENT
            GlassContainer(
              padding: const EdgeInsets.all(40),
              margin: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Text(mainText, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  Text(subText, style: TextStyle(fontSize: 32, color: AppTheme.accentPink)),
                ],
              ),
            ),

            // STATS
            if (lobby.started)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _statCard("Players", "${lobby.players.length}"),
                  const SizedBox(width: 20),
                  _statCard("Question", "${lobby.currentQuestionIndex + 1} / ${lobby.quizData?.length ?? '?'}"),
                ],
              )
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label, style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}