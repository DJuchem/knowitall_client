import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../providers/game_provider.dart';
import '../widgets/base_scaffold.dart';
import '../theme/app_theme.dart'; // For GlassContainer


class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _timeLeft = 30;
  Timer? _timer;
  int _internalIndex = -1;
  String _questionText = "Loading...";
  String? _mediaUrl;
  List<String> _answers = [];
  String? _selectedAnswer;
  bool _hasAnswered = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final game = Provider.of<GameProvider>(context, listen: false);
      if (game.lobby != null) _processLobbyData(game, force: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _processLobbyData(GameProvider game, {bool force = false}) {
    final lobby = game.lobby;
    if (lobby == null || lobby.quizData == null || lobby.quizData!.isEmpty) return;

    if (lobby.currentQuestionIndex != _internalIndex || force) {
      _internalIndex = lobby.currentQuestionIndex;
      _hasAnswered = false;
      _selectedAnswer = null;
      _timeLeft = lobby.timer;
      
      final int idx = _internalIndex >= lobby.quizData!.length ? 0 : _internalIndex;
      final q = lobby.quizData![idx];

      String txt = q['Question'] ?? q['question'] ?? "Error";
      String? img = q['Image'] ?? q['image'];
      String correct = q['CorrectAnswer'] ?? q['correctAnswer'] ?? "";
      List<dynamic> incorrect = (q['IncorrectAnswers'] ?? q['incorrectAnswers'] ?? []) as List<dynamic>;

      List<String> newAnswers = [correct, ...incorrect.map((e) => e.toString())];
      newAnswers.shuffle();

      if (game.currentStreak >= 3) {
        _confettiController.play();
      }

      startTimer();
      
      Future.delayed(Duration.zero, () {
        if (mounted) {
          setState(() {
            _questionText = txt;
            _mediaUrl = img;
            _answers = newAnswers;
          });
        }
      });
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

  void _submitAnswer(String answer, BuildContext ctx) {
    if (_hasAnswered) return;
    setState(() { _selectedAnswer = answer; _hasAnswered = true; });
    
    final game = Provider.of<GameProvider>(ctx, listen: false);
    double timeTaken = (game.lobby!.timer - _timeLeft).toDouble();
    if (timeTaken < 0) timeTaken = 0;
    
    game.submitAnswer(answer, timeTaken, _internalIndex);
  }

  void _confirmLeave(BuildContext context, GameProvider game) {
    showDialog(
      context: context, 
      builder: (_) => AlertDialog(
        // FIX: Dynamic Surface Color
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text("Leave Game?", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text("You will be removed from the lobby.", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
        actions: [
          TextButton(child: const Text("Cancel"), onPressed: () => Navigator.pop(context)),
          TextButton(
            child: const Text("LEAVE", style: TextStyle(color: Colors.red)), 
            onPressed: () { 
              Navigator.pop(context); 
              game.leaveLobby(); 
            }
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    _processLobbyData(game);
    
    double totalTime = (game.lobby?.timer ?? 30).toDouble();
    double progress = totalTime > 0 ? _timeLeft / totalTime : 0;

    return BaseScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
          onPressed: () => _confirmLeave(context, game),
        ),
        title: game.currentStreak > 1 
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange),
                const SizedBox(width: 5),
                Text("${game.currentStreak}", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 24))
              ],
            )
          : null,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // TIMER BAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 12,
                          backgroundColor: Colors.white10,
                          color: progress < 0.3 ? Colors.redAccent : (progress < 0.6 ? Colors.amber : Colors.greenAccent),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text("$_timeLeft s", style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))
                    ],
                  ),
                ),

                const Spacer(),

                // QUESTION & MEDIA
                GlassContainer(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      if (_mediaUrl != null && _mediaUrl!.isNotEmpty) ...[
                        if (_mediaUrl!.contains("youtube") || _mediaUrl!.endsWith("mp3"))
                          Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.music_note, size: 50, color: game.themeColor),
                                const SizedBox(height: 8),
                                const Text("Audio Clip", style: TextStyle(color: Colors.white70)),
                              ],
                            ),
                          )
                        else
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              // Handle Network vs Asset
                              child: _mediaUrl!.startsWith("http")
                                  ? Image.network(_mediaUrl!, fit: BoxFit.contain, errorBuilder: (_,__,___) => const SizedBox())
                                  : Image.asset(_mediaUrl!, fit: BoxFit.contain, errorBuilder: (_,__,___) => const SizedBox()),
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

                // ANSWER BUTTONS
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _hasAnswered 
                  ? const Center(child: Text("Answer Locked. Waiting...", style: TextStyle(color: Colors.white54, fontSize: 18)))
                  : Column(
                      children: _answers.map((ans) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            // FIX: withValues
                            backgroundColor: _selectedAnswer == ans ? game.themeColor : Colors.white.withValues(alpha: 0.1),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 60),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: _selectedAnswer == ans ? game.themeColor : Colors.white24, width: 1.5)
                            ),
                            elevation: _selectedAnswer == ans ? 8 : 0,
                          ),
                          onPressed: () => _submitAnswer(ans, context),
                          child: Text(ans, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        ),
                      )).toList(),
                    ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),

          // CONFETTI
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