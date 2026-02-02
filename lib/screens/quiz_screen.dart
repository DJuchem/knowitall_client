import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../providers/game_provider.dart';
import '../widgets/base_scaffold.dart';
import '../theme/app_theme.dart';

import 'dart:math';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _timeLeft = 30;
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

  void _initMedia(String? payload, String type, GameProvider game) {
    _mediaStopTimer?.cancel();
    if (!type.toLowerCase().contains("music") || payload == null || payload.trim().isEmpty) {
      _ytController?.close();
      _ytController = null;
      if (!game.isMusicPlaying && game.isMusicEnabled) game.initMusic();
      return;
    }
    game.stopMusic();

    final raw = payload.trim();
    String videoId = raw;
    int startSec = 0;
    int? endSec;

    if (raw.contains('|')) {
      final parts = raw.split('|');
      videoId = parts[0].trim();
      if (parts.length > 1) {
        final rangePart = parts[1].trim();
        if (rangePart.contains('-')) {
          final ab = rangePart.split('-');
          final a = int.tryParse(ab[0].trim());
          final b = (ab.length > 1) ? int.tryParse(ab[1].trim()) : null;
          if (a != null && b != null) {
            if (b > a && (b - a) <= 30) {
              startSec = a;
              endSec = b;
            } else {
              final minS = a < b ? a : b;
              final maxS = a < b ? b : a;
              startSec = Random().nextInt((maxS - minS) + 1) + minS;
              endSec = null;
            }
          } else if (a != null) startSec = a;
        } else {
          final s = int.tryParse(rangePart);
          if (s != null) startSec = s;
        }
      }
    }

    if (_ytController != null) {
      _ytController!.loadVideoById(videoId: videoId, startSeconds: startSec.toDouble());
      _ytController!.playVideo();
    } else {
      _ytController = YoutubePlayerController(
        params: const YoutubePlayerParams(
          showControls: false,
          showFullscreenButton: false,
          loop: false,
          mute: false,
        ),
      );
      _ytController!.loadVideoById(videoId: videoId, startSeconds: startSec.toDouble());
      _ytController!.playVideo();
    }

    final int questionSeconds = game.lobby?.timer ?? 30;
    int stopAfterSeconds = questionSeconds;
    if (endSec != null && endSec > startSec) {
      final segLen = endSec - startSec;
      stopAfterSeconds = (segLen < questionSeconds) ? questionSeconds : segLen;
    }
    _mediaStopTimer = Timer(Duration(seconds: stopAfterSeconds), () {
      if (!mounted || _ytController == null) return;
      _ytController!.pauseVideo();
    });
  }

  void _processLobbyData(GameProvider game, {bool force = false}) {
    final lobby = game.lobby;
    if (lobby == null || lobby.quizData == null || lobby.quizData!.isEmpty) {
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
      final txt = q['Question'] ?? q['question'] ?? "No Question Text";
      final media = q['MediaPayload'] ?? q['mediaPayload'] ?? q['Image'] ?? q['image'];
      final type = q['Type'] ?? q['type'] ?? "general";

      final List<dynamic> incorrectRaw = (q['IncorrectAnswers'] ?? q['incorrectAnswers'] ?? []) as List<dynamic>;
      final incorrect = incorrectRaw.map((e) => e.toString()).toList();
      final newAnswers = <String>[q['CorrectAnswer'] ?? q['correctAnswer'] ?? "", ...incorrect]..shuffle();

      if (game.currentStreak >= 3) _confettiController.play();

      _initMedia(media, type, game);
      startTimer();

      if (mounted) {
        setState(() {
          _questionText = txt;
          _mediaUrl = media?.toString();
          _answers = newAnswers;
        });
      }
    }
  }

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
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
      await game.submitAnswer(answer, (game.lobby!.timer - _timeLeft).toDouble(), _internalIndex);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit: $e"), backgroundColor: Colors.red),
      );
    }
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
              Navigator.pop(context);
              game.leaveLobby();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final lobby = game.lobby;

    if (lobby == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final int maxTime = lobby.timer;
    final double progress = maxTime > 0 ? (_timeLeft / maxTime).toDouble() : 0.0;
    
    // ✅ NEW INFO LOGIC
    final int currentQ = _internalIndex + 1;
    final int totalQ = lobby.quizData?.length ?? 10; 

    if (_questionText == "Synchronizing...") {
      return const BaseScaffold(
        showSettings: false,
        body: Center(child: Text("Synchronizing...", style: TextStyle(color: Colors.white))),
      );
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
        // ✅ ADDED: Player Name + Question Count in AppBar
        title: Column(
          children: [
            Text(game.myName, style: const TextStyle(fontSize: 14, color: Colors.white70)),
            Text("Question $currentQ / $totalQ", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                      Text(
                        _questionText,
                        style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
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
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }
}