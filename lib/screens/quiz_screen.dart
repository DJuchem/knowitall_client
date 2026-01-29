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
  
  // Internal state to track the specific question currently displayed
  int _internalIndex = -1;
  String _questionText = "Loading...";
  String? _mediaUrl; // Can be an Image path, URL, or Audio link
  List<String> _answers = [];
  
  String? _selectedAnswer;
  bool _hasAnswered = false;

  @override
  void initState() {
    super.initState();
    // Force process the lobby data immediately after the widget builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final game = Provider.of<GameProvider>(context, listen: false);
      if (game.lobby != null) {
        _processLobbyData(game, force: true); 
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- TIMER LOGIC ---
  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          timer.cancel();
          // Auto-submit if time runs out
          if (!_hasAnswered) {
             _submitAnswer("", context);
          }
        }
      });
    });
  }

  // --- DATA PARSING ---
  void _processLobbyData(GameProvider game, {bool force = false}) {
    final lobby = game.lobby;
    // Safety checks
    if (lobby == null || lobby.quizData == null || lobby.quizData!.isEmpty) return;

    // Detect if we moved to a new question OR if we are forcing a reload (first mount)
    if (lobby.currentQuestionIndex != _internalIndex || force) {
      _internalIndex = lobby.currentQuestionIndex;
      _hasAnswered = false;
      _selectedAnswer = null;
      _timeLeft = lobby.timer; // Reset timer to lobby setting
      
      // Safety bounds check
      final int dataIndex = _internalIndex >= lobby.quizData!.length ? 0 : _internalIndex;
      final q = lobby.quizData![dataIndex]; // This is the JSON object from DB/API

      // Parsing Fields (Handles uppercase/lowercase differences in JSON)
      String txt = q['Question'] ?? q['question'] ?? "Error loading question";
      String? img = q['Image'] ?? q['image'];
      String correct = q['CorrectAnswer'] ?? q['correctAnswer'] ?? "";
      List<dynamic> incorrect = (q['IncorrectAnswers'] ?? q['incorrectAnswers'] ?? []) as List<dynamic>;

      _mediaUrl = img;

      // Combine and Shuffle Answers
      List<String> newAnswers = [correct, ...incorrect.map((e) => e.toString())];
      newAnswers.shuffle();

      // Start the round
      startTimer();
      
      // Update UI (delayed to avoid build conflicts)
      Future.delayed(Duration.zero, () {
        if (mounted) {
          setState(() {
            _questionText = txt;
            _answers = newAnswers;
          });
        }
      });
    }
  }

  // --- ACTION: SUBMIT ---
  void _submitAnswer(String answer, BuildContext ctx) {
    if (_hasAnswered) return; // Prevent double submission

    setState(() {
      _selectedAnswer = answer;
      _hasAnswered = true;
    });

    double timeTaken = (Provider.of<GameProvider>(ctx, listen: false).lobby!.timer - _timeLeft).toDouble();
    if (timeTaken < 0) timeTaken = 0;

    // Send to Server
    Provider.of<GameProvider>(ctx, listen: false).submitAnswer(answer, timeTaken, _internalIndex);
  }

  // --- UI BUILDER ---
  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    
    // Check for updates every build
    _processLobbyData(game);

    // Dynamic Background from Theme Engine
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(game.wallpaper), 
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- HEADER (Progress & Timer) ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        "Q: ${_internalIndex + 1} / ${game.lobby?.quizData?.length ?? '?'}", 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                      ),
                    ),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: (game.lobby?.timer ?? 30) > 0 ? _timeLeft / (game.lobby!.timer) : 0, 
                          color: game.themeColor,
                          backgroundColor: Colors.white24,
                        ),
                        Text("$_timeLeft", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // --- MEDIA & QUESTION AREA ---
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1), // Glass Effect
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15)],
                ),
                child: Column(
                  children: [
                    // Media Handling
                    if (_mediaUrl != null && _mediaUrl!.isNotEmpty) ...[
                      if (_mediaUrl!.contains("youtube") || _mediaUrl!.endsWith("mp3"))
                        // Audio/Music Placeholder
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.music_note, size: 60, color: game.themeColor),
                              const SizedBox(height: 8),
                              const Text("Audio Clip", style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        )
                      else
                        // Image Handler (Network or Asset)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _mediaUrl!.startsWith("http")
                                ? Image.network(_mediaUrl!, fit: BoxFit.contain, errorBuilder: (_,__,___) => const SizedBox())
                                : Image.asset(_mediaUrl!, fit: BoxFit.contain, errorBuilder: (_,__,___) => const SizedBox()),
                          ),
                        ),
                    ],
                    
                    // The Question
                    Text(
                      _questionText,
                      style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // --- ANSWER BUTTONS ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: _hasAnswered 
                ? Column(
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 10),
                      Text("Answer locked. Waiting...", style: TextStyle(color: Colors.white.withOpacity(0.7))),
                    ],
                  )
                : Column(
                    children: _answers.map((ans) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedAnswer == ans ? game.themeColor : Colors.white.withOpacity(0.1),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: _selectedAnswer == ans ? game.themeColor : Colors.white24)
                          ),
                          elevation: _selectedAnswer == ans ? 10 : 0,
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
      ),
    );
  }
}