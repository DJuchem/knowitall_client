import 'package:flutter/material.dart';
import '../models/lobby_data.dart';
import '../services/signalr_service.dart';

enum AppState { welcome, lobby, quiz, results }



class GameProvider extends ChangeNotifier {
  final SignalRService _service = SignalRService();
  
  AppState _appState = AppState.welcome;
  LobbyData? _currentLobby;
  String? _errorMessage;
  String _myName = "Player";
  String _myAvatar = "assets/avatars/avatar1.webp";

  Map<String, dynamic>? _lastResults;
Map<String, dynamic>? get lastResults => _lastResults;


  // Getters
  AppState get appState => _appState;
  LobbyData? get lobby => _currentLobby;
  String? get error => _errorMessage;
  String get myName => _myName;
  bool get amIHost => _currentLobby?.host == _myName;

  Future<void> connect(String url) async {
    // 1. Handle Lobby Updates (Chat, Players joining)
    _service.onLobbyUpdate = (data) {
      if (data != null) {
        final map = data as Map<String, dynamic>;
        _currentLobby = LobbyData.fromJson(map);
        notifyListeners();
      }
    };

    // 2. Handle Creation Success -> Navigate to Lobby
    _service.onGameCreated = (data) {
       final map = data as Map<String, dynamic>;
       _currentLobby = LobbyData.fromJson(map);
       _appState = AppState.lobby; // <--- TRIGGERS NAVIGATION
       notifyListeners();
    };

    // 3. Handle Join Success -> Navigate to Lobby
    _service.onGameJoined = (data) {
       final map = data as Map<String, dynamic>;
       _currentLobby = LobbyData.fromJson(map);
       _appState = AppState.lobby; // <--- TRIGGERS NAVIGATION
       notifyListeners();
    };
    
    // 4. Handle Game Start -> Navigate to Quiz
 _service.onGameStarted = (data) {
      final map = data as Map<String, dynamic>;
      
      if (_currentLobby != null) {
        // A. Inject the Quiz Data into the existing lobby object
        if (map['quizData'] != null) {
           // Reuse the JSON parser logic from LobbyData
           _currentLobby!.quizData = LobbyData.fromJson({'quizData': map['quizData']}).quizData;
        }
        
        // B. Update current index (for Next Question logic)
        if (map['questionIndex'] != null) {
          _currentLobby!.currentQuestionIndex = map['questionIndex'];
        } else if (map['currentQuestionIndex'] != null) {
          _currentLobby!.currentQuestionIndex = map['currentQuestionIndex'];
        }
      }

      _appState = AppState.quiz;
      notifyListeners();
    };
    
    _service.onError = (err) {
      _errorMessage = err.toString();
      notifyListeners();
    };

    _service.onQuestionResults = (data) {
      _lastResults = data as Map<String, dynamic>;
      _appState = AppState.results; // <--- Switch to Results Screen
      notifyListeners();
    };

    await _service.init(url);
  }

  void setPlayerInfo(String name, String avatar) {
    _myName = name;
    _myAvatar = avatar;
  }

  // --- ACTIONS ---

  Future<void> createLobby(String name, String mode, int qCount, String category, String difficulty) async {
    _myName = name;
    // We just send the command. The 'onGameCreated' listener above handles the rest.
    await _service.createGame(name, mode, qCount, category, difficulty);
  }

  Future<void> joinLobby(String code, String name) async {
    _myName = name;
    await _service.joinGame(code, name);
  }

  Future<void> sendChat(String msg) async {
    if (_currentLobby != null) {
      await _service.postChat(_currentLobby!.code, msg);
    }
  }

  Future<void> startGame() async {
    if (_currentLobby != null) {
      await _service.startGame(_currentLobby!.code);
    }
  }

  Future<void> nextQuestion() async {
  if (_currentLobby != null) {
    await _service.nextQuestion(_currentLobby!.code);
  }
}

Future<void> submitAnswer(String answer, double time) async {
    if (_currentLobby != null) {
      // Get current Question Index from lobby data
      // If your LobbyData model doesn't have it yet, default to 0 for testing
      // int qIndex = _currentLobby!.currentQuestionIndex; 
      int qIndex = 0; 
      
      await _service.submitAnswer(_currentLobby!.code, qIndex, answer, time);
    }
  }

}