import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/lobby_data.dart';
import '../services/signalr_service.dart';

enum AppState { welcome, lobby, quiz, results, gameOver }

class GameProvider extends ChangeNotifier {
  final SignalRService _service = SignalRService();
  final AudioPlayer _musicPlayer = AudioPlayer(); // Music Engine

  // --- CLIENT SETTINGS (Theming) ---
  Color _themeColor = const Color(0xFFE91E63); // Default Cyberpunk Pink
  String _wallpaper = "assets/bg/cyberpunk.jpg"; // Default BG
  String _bgMusic = "assets/music/default.mp3"; // Default Music
  bool _isMusicPlaying = false;
  double _volume = 0.5;

  // --- GAME STATE ---
  AppState _appState = AppState.welcome;
  LobbyData? _currentLobby;
  Map<String, dynamic>? _lastResults;
  String? _errorMessage;
  
  String _myName = "Player";
  String _myAvatar = "assets/avatars/avatar1.webp";

  // Getters
  AppState get appState => _appState;
  LobbyData? get lobby => _currentLobby;
  Map<String, dynamic>? get lastResults => _lastResults;
  String? get error => _errorMessage;
  String get myName => _myName;
  String get myAvatar => _myAvatar;
  bool get amIHost => _currentLobby != null && _currentLobby!.host.trim().toLowerCase() == _myName.trim().toLowerCase();

  // Theme Getters
  Color get themeColor => _themeColor;
  String get wallpaper => _wallpaper;
  bool get isMusicPlaying => _isMusicPlaying;

  // --- MUSIC ENGINE ---
  Future<void> initMusic() async {
    // Only start if not already playing
    if (!_isMusicPlaying) {
      _musicPlayer.setReleaseMode(ReleaseMode.loop); // Loop music
      _musicPlayer.setVolume(_volume);
      // Ensure you have a file at assets/music/menu.mp3 or change this
      try {
        await _musicPlayer.play(AssetSource(_bgMusic.replaceFirst('assets/', '')));
        _isMusicPlaying = true;
      } catch (e) {
        print("Music Error (Ensure assets/music/ exists): $e");
      }
      notifyListeners();
    }
  }

  void toggleMusic(bool enable) {
    if (enable) {
      _musicPlayer.resume();
      _isMusicPlaying = true;
    } else {
      _musicPlayer.pause();
      _isMusicPlaying = false;
    }
    notifyListeners();
  }

  void setVolume(double val) {
    _volume = val;
    _musicPlayer.setVolume(val);
    notifyListeners();
  }

  void updateTheme(Color color, String bgPath) {
    _themeColor = color;
    _wallpaper = bgPath;
    notifyListeners();
  }

  // --- SIGNALR & GAME LOGIC (Unchanged from previous fixes) ---
  Future<void> connect(String url) async {
    await _service.init(url);

    _service.onLobbyUpdate = (data) {
      if (data != null) {
        _currentLobby = LobbyData.fromJson(data as Map<String, dynamic>);
        notifyListeners();
      }
    };

    _service.onGameCreated = (data) { _handleLobbyData(data); _appState = AppState.lobby; notifyListeners(); };
    _service.onGameJoined = (data) { _handleLobbyData(data); _appState = AppState.lobby; notifyListeners(); };
    _service.onGameStarted = (data) { _handleGameStart(data); _appState = AppState.quiz; notifyListeners(); };
    _service.onNewRound = (data) {
       final map = data as Map<String, dynamic>;
       if (_currentLobby != null) _currentLobby!.currentQuestionIndex = map['questionIndex'] ?? 0;
       _appState = AppState.quiz; 
       notifyListeners();
    };
    _service.onQuestionResults = (data) { _lastResults = data as Map<String, dynamic>; _appState = AppState.results; notifyListeners(); };
    _service.onGameOver = (data) { _appState = AppState.gameOver; notifyListeners(); };
    _service.onGameReset = (data) { _appState = AppState.lobby; notifyListeners(); };
    _service.onLobbyDeleted = (data) { _appState = AppState.welcome; _currentLobby = null; _errorMessage = "Host ended session."; notifyListeners(); };
    _service.onError = (err) { _errorMessage = err.toString(); notifyListeners(); };
  }

  void _handleLobbyData(dynamic data) {
    final map = data as Map<String, dynamic>;
    _currentLobby = LobbyData.fromJson(map);
  }

  void _handleGameStart(dynamic data) {
      final map = data as Map<String, dynamic>;
      if (_currentLobby != null) {
        if (map['quizData'] != null) {
           final temp = LobbyData.fromJson({'quizData': map['quizData'], 'players': [], 'spectators': [], 'chat': [], 'code': '', 'host': '', 'mode': '', 'started': true, 'timer': 0, 'questionIndex': 0, 'difficulty': ''});
           _currentLobby!.quizData = temp.quizData;
        }
        _currentLobby!.currentQuestionIndex = map['questionIndex'] ?? 0;
      }
  }

  void setPlayerInfo(String name, String avatar) {
    _myName = name;
    _myAvatar = avatar;
    notifyListeners();
  }

  Future<void> createLobby(String name, String mode, int qCount, String category, int timer, String difficulty, String customCode) async {
    _myName = name;
    await _service.createGame(name, mode, qCount, category, timer, difficulty, customCode);
  }

  Future<void> joinLobby(String code, String name, String avatar) async {
    _myName = name;
    _myAvatar = avatar;
    await _service.joinGame(code, name, avatar, false); 
  }

  Future<void> updateSettings(String mode, int qCount, String category, int timer, String difficulty) async {
    if (_currentLobby != null) {
      await _service.updateSettings(_currentLobby!.code, mode, qCount, category, timer, difficulty);
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