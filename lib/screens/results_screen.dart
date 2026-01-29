import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/base_scaffold.dart';
import '../widgets/game_avatar.dart'; // Ensure you have this file from previous steps

class ResultsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final results = game.lastResults;
    final lobby = game.lobby;

    if (results == null || lobby == null) return const BaseScaffold(body: Center(child: CircularProgressIndicator()));

    final correctAnswer = results['correctAnswer']?.toString() ?? "Unknown";
    final List playerResults = results['results'] ?? [];
    
    // Sort so winner is first if you want, or keep server order
    playerResults.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    return BaseScaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text("ROUND COMPLETE", style: Theme.of(context).textTheme.titleLarge?.copyWith(letterSpacing: 2)),
            const SizedBox(height: 20),

            // Correct Answer Card
            GlassContainer(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              child: Column(
                children: [
                  const Text("The answer was:", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 10),
                  Text(correctAnswer, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary), textAlign: TextAlign.center),
                ],
              ),
            ),

            const SizedBox(height: 20),
            
            // Leaderboard List
            GlassContainer(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(10),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: playerResults.length,
                separatorBuilder: (_,__) => const Divider(),
                itemBuilder: (ctx, i) {
                  final p = playerResults[i];
                  final bool isCorrect = p['correct'] == true;
                  final double timeTaken = (p['time_spent'] ?? 0).toDouble(); // Assuming server sends this now? Or calculate locally?
                  // If server doesn't send time_spent in results array, you might need to adjust server logic
                  // For now, let's assume 'earned' points implies speed. 
                  final int earned = p['earned'] ?? 0;

                  return ListTile(
                    leading: GameAvatar(path: "assets/avatars/avatar1.webp", radius: 20), // Replace with real lookup if available
                    title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: isCorrect 
                      ? Text("Correct (+${earned}pts)", style: const TextStyle(color: Colors.green))
                      : const Text("Wrong", style: TextStyle(color: Colors.red)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("${p['score']} PTS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary)),
                        // #8 TIME DISPLAY (Requires server update to send 'time_spent' in results list, otherwise hide)
                        // Text("${timeTaken.toStringAsFixed(1)}s", style: const TextStyle(fontSize: 10, color: Colors.grey)), 
                      ],
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Host Controls
            if (game.amIHost)
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                  ),
                  onPressed: () => game.nextQuestion(),
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  label: const Text("NEXT QUESTION", style: TextStyle(fontSize: 20, color: Colors.white)),
                ),
              )
            else
              const Text("Waiting for Host...", style: TextStyle(color: Colors.grey)),
              
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}