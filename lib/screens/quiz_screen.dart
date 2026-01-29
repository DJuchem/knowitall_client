import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../providers/game_provider.dart';
import '../widgets/base_scaffold.dart';
import '../theme/app_theme.dart';
import 'results_screen.dart'; 
import 'welcome_screen.dart'; 
import 'game_over_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _timeLeft = 30;
  Timer? _timer;
  Timer? _mediaStopTimer; // NEW: Timer to stop video at end range
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
    
    // Navigation Triggers
    if (game.appState == AppState.results) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ResultsScreen()));
        });
        return;
    }
    if (game.appState == AppState.gameOver) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const GameOverScreen()));
        });
        return;
    }
    if (game.appState == AppState.welcome) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const WelcomeScreen()), (r) => false);
        });
        return;
    }

    _processLobbyData(game);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mediaStopTimer?.cancel();
    _confettiController.dispose();
    _ytController?.close();
    super.dispose();
  }

  // --- MUSIC LOGIC: PARSE "ID|Start-End" ---
  void _initMedia(String? payload, String type, GameProvider game) {
    _mediaStopTimer?.cancel();

    if (!type.contains("music") || payload == null || payload.isEmpty) {
        _ytController?.close();
        _ytController = null;
        if (!game.isMusicPlaying && game.isMusicEnabled) game.initMusic(); 
        return;
    }

    game.stopMusic();

    // 1. Parse Payload: "ID|Start-End" (e.g. "dQw4w9WgXcQ|40-100")
    String videoId = payload;
    int startSec = 0;
    int? endSec;

    if (payload.contains('|')) {
        final parts = payload.split('|');
        videoId = parts[0]; 
        
        if (parts.length > 1) {
            final range = parts[1].split('-');
            if (range.isNotEmpty) startSec = int.tryParse(range[0]) ?? 0;
            if (range.length > 1) endSec = int.tryParse(range[1]);
        }
    }

    // 2. Initialize or Load Video
    if (_ytController != null) {
        // .load() usually takes startAt as INT or DOUBLE depending on version.
        // We use loadVideoById for updates as it's more reliable for time jumps.
        _ytController!.loadVideoById(videoId: videoId, startSeconds: startSec.toDouble());
    } else {
        _ytController = YoutubePlayerController.fromVideoId(
          videoId: videoId,
          autoPlay: true,
          params: YoutubePlayerParams(
           
            showControls: false,
            showFullscreenButton: false,
            loop: false, // Don't loop music clips
            mute: false,
          ),
        );
    }

    // 3. Auto-Stop Logic
    if (endSec != null && endSec > startSec) {
        int durationMs = (endSec - startSec) * 1000;
        debugPrint("MEDIA: Playing for $durationMs ms");
        _mediaStopTimer = Timer(Duration(milliseconds: durationMs), () {
            if (mounted && _ytController != null) {
                _ytController!.pauseVideo();
            }
        });
    }
  }

  void _processLobbyData(GameProvider game, {bool force = false}) {
    final lobby = game.lobby;
    
    if (lobby == null || lobby.quizData == null || lobby.quizData!.isEmpty) {
      if (game.appState == AppState.welcome) return;
      if (mounted && _questionText != "Synchronizing...") {
         setState(() => _questionText = "Synchronizing...");
      }
      return;
    }

    if (lobby.currentQuestionIndex != _internalIndex || force || _questionText == "Synchronizing...") {
      _internalIndex = lobby.currentQuestionIndex;
      _hasAnswered = false;
      _selectedAnswer = null;
      _timeLeft = lobby.timer;
      
      final int idx = (_internalIndex < 0 || _internalIndex >= lobby.quizData!.length) ? 0 : _internalIndex;
      final q = lobby.quizData![idx];

      String txt = q['Question'] ?? q['question'] ?? "No Question Text";
      String? media = q['MediaPayload'] ?? q['mediaPayload'] ?? q['Image'] ?? q['image'];
      String type = q['Type'] ?? q['type'] ?? "general";
      
      List<dynamic> incorrectRaw = (q['IncorrectAnswers'] ?? q['incorrectAnswers'] ?? []) as List<dynamic>;
      List<String> incorrect = incorrectRaw.map((e) => e.toString()).toList();
      List<String> newAnswers = [q['CorrectAnswer'] ?? q['correctAnswer'] ?? "", ...incorrect];
      newAnswers.shuffle();

      if (game.currentStreak >= 3) _confettiController.play();
      
      _initMedia(media, type, game);

      startTimer();
      
      if (mounted) setState(() { _questionText = txt; _mediaUrl = media; _answers = newAnswers; });
    }
  }

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft > 0) _timeLeft--;
        else {
          timer.cancel();
          if (!_hasAnswered) _submitAnswer("", context);
        }
      });
    });
  }

  void _submitAnswer(String answer, BuildContext ctx) {
    if (_hasAnswered) return;
    setState(() { _selectedAnswer = answer; _hasAnswered = true; });
    final game = Provider.of<GameProvider>(ctx, listen: false);
    game.submitAnswer(answer, (game.lobby!.timer - _timeLeft).toDouble(), _internalIndex);
  }

  void _confirmLeave(BuildContext context, GameProvider game) {
    showDialog(
      context: context, 
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text("Leave Game?"),
        content: const Text("You will be removed from the lobby."),
        actions: [
          TextButton(child: const Text("Cancel"), onPressed: () => Navigator.pop(context)),
          TextButton(
            child: const Text("LEAVE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), 
            onPressed: () { 
              game.leaveLobby(); 
              Navigator.pop(context);
            }
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    if (game.lobby == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    int maxTime = game.lobby?.timer ?? 30;
    double progress = maxTime > 0 ? _timeLeft / maxTime : 0;

    if (_questionText == "Synchronizing...") {
       return const BaseScaffold(showSettings: false, body: Center(child: Text("Synchronizing...", style: TextStyle(color: Colors.white))));
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
        title: game.currentStreak > 1 
          ? Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.local_fire_department, color: Colors.orange), Text("${game.currentStreak}", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 24))])
          : null,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.white10,
                    color: progress < 0.3 ? Colors.redAccent : (progress < 0.6 ? Colors.amber : Colors.greenAccent),
                  ),
                ),
                const Spacer(),
                GlassContainer(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      if (_ytController != null) ...[
                          SizedBox(height: 1, width: 1, child: YoutubePlayer(controller: _ytController!)),
                          const Icon(Icons.music_note, size: 80, color: Colors.white),
                          const Text("Listen closely...", style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 20),
                      ] else if (_mediaUrl != null && !_mediaUrl!.contains('|') && _mediaUrl!.startsWith("http")) ...[
                          // Hide Image if it's a Music payload (contains pipe)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_mediaUrl!, fit: BoxFit.contain, errorBuilder: (_,__,___) => const SizedBox())),
                          ),
                      ],
                      Text(_questionText, style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: _answers.map((ans) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedAnswer == ans ? game.themeColor : Colors.white.withValues(alpha: 0.1),
                          minimumSize: const Size(double.infinity, 60),
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
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(confettiController: _confettiController, blastDirectionality: BlastDirectionality.explosive, shouldLoop: false, colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple]),
          ),
        ],
      ),
    );
  }
}