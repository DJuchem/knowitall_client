import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class QuizScreen extends StatefulWidget {
  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _timeLeft = 30;
  Timer? _timer;
  int _internalIndex = -1;
  String _questionText = "Loading...";
  String? _imageUrl;
  List<String> _answers = [];
  String? _selectedAnswer;
  bool _hasAnswered = false;

@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final game = Provider.of<GameProvider>(context, listen: false);
    if (game.lobby != null) _processLobbyData(game, force: true); 
  });
}

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  void startTimer() {
    _timeLeft = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft > 0) { _timeLeft--; } 
        else {
          timer.cancel();
          if (!_hasAnswered) _submitAnswer("", Provider.of<GameProvider>(context, listen: false));
        }
      });
    });
  }

void _processLobbyData(GameProvider game, {bool force = false}) {
  final lobby = game.lobby;
  // SAFE CHECK
  if (lobby == null || lobby.quizData == null || lobby.quizData!.isEmpty) return;

  if (lobby.currentQuestionIndex != _internalIndex || force) {
    _internalIndex = lobby.currentQuestionIndex;
    _hasAnswered = false;
    _selectedAnswer = null;
    _timeLeft = 30; 
    startTimer();

    // SAFE ACCESS
    final idx = _internalIndex >= lobby.quizData!.length ? 0 : _internalIndex;
    final q = lobby.quizData![idx];

    String txt = q['Question'] ?? q['question'] ?? "Error";
    String? img = q['Image'] ?? q['image'];
    String correct = q['CorrectAnswer'] ?? q['correctAnswer'] ?? "";
    List<dynamic> incorrect = (q['IncorrectAnswers'] ?? q['incorrectAnswers'] ?? []) as List<dynamic>;

    List<String> newAnswers = [correct, ...incorrect.map((e) => e.toString())];
    newAnswers.shuffle();

    Future.delayed(Duration.zero, () {
      if (mounted) {
        setState(() { _questionText = txt; _imageUrl = img; _answers = newAnswers; });
      }
    });
  }
}

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    _processLobbyData(game);

    return Scaffold(
      body: CyberpunkBackground(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                      child: Text("Q: ${_internalIndex + 1}", style: const TextStyle(color: Colors.white)),
                    ),
                    Text("$_timeLeft", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                  ],
                ),
              ),
              const Spacer(),
              GlassContainer(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    if (_imageUrl != null && _imageUrl!.isNotEmpty)
                      Padding(padding: const EdgeInsets.only(bottom: 12.0), child: Image.network(_imageUrl!, height: 150, errorBuilder: (_,__,___) => const SizedBox())),
                    Text(_questionText, style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: _hasAnswered 
                ? const Center(child: Text("Waiting for others...", style: TextStyle(color: Colors.white54, fontSize: 18)))
                : Column(children: _answers.map((ans) => Padding(padding: const EdgeInsets.only(bottom: 12), child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _selectedAnswer == ans ? AppTheme.accentPink : Colors.white10, minimumSize: const Size(double.infinity, 56)), onPressed: () => _submitAnswer(ans, game), child: Text(ans, style: const TextStyle(fontSize: 18, color: Colors.white))))).toList()),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _submitAnswer(String answer, GameProvider game) {
    setState(() { _selectedAnswer = answer; _hasAnswered = true; });
    double timeTaken = (30 - _timeLeft).toDouble();
    if (timeTaken < 0) timeTaken = 0;
    game.submitAnswer(answer, timeTaken, _internalIndex);
  }
}