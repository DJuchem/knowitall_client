import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/base_scaffold.dart';
import '../theme/app_theme.dart';
import '../widgets/game_avatar.dart';
import '../models/lobby_data.dart';

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
    final theme = Theme.of(context);

    if (lobby == null || results == null) return const BaseScaffold(body: Center(child: CircularProgressIndicator()));

    final correctAnswer = results['correctAnswer']?.toString() ?? "Unknown";
    final List playerResults = (results['results'] ?? []) as List;
    playerResults.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    final totalQs = lobby.quizData?.length ?? 0;
    final isLast = totalQs > 0 ? lobby.currentQuestionIndex >= totalQs - 1 : false;

    // 🟢 DYNAMIC SCALING LOGIC
    final int count = playerResults.length;
    
    // Define Breakpoints
    final bool isLarge  = count <= 4;
    final bool isMedium = count > 4 && count <= 8;
    // else isCompact (9+)

    // Set Sizes based on Breakpoints
    final double nameSize      = isLarge ? 26 : (isMedium ? 22 : 16);
    final double scoreSize     = isLarge ? 30 : (isMedium ? 26 : 18);
    final double subSize       = isLarge ? 16 : (isMedium ? 14 : 12);
    final double avatarRadius  = isLarge ? 32 : (isMedium ? 26 : 20);
    final double badgeSize     = isLarge ? 24 : (isMedium ? 20 : 16);
    final double tilePadding   = isLarge ? 16 : (isMedium ? 10 : 6);

    return BaseScaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Column(
              children: [
                const SizedBox(height: 12),
                
                // Title Animation
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
                
                // Correct Answer Box
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
                
                // Leaderboard List
                Expanded(
                  child: GlassContainer(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: count,
                      separatorBuilder: (_, __) => Divider(height: 1, color: theme.colorScheme.onSurface.withOpacity(0.1)),
                      itemBuilder: (ctx, i) {
                        final p = playerResults[i];
                        final bool isCorrect = p['correct'] == true;
                        final String name = p['name'] ?? "Unknown";
                        final String chosen = p['chosenAnswer']?.toString() ?? "No Answer";
                        final int score = p['score'] ?? 0;
                        final int earned = p['earned'] ?? 0;
                        final double timeTaken = (p['time'] is num) ? (p['time'] as num).toDouble() : 0.0;

                        // Find Avatar
                        String avatarPath = "assets/avatars/avatar_0.png";
                        try {
                          final playerObj = lobby.players.firstWhere((pl) => pl.name == name);
                          avatarPath = playerObj.avatar ?? "assets/avatars/avatar_0.png";
                        } catch (_) {}

                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: tilePadding), // 🟢 Dynamic Padding
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            
                            // Avatar + Badge
                            leading: SizedBox(
                              width: avatarRadius * 2,
                              height: avatarRadius * 2,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  GameAvatar(path: avatarPath, radius: avatarRadius),
                                  Positioned(
                                    bottom: -2,
                                    right: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: theme.scaffoldBackgroundColor, 
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isCorrect ? Icons.check_circle : Icons.cancel,
                                        color: isCorrect ? Colors.greenAccent : Colors.redAccent,
                                        size: badgeSize, // 🟢 Dynamic Badge Size
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Name
                            title: Text(
                              name, 
                              style: TextStyle(
                                color: theme.colorScheme.onSurface, 
                                fontWeight: FontWeight.bold, 
                                fontSize: nameSize // 🟢 Dynamic Font Size
                              )
                            ),
                            
                            // Subtitle (Answer & Time)
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "Chose: $chosen ${isCorrect ? '(+$earned)' : ''}  •  ${timeTaken.toStringAsFixed(1)}s", 
                                style: TextStyle(
                                  fontSize: subSize, // 🟢 Dynamic Font Size
                                  color: isCorrect ? Colors.green : theme.colorScheme.onSurface.withOpacity(0.5), 
                                  fontStyle: FontStyle.italic
                                ),
                              ),
                            ),
                            
                            // Score
                            trailing: Text(
                              "$score", 
                              style: TextStyle(
                                color: theme.colorScheme.onSurface, 
                                fontWeight: FontWeight.w900, 
                                fontSize: scoreSize // 🟢 Dynamic Font Size
                              )
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Next/Finish Button
                if (game.amIHost)
                  SizedBox(
                    width: double.infinity,
                    height: 60, 
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLast ? Colors.redAccent : theme.colorScheme.primary, 
                        foregroundColor: isLast ? Colors.white : theme.colorScheme.onPrimary,
                        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1),
                        iconSize: 28,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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