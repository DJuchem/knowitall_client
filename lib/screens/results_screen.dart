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
    // Prevent initial transparency flash (esp. Flutter Web)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _in = true);
    });
  }

  // ─────────────────────────────────────────────
  // Helpers to extract music info safely
  // ─────────────────────────────────────────────
  String _readAny(Map? q, List<String> keys) {
    if (q == null) return "";
    for (final k in keys) {
      final v = q[k];
      if (v != null) {
        final s = v.toString().trim();
        if (s.isNotEmpty) return s;
      }
    }
    return "";
  }

  String _buildTrackLine(Map? q) {
    final artist = _readAny(q, const [
      "Artist",
      "artist",
      "Performer",
      "performer"
    ]);

    final title = _readAny(q, const [
      "Title",
      "title",
      "Track",
      "track",
      "Song",
      "song"
    ]);

    final year = _readAny(q, const [
      "Year",
      "year",
      "ReleaseYear",
      "releaseYear"
    ]);

    if (artist.isNotEmpty || title.isNotEmpty || year.isNotEmpty) {
      final main = [artist, title].where((e) => e.isNotEmpty).join(" — ");
      return year.isNotEmpty ? "$main ($year)" : main;
    }

    // Fallback: combined TrackInfo
    final trackInfo = _readAny(q, const ["TrackInfo", "trackInfo"]);
    if (trackInfo.isEmpty) return "";

    // Handle "Artist|Title|Year"
    final parts = trackInfo.split("|").map((s) => s.trim()).toList();
    if (parts.length >= 2) {
      final a = parts[0];
      final t = parts[1];
      final y = parts.length >= 3 ? parts[2] : "";
      return y.isNotEmpty ? "$a — $t ($y)" : "$a — $t";
    }

    return trackInfo;
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final lobby = game.lobby;
    final results = game.lastResults;
    final theme = Theme.of(context);

    if (lobby == null || results == null) {
      return const BaseScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final quizData = lobby.quizData;
    final qIdx = lobby.currentQuestionIndex;

    final currentQ =
        (quizData != null && qIdx >= 0 && qIdx < quizData.length)
            ? quizData[qIdx]
            : null;

    final String type =
        (currentQ?['Type'] ?? currentQ?['type'] ?? '').toString().toLowerCase();

    final String trackLine = _buildTrackLine(currentQ);

    final String correctAnswer =
        results['correctAnswer']?.toString() ?? "Unknown";

    final List playerResults = (results['results'] ?? []) as List;

    playerResults.sort(
      (a, b) => (b['score'] as int).compareTo(a['score'] as int),
    );

    final totalQs = lobby.quizData?.length ?? 0;
    final isLast =
        totalQs > 0 ? lobby.currentQuestionIndex >= totalQs - 1 : false;

    return BaseScaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Column(
              children: [
                const SizedBox(height: 12),

                // ───────── HEADER ─────────
                AnimatedSlide(
                  offset: _in ? Offset.zero : const Offset(0, -0.04),
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  child: AnimatedScale(
                    scale: _in ? 1 : 0.98,
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      "ROUND COMPLETE",
                      style: theme.textTheme.titleLarge?.copyWith(
                        letterSpacing: 2,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ───────── ANSWER CARD ─────────
                AnimatedSlide(
                  offset: _in ? Offset.zero : const Offset(0, 0.04),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: GlassContainer(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        const Text(
                          "The correct answer was:",
                          style: TextStyle(color: Colors.white54),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          correctAnswer,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.amber,
                          ),
                        ),

                        // 🎵 FULL MUSIC INFO
                        if (type == 'music' && trackLine.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            trackLine,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white70,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Leaderboard",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // ───────── LEADERBOARD ─────────
                Expanded(
                  child: GlassContainer(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: playerResults.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Colors.white10),
                      itemBuilder: (ctx, i) {
                        final p = playerResults[i];
                        final bool isCorrect = p['correct'] == true;
                        final String name = p['name'] ?? "Unknown";
                        final String chosen =
                            p['chosenAnswer']?.toString() ?? "No Answer";
                        final int score = p['score'] ?? 0;
                        final int earned = p['earned'] ?? 0;

                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: _in ? 1 : 0, end: 1),
                          duration:
                              Duration(milliseconds: 140 + (i * 35)),
                          curve: Curves.easeOut,
                          builder: (_, t, child) {
                            return Transform.translate(
                              offset: Offset(0, (1 - t) * 12),
                              child: child,
                            );
                          },
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: (isCorrect
                                      ? Colors.green
                                      : Colors.red)
                                  .withOpacity(0.25),
                              child: Icon(
                                isCorrect ? Icons.check : Icons.close,
                                color: isCorrect
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                              ),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "Chose: $chosen ${isCorrect ? '(+$earned)' : ''}",
                              style: TextStyle(
                                color: isCorrect
                                    ? Colors.greenAccent
                                    : Colors.white54,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            trailing: Text(
                              "$score",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ───────── ACTION BUTTON ─────────
                if (game.amIHost)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isLast ? Colors.redAccent : Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: Icon(
                        isLast ? Icons.flag : Icons.arrow_forward,
                        color: Colors.white,
                      ),
                      label: Text(
                        isLast ? "FINISH GAME" : "NEXT QUESTION",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => game.nextQuestion(),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      "Waiting for host…",
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
