import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../providers/game_provider.dart';
import '../widgets/base_scaffold.dart';
import '../theme/app_theme.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  double _timeLeft = 30.0; 
  Timer? _timer;
  Timer? _mediaStopTimer;
  int _internalIndex = -1;

  String _questionText = "Loading...";
  String? _mediaUrl;
  List<String> _answers = [];
  String? _selectedAnswer;
  bool _hasAnswered = false;

  late ConfettiController _confettiController;
  YoutubePlayerController? _ytController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final game = Provider.of<GameProvider>(context);
    if (game.appState != AppState.quiz) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _processLobbyData(game);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mediaStopTimer?.cancel();
    _confettiController.dispose();
    _ytController?.close();
    super.dispose();
  }

  void _initMedia(String? payload, String type, GameProvider game) {
    _mediaStopTimer?.cancel();

    if (_ytController != null) {
      try { _ytController!.pauseVideo(); } catch (_) {}
    }

    if (!type.toLowerCase().contains("music") || payload == null || payload.trim().isEmpty) {
      if (!game.isMusicPlaying && game.isMusicEnabled) {
        game.initMusic(); 
      }
      return;
    }

    game.stopMusic(); // Stop BG music

    final raw = payload.trim();
    String videoId = raw;
    int startSec = 40;
    int? endSec = 100;

    if (raw.contains('|')) {
      final parts = raw.split('|');
      videoId = parts[0].trim();
      if (parts.length > 1) {
        final rangePart = parts[1].trim();
        if (rangePart.contains('-')) {
          final ab = rangePart.split('-');
          final a = int.tryParse(ab[0].trim());
          final b = (ab.length > 1) ? int.tryParse(ab[1].trim()) : null;
          if (a != null) startSec = a;
          if (b != null) endSec = b;
        } else {
          final s = int.tryParse(rangePart);
          if (s != null) startSec = s;
        }
      }
    }

    if (_ytController == null) {
      _ytController = YoutubePlayerController(
        params: const YoutubePlayerParams(
          showControls: false,
          showFullscreenButton: false,
          loop: false,
          mute: false,
          enableCaption: false,
        ),
      );
    }

    _ytController!.loadVideoById(
      videoId: videoId,
      startSeconds: startSec.toDouble(),
      endSeconds: endSec?.toDouble(),
    );

    final int questionSeconds = game.lobby?.timer ?? 30;
    int stopAfterSeconds = questionSeconds;
    
    if (endSec != null && endSec! > startSec) {
      final segLen = endSec! - startSec;
      stopAfterSeconds = (segLen < questionSeconds) ? segLen : questionSeconds;
    }

    _mediaStopTimer = Timer(Duration(seconds: stopAfterSeconds + 1), () {
      if (!mounted || _ytController == null) return;
      _ytController!.pauseVideo();
    });
  }

  void _processLobbyData(GameProvider game, {bool force = false}) {
    final lobby = game.lobby;
    if (lobby == null || lobby.quizData == null || lobby.quizData!.isEmpty) {
      if (mounted && _questionText != "Synchronizing...") setState(() => _questionText = "Synchronizing...");
      return;
    }

    if (lobby.currentQuestionIndex != _internalIndex || force || _questionText == "Synchronizing...") {
      _internalIndex = lobby.currentQuestionIndex;
      _hasAnswered = false;
      _selectedAnswer = null;
      _timeLeft = lobby.timer.toDouble();

      final int idx = (_internalIndex < 0 || _internalIndex >= lobby.quizData!.length) ? 0 : _internalIndex;
      final q = lobby.quizData![idx];
      final txt = q['Question'] ?? q['question'] ?? "No Question Text";
      final media = q['MediaPayload'] ?? q['mediaPayload'] ?? q['Image'] ?? q['image'];
      final type = q['Type'] ?? q['type'] ?? "general";

      final List<dynamic> incorrectRaw = (q['IncorrectAnswers'] ?? q['incorrectAnswers'] ?? []) as List<dynamic>;
      final incorrect = incorrectRaw.map((e) => e.toString()).toList();
      final newAnswers = <String>[q['CorrectAnswer'] ?? q['correctAnswer'] ?? "", ...incorrect]..shuffle();

      if (game.currentStreak >= 3) _confettiController.play();

      _initMedia(media, type, game);
      startTimer(game); 

      if (mounted) {
        setState(() {
          _questionText = txt;
          _mediaUrl = media?.toString();
          _answers = newAnswers;
        });
      }
    }
  }

  void startTimer(GameProvider game) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft = (_timeLeft - 0.1).clamp(0.0, 999.0);
        } else {
          timer.cancel();
          if (!_hasAnswered) _submitAnswer("", context);
        }
      });
    });
  }

  Future<void> _submitAnswer(String answer, BuildContext ctx) async {
    if (_hasAnswered) return;
    setState(() {
      _selectedAnswer = answer;
      _hasAnswered = true;
    });

    final game = Provider.of<GameProvider>(ctx, listen: false);
    try {
      await game.submitAnswer(answer, (game.lobby!.timer - _timeLeft), _internalIndex);
    } catch (_) {
      debugPrint("Answer submission failed.");
    }
  }

  void _confirmLeave(BuildContext context, GameProvider game) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(game.amIHost ? "End Game?" : "Leave Game?"),
        content: Text(game.amIHost 
            ? "This will end the game for everyone." 
            : "You will leave the game."),
        actions: [
          TextButton(child: const Text("Cancel"), onPressed: () => Navigator.pop(context)),
          TextButton(
            child: Text(game.amIHost ? "END GAME" : "LEAVE", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(context);
              if (game.amIHost) { await game.resetToLobby(); } 
              else { await game.leaveLobby(); }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);
    final lobby = game.lobby;

    if (lobby == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final int maxTime = lobby.timer;
    final double progress = maxTime > 0 ? (_timeLeft / maxTime) : 0.0;
    final int currentQ = _internalIndex + 1;
    final int totalQ = lobby.quizData?.length ?? 10; 

    if (_questionText == "Synchronizing...") {
      return const BaseScaffold(body: Center(child: Text("Synchronizing...")));
    }

    return BaseScaffold(
      showSettings: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
          onPressed: () => _confirmLeave(context, game),
        ),
        title: Column(
          children: [
            Text(game.myName, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.7))),
            Text("Question $currentQ / $totalQ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          ],
        ),
        centerTitle: true,
        actions: [
          if (game.currentStreak > 1)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.orange),
                  Text("${game.currentStreak}", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 20)),
                ],
              ),
            )
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // --- TIMER ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 12,
                          backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                          color: progress < 0.3 ? Colors.redAccent : (progress < 0.6 ? Colors.amber : theme.colorScheme.primary),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text("${_timeLeft.toStringAsFixed(1)}s", style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                
                const Spacer(),

                // --- MEDIA AREA (GLASS) ---
                GlassContainer(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  // 🟢 FIX: Moved constraints to a child Container
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 300, minWidth: double.infinity),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, // Center vertically
                      children: [
                        // 1. MUSIC PLAYER (Youtube)
                        if (_ytController != null) ...[
                          // Invisible player
                          SizedBox(height: 1, width: 1, child: YoutubePlayer(controller: _ytController!)),
                          
                          // ✨ FANCY WAVEFORM VISUALIZER ✨
                          // 🟢 FIX: Wrapped in SizedBox to reserve space and prevent jitter
                          SizedBox(
                            height: 80, 
                            child: Center(
                              child: MusicVisualizer(
                                color: game.themeColor, // TIES TO THEME!
                                barCount: 20, 
                              ),
                            ),
                          ),

                          const Text("Listen closely...", style: TextStyle(color: Colors.white70, letterSpacing: 1.5, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 20),
                        ] 
                        // 2. IMAGE DISPLAY
                        else if (_mediaUrl != null && !_mediaUrl!.contains('|') && _mediaUrl!.startsWith("http")) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _mediaUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const SizedBox(),
                              ),
                            ),
                          ),
                        ],

                        // 3. QUESTION TEXT
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            _questionText,
                            style: TextStyle(fontSize: 22, color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),

                // --- ANSWERS ---
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: _answers.map((ans) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedAnswer == ans ? theme.colorScheme.primary : theme.colorScheme.surface.withOpacity(0.6),
                          foregroundColor: _selectedAnswer == ans ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                          minimumSize: const Size(double.infinity, 60),
                          elevation: _selectedAnswer == ans ? 10 : 0,
                          side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
                        ),
                        onPressed: _hasAnswered ? null : () => _submitAnswer(ans, context),
                        child: Text(ans, style: const TextStyle(fontSize: 18)),
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          
          // --- CONFETTI ---
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary, Colors.white],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ✨ SUPER FANCY MUSIC VISUALIZER COMPONENT
// ---------------------------------------------------------------------------
class MusicVisualizer extends StatefulWidget {
  final Color color;
  final int barCount;

  const MusicVisualizer({
    Key? key,
    required this.color,
    this.barCount = 20,
  }) : super(key: key);

  @override
  _MusicVisualizerState createState() => _MusicVisualizerState();
}

class _MusicVisualizerState extends State<MusicVisualizer> with TickerProviderStateMixin {
  late List<double> values;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    values = List.generate(widget.barCount, (index) => Random().nextDouble());
    // Update the visualizer rapidly to simulate audio frequency changes
    timer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (mounted) {
        setState(() {
          values = List.generate(widget.barCount, (index) => Random().nextDouble());
        });
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(widget.barCount, (index) {
        return VisualizerBar(
            value: values[index],
            color: widget.color,
            maxHeight: 60 // Max height of the waveform
        );
      }),
    );
  }
}

class VisualizerBar extends StatelessWidget {
  final double value;
  final Color color;
  final double maxHeight;

  const VisualizerBar({
    Key? key,
    required this.value,
    required this.color,
    required this.maxHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine height: base height + (random value * variance)
    final double height = 10.0 + (value * maxHeight); 
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutQuad,
        width: 8,
        height: height,
        decoration: BoxDecoration(
          color: color.withOpacity(0.8),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 1,
            )
          ],
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              color.withOpacity(0.4),
              color,
            ],
          ),
        ),
      ),
    );
  }
}