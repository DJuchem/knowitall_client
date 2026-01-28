import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class ResultsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final results = game.lastResults; // Ensure this getter exists in Provider

    if (results == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Robust parsing again
    final correct = results['correctAnswer'] ?? "?";
    final List playerResults = results['results'] ?? [];

    return Scaffold(
      body: CyberpunkBackground(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 80),
              const Text("Round Complete!", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 20),

              // Correct Answer
              GlassContainer(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Text("Correct Answer:", style: TextStyle(color: Colors.white54)),
                    const SizedBox(height: 8),
                    Text(correct, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.accentPink), textAlign: TextAlign.center),
                  ],
                ),
              ),

              // Player Scores
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: playerResults.length,
                itemBuilder: (ctx, i) {
                  final p = playerResults[i];
                  final isCorrect = p['correct'] == true;
                  return ListTile(
                    title: Text(p['name'], style: const TextStyle(color: Colors.white)),
                    trailing: Text(isCorrect ? "+100" : "0", style: TextStyle(color: isCorrect ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                    leading: Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: isCorrect ? Colors.green : Colors.red),
                  );
                },
              ),

              const SizedBox(height: 40),

              // HOST BUTTON
              if (game.amIHost)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text("NEXT QUESTION", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    await game.nextQuestion();
                  },
                )
              else
                const Text("Waiting for Host...", style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      ),
    );
  }
}