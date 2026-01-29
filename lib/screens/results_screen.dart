import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/base_scaffold.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final results = game.lastResults;
    final lobby = game.lobby;
    final theme = Theme.of(context);

    if (results == null || lobby == null) {
      return const BaseScaffold(body: Center(child: CircularProgressIndicator()));
    }

    final totalQs = lobby.quizData?.length ?? 0;
    final currentIdx = lobby.currentQuestionIndex;
    final isLast = totalQs > 0 ? currentIdx >= (totalQs - 1) : false;

    final correctAnswer = results['correctAnswer']?.toString() ?? "Unknown";
    final List playerResults = (results['results'] ?? []) as List;

    playerResults.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    return BaseScaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Text("ROUND COMPLETE", style: theme.textTheme.titleLarge?.copyWith(letterSpacing: 2, color: Colors.white)),
            const SizedBox(height: 20),

            GlassContainer(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text("The correct answer was:", style: TextStyle(color: Colors.white54)),
                  const SizedBox(height: 8),
                  Text(
                    correctAnswer,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text("Leaderboard:", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
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
                  final int earned = p['earned'] ?? 0;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCorrect ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                      child: Icon(isCorrect ? Icons.check : Icons.close, color: isCorrect ? Colors.green : Colors.red),
                    ),
                    title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      "Chose: $chosen ${isCorrect ? '(+$earned)' : ''}",
                      style: TextStyle(color: isCorrect ? Colors.greenAccent : Colors.white54, fontStyle: FontStyle.italic),
                    ),
                    trailing: Text("$score", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  );
                },
              ),
            ),

            const SizedBox(height: 40),

            if (game.amIHost)
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLast ? Colors.redAccent : Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      icon: Icon(isLast ? Icons.flag : Icons.arrow_forward, color: Colors.white),
                      label: Text(
                        isLast ? "FINISH GAME" : "NEXT QUESTION",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      onPressed: () async {
                        await game.nextQuestion();
                        // server drives appState -> root switches screen
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    icon: const Icon(Icons.settings, color: Colors.white54),
                    label: const Text("Abort to Lobby", style: TextStyle(color: Colors.white54)),
                    onPressed: () => game.resetToLobby(),
                  )
                ],
              )
            else
              Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Text("Waiting for Host...", style: TextStyle(color: Colors.white54)),
                  ),
                  TextButton(
                    onPressed: () => _confirmLeave(context, game),
                    child: const Text("Leave Game", style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _confirmLeave(BuildContext context, GameProvider game) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text("Leave Game?"),
        content: const Text("You will be returned to the main menu."),
        actions: [
          TextButton(child: const Text("Cancel"), onPressed: () => Navigator.pop(context)),
          TextButton(
            child: const Text("LEAVE", style: TextStyle(color: Colors.red)),
            onPressed: () {
              game.leaveLobby();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
