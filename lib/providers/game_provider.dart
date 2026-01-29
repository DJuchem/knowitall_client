import 'package:flutter/material.dart';
import '../models/lobby_data.dart';
import '../services/signalr_service.dart';

enum AppState { welcome, lobby, quiz, results, gameOver }

class GameProvider extends ChangeNotifier {
  final SignalRService _service = SignalRService();
  
  AppState _appState = AppState.welcome;
  LobbyData? _currentLobby;
  Map<String, dynamic>? _lastResults;
  String? _errorMessage;
  
  String _myName = "Player";
  String _myAvatar = "assets/avatars/avatar1.webp";

  AppState get appState => _appState;
  LobbyData? get lobby => _currentLobby;
  Map<String, dynamic>? get lastResults => _lastResults;
  String? get error => _errorMessage;
  String get myName => _myName;
  String get myAvatar => _myAvatar;
  
  bool get amIHost => _currentLobby != null && _currentLobby!.host.trim().toLowerCase() == _myName.trim().toLowerCase();

  Future<void> connect(String url) async {
    await _service.init(url);

    _service.onLobbyUpdate = (data) {
      if (data != null) {
        final map = data as Map<String, dynamic>;
        _currentLobby = LobbyData.fromJson(map);
        notifyListeners();
      }
    };

    _service.onGameCreated = (data) { _handleLobbyData(data); _appState = AppState.lobby; notifyListeners(); };
    _service.onGameJoined = (data) { _handleLobbyData(data); _appState = AppState.lobby; notifyListeners(); };
    
    _service.onGameStarted = (data) {
      final map = data as Map<String, dynamic>;
      if (_currentLobby != null) {
        if (map['quizData'] != null) {
           final temp = LobbyData.fromJson({'quizData': map['quizData'], 'players': [], 'spectators': [], 'chat': [], 'code': '', 'host': '', 'mode': '', 'started': true, 'timer': 0, 'questionIndex': 0, 'difficulty': ''});
           _currentLobby!.quizData = temp.quizData;
        }
        _currentLobby!.currentQuestionIndex = map['questionIndex'] ?? 0;
      }
      _appState = AppState.quiz;
      notifyListeners();
    };

    _service.onNewRound = (data) {
       final map = data as Map<String, dynamic>;
       if (_currentLobby != null) {
          _currentLobby!.currentQuestionIndex = map['questionIndex'] ?? 0;
       }
       _appState = AppState.quiz; 
       notifyListeners();
    };

    _service.onQuestionResults = (data) { _lastResults = data as Map<String, dynamic>; _appState = AppState.results; notifyListeners(); };
    _service.onGameOver = (data) { _appState = AppState.gameOver; notifyListeners(); };
    _service.onGameReset = (data) { _appState = AppState.lobby; notifyListeners(); };
    
    _service.onLobbyDeleted = (data) { 
       _appState = AppState.welcome; 
       _currentLobby = null; 
       _errorMessage = "Host ended session."; 
       notifyListeners(); 
    };
    
    _service.onError = (err) { _errorMessage = err.toString(); notifyListeners(); };
  }

  void _handleLobbyData(dynamic data) {
    final map = data as Map<String, dynamic>;
    _currentLobby = LobbyData.fromJson(map);
  }

  void setPlayerInfo(String name, String avatar) {
    _myName = name;
    _myAvatar = avatar;
    notifyListeners();
  }

  // --- ACTIONS ---

  Future<void> createLobby(String name, String mode, int qCount, String category, int timer, String difficulty, String customCode) async {
    _myName = name;
    await _service.createGame(name, mode, qCount, category, timer, difficulty, customCode);
  }

  Future<void> joinLobby(String code, String name, String avatar) async {
    _myName = name;
    _myAvatar = avatar;
    await _service.joinGame(code, name, avatar, false); 
  }

  Future<void> updateSettings(String mode, int timer, String difficulty) async {
    if (_currentLobby != null) {
      await _service.updateSettings(_currentLobby!.code, mode, timer, difficulty);
    }
  }

  Future<void> startGame() async { if (_currentLobby != null) await _service.startGame(_currentLobby!.code); }
  Future<void> submitAnswer(String answer, double time, int questionId) async { if (_currentLobby != null) await _service.submitAnswer(_currentLobby!.code, questionId, answer, time); }
  Future<void> nextQuestion() async { if (_currentLobby != null) await _service.nextQuestion(_currentLobby!.code); }
  Future<void> sendChat(String msg) async { if (_currentLobby != null) await _service.postChat(_currentLobby!.code, msg); }
  Future<void> leaveLobby() async { if (_currentLobby != null) { await _service.leaveLobby(_currentLobby!.code); _appState = AppState.welcome; _currentLobby = null; notifyListeners(); } }
  Future<void> toggleReady(bool isReady) async { if (_currentLobby != null) await _service.toggleReady(_currentLobby!.code, isReady); }
  Future<void> playAgain() async { if (_currentLobby != null) await _service.playAgain(_currentLobby!.code); }
  Future<void> resetToLobby() async { if (_currentLobby != null) await _service.resetToLobby(_currentLobby!.code); }
}