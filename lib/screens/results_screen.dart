import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class ResultsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final results = game.lastResults;
    final lobby = game.lobby;

    if (results == null || lobby == null || lobby.quizData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    int totalQs = lobby.quizData!.length;
    int currentIdx = lobby.currentQuestionIndex;
    bool isLast = currentIdx >= (totalQs - 1);

    final correctAnswer = results['correctAnswer']?.toString() ?? "Unknown";
    final List playerResults = results['results'] ?? [];

    return Scaffold(
      body: CyberpunkBackground(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 60),
              const Text("Round Complete!", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 20),
              GlassContainer(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text("The correct answer was:", style: TextStyle(color: Colors.white54)),
                    const SizedBox(height: 8),
                    Text(correctAnswer, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.accentPink), textAlign: TextAlign.center),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text("Player Answers:", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              GlassContainer(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: playerResults.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
                  itemBuilder: (ctx, i) {
                    final p = playerResults[i];
                    final bool isCorrect = p['correct'] == true;
                    final String chosen = p['chosenAnswer']?.toString() ?? "No Answer";
                    final String name = p['name']?.toString() ?? "Unknown";
                    final int score = p['score'] ?? 0;
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: isCorrect ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2), child: Icon(isCorrect ? Icons.check : Icons.close, color: isCorrect ? Colors.green : Colors.red)),
                      title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text("Chose: $chosen", style: TextStyle(color: isCorrect ? Colors.greenAccent : Colors.white54, fontStyle: FontStyle.italic)),
                      trailing: Text("$score pts", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
              if (game.amIHost)
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: isLast ? Colors.redAccent : Colors.green, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                    icon: Icon(isLast ? Icons.flag : Icons.arrow_forward),
                    label: Text(isLast ? "END GAME" : "NEXT QUESTION", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    onPressed: () async { await game.nextQuestion(); },
                  ),
                )
              else
                const Padding(padding: EdgeInsets.only(bottom: 40), child: Text("Waiting for Host...", style: TextStyle(color: Colors.white54))),
            ],
          ),
        ),
      ),
    );
  }
}