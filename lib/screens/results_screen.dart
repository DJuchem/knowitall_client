import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/base_scaffold.dart';
import '../theme/app_theme.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _in = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _in = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final lobby = game.lobby;
    final results = game.lastResults;
    final theme = Theme.of(context); // ✅ Active Theme

    if (lobby == null || results == null) return const BaseScaffold(body: Center(child: CircularProgressIndicator()));

    final correctAnswer = results['correctAnswer']?.toString() ?? "Unknown";
    final List playerResults = (results['results'] ?? []) as List;

    playerResults.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    final totalQs = lobby.quizData?.length ?? 0;
    final isLast = totalQs > 0 ? lobby.currentQuestionIndex >= totalQs - 1 : false;

    return BaseScaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Column(
              children: [
                const SizedBox(height: 12),
                AnimatedSlide(
                  offset: _in ? Offset.zero : const Offset(0, -0.04),
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  child: Text(
                    "ROUND COMPLETE", 
                    style: theme.textTheme.titleLarge?.copyWith(letterSpacing: 2, fontWeight: FontWeight.w800)
                  ),
                ),
                const SizedBox(height: 12),
                GlassContainer(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Text("The correct answer was:", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
                        const SizedBox(height: 8),
                        Text(correctAnswer, textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                Text("Leaderboard", style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: GlassContainer(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: playerResults.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: theme.colorScheme.onSurface.withOpacity(0.1)),
                      itemBuilder: (ctx, i) {
                        final p = playerResults[i];
                        final bool isCorrect = p['correct'] == true;
                        final String name = p['name'] ?? "Unknown";
                        final String chosen = p['chosenAnswer']?.toString() ?? "No Answer";
                        final int score = p['score'] ?? 0;
                        final int earned = p['earned'] ?? 0;
                        final double timeTaken = (p['time'] is num) ? (p['time'] as num).toDouble() : 0.0;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: (isCorrect ? Colors.green : Colors.red).withOpacity(0.25),
                            child: Icon(isCorrect ? Icons.check : Icons.close, color: isCorrect ? Colors.greenAccent : Colors.redAccent),
                          ),
                          title: Text(name, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            // ✅ Fixed time format
                            "Chose: $chosen ${isCorrect ? '(+$earned)' : ''}  •  ${timeTaken.toStringAsFixed(1)}s", 
                            style: TextStyle(color: isCorrect ? Colors.green : theme.colorScheme.onSurface.withOpacity(0.5), fontStyle: FontStyle.italic),
                          ),
                          trailing: Text("$score", style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w900, fontSize: 18)),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (game.amIHost)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLast ? Colors.redAccent : theme.colorScheme.primary, 
                        foregroundColor: isLast ? Colors.white : theme.colorScheme.onPrimary
                      ),
                      icon: Icon(isLast ? Icons.flag : Icons.arrow_forward),
                      label: Text(isLast ? "FINISH GAME" : "NEXT QUESTION"),
                      onPressed: () => game.nextQuestion(),
                    ),
                  )
                else
                  Padding(padding: const EdgeInsets.only(top: 6), child: Text("Waiting for host…", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}