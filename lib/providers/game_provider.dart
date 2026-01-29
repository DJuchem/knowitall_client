import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/lobby_data.dart';
import '../services/signalr_service.dart';

// --- DEPLOYMENT CONFIG ---
class GameConfig {
  String appTitle;
  String logoPath;
  List<String> enabledModes;
  
  GameConfig({
    this.appTitle = "KNOW IT ALL",
    this.logoPath = "logo.png", // FIX: Removed 'assets/' prefix to prevent 404
    this.enabledModes = const ["general-knowledge", "calculations", "flags", "music"],
  });
}

enum AppState { welcome, create, lobby, quiz, results, gameOver }

class GameProvider extends ChangeNotifier {
  final SignalRService _service = SignalRService();
  final AudioPlayer _musicPlayer = AudioPlayer(); 
  final AudioPlayer _sfxPlayer = AudioPlayer();
  
  // CONFIG INSTANCE
  final GameConfig config = GameConfig();

  // ASSETS
  final Map<String, String> _musicOptions = {
    "Cyber Action": "assets/music/action.mp3",
    "Chill Lo-Fi": "assets/music/chill.mp3",
    "Game Default": "assets/music/default.mp3",
  };
  final Map<String, String> _wallpaperOptions = {
    "Cyber City": "assets/bg/cyberpunk.jpg",
    "Matrix Code": "assets/bg/matrix.jpg",
    "Space Void": "assets/bg/space.jpg",
    "Retro Sunset": "assets/bg/retro.jpg",
  };

  // SETTINGS
  Color _themeColor = const Color(0xFFE91E63);
  String _wallpaper = "assets/bg/cyberpunk.jpg"; 
  String _bgMusic = "assets/music/default.mp3"; 
  Brightness _brightness = Brightness.dark; 
  
  // AUDIO STATE
  bool _isMusicEnabled = true; 
  bool _isPlaying = false;
  double _volume = 0.5;

  // GAME STATE
  AppState _appState = AppState.welcome;
  LobbyData? _currentLobby;
  Map<String, dynamic>? _lastResults;
  String? _errorMessage;
  
  String _myName = "Player";
  String _myAvatar = "assets/avatars/avatar1.webp";
  int _currentStreak = 0;
  int _unreadCount = 0;

  // GETTERS
  AppState get appState => _appState;
  LobbyData? get lobby => _currentLobby;
  Map<String, dynamic>? get lastResults => _lastResults;
  String? get error => _errorMessage;
  String get myName => _myName;
  String get myAvatar => _myAvatar;
  bool get amIHost => _currentLobby != null && _currentLobby!.host.trim().toLowerCase() == _myName.trim().toLowerCase();
  
  Color get themeColor => _themeColor;
  String get wallpaper => _wallpaper;
  String get currentMusic => _bgMusic;
  bool get isMusicEnabled => _isMusicEnabled;
  bool get isMusicPlaying => _isPlaying; 
  int get currentStreak => _currentStreak;
  Brightness get brightness => _brightness;
  int get unreadCount => _unreadCount;

  Map<String, String> get musicOptions => _musicOptions;
  Map<String, String> get wallpaperOptions => _wallpaperOptions;

  // --- ACTIONS ---

  void resetUnreadCount() { 
    _unreadCount = 0; 
    notifyListeners(); 
  }
void setAppState(AppState s) {
  if (_appState == s) return;
  _appState = s;
  notifyListeners();
}

// Add to GameProvider
void goToWelcome() {
  _appState = AppState.welcome;
  notifyListeners();
}

void goToCreate() {
  _appState = AppState.create; // you DO have AppState.create (your router error proves it)
  notifyListeners();
}


  void updateTheme({Color? color, String? bg, Brightness? brightness}) {
    if (color != null) _themeColor = color;
    if (bg != null) _wallpaper = bg;
    if (brightness != null) _brightness = brightness;
    notifyListeners();
  }

  // --- MUSIC LOGIC ---
  Future<void> initMusic() async {
    if (!_isMusicEnabled) return;
    if (_isPlaying && _musicPlayer.state == PlayerState.playing) return;

    try {
      _musicPlayer.setReleaseMode(ReleaseMode.loop);
      _musicPlayer.setVolume(_volume);
      
      // Fix for AudioPlayers adding "assets/" automatically
      final cleanPath = _bgMusic.startsWith("assets/") ? _bgMusic.substring(7) : _bgMusic;
      await _musicPlayer.play(AssetSource(cleanPath));
      
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint("Audio Blocked/Failed: $e");
      _isPlaying = false; 
      notifyListeners();
    }
  }

  void setMusicTrack(String assetPath) {
    _bgMusic = assetPath;
    if (_isMusicEnabled) {
      _musicPlayer.stop();
      _isPlaying = false;
      initMusic(); 
    }
    notifyListeners();
  }

  void toggleMusic(bool enable) {
    _isMusicEnabled = enable;
    if (enable) {
      initMusic(); 
    } else {
      _musicPlayer.stop();
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> playSfx(String type) async {
    String file = "";
    switch (type) {
      case "correct": file = "audio/correct.mp3"; break;
      case "wrong": file = "audio/wrong.mp3"; break;
      case "streak": file = "audio/streak.mp3"; break;
      case "gameover": file = "audio/gameover.mp3"; break;
    }
    if (file.isNotEmpty) {
      try {
        await _sfxPlayer.stop();
        await _sfxPlayer.play(AssetSource(file), mode: PlayerMode.lowLatency);
      } catch (_) {}
    }
  }

  void handleAnswerResult(bool correct) {
    if (correct) {
      _currentStreak++;
      if (_currentStreak > 0 && _currentStreak % 3 == 0) playSfx("streak");
      else playSfx("correct");
    } else {
      _currentStreak = 0;
      playSfx("wrong");
    }
    notifyListeners();
  }

  // --- SIGNALR ---
  Future<void> connect(String url) async {
    debugPrint("CONNECTING TO: $url");
    await _service.init(url);
    
    _service.onLobbyUpdate = (data) { 
        if(data != null) {
            _mergeLobbyData(data); // FIX: Use merge instead of overwrite
            notifyListeners();
        } 
    };
    _service.onGameCreated = (data) { 
        debugPrint("GAME CREATED: $data");
        _mergeLobbyData(data); // FIX: Use merge
        _appState = AppState.lobby; 
        notifyListeners(); 
    };
    _service.onGameJoined = (data) { 
        debugPrint("GAME JOINED: $data");
        _mergeLobbyData(data); // FIX: Use merge
        _appState = AppState.lobby; 
        notifyListeners(); 
    };
    _service.onGameStarted = (data) { 
        debugPrint("GAME STARTED SIGNAL RECEIVED");
        _handleGameStart(data); 
    };
    _service.onNewRound = (data) { 
       final map = data as Map<String, dynamic>;
       if(_currentLobby != null) _currentLobby!.currentQuestionIndex = map['questionIndex'] ?? 0;
       _appState = AppState.quiz; 
       notifyListeners();
    };
    _service.onQuestionResults = (data) { 
      _lastResults = data as Map<String, dynamic>; 
      _appState = AppState.results; 
      
      bool amICorrect = false;
      if (_lastResults != null && _lastResults!['results'] != null) {
        final myRes = (_lastResults!['results'] as List).firstWhere((r) => r['name'] == _myName, orElse: () => null);
        if (myRes != null) amICorrect = myRes['correct'] == true;
      }
      handleAnswerResult(amICorrect);
      notifyListeners(); 
    };
    _service.onGameOver = (data) { _appState = AppState.gameOver; playSfx("gameover"); notifyListeners(); };
    _service.onGameReset = (data) { _appState = AppState.lobby; _currentStreak = 0; notifyListeners(); };
    _service.onLobbyDeleted = (data) { 
        _appState = AppState.welcome; 
        _currentLobby = null; 
        _errorMessage = "Host ended session."; 
        notifyListeners(); 
    };
    _service.onError = (err) { _errorMessage = err.toString(); notifyListeners(); };
  }

  // --- CRITICAL FIX: DATA PRESERVATION METHOD ---
  // Prevents the "empty" lobby update from wiping out our quiz data
  void _mergeLobbyData(dynamic data) { 
      final newLobby = LobbyData.fromJson(data);
      
      // If we already have quiz data, and the new update doesn't, KEEP the old data!
      if (_currentLobby != null && _currentLobby!.quizData != null && _currentLobby!.quizData!.isNotEmpty) {
          if (newLobby.quizData == null || newLobby.quizData!.isEmpty) {
              debugPrint("PRESERVING QUIZ DATA during Lobby Update");
              newLobby.quizData = _currentLobby!.quizData;
              //amIHost = newLobby.host;
          }
      }

      // Logic for unread count
      if (_currentLobby != null && newLobby.chat.length > _currentLobby!.chat.length) {
          _unreadCount += (newLobby.chat.length - _currentLobby!.chat.length);
      }
      
      _currentLobby = newLobby; 
  }
  
void stopMusic() {
    _musicPlayer.stop();
    _isPlaying = false;
    notifyListeners();
  }

  void _handleGameStart(dynamic data) {
      try {
        final map = data as Map<String, dynamic>;
        debugPrint("PARSING GAME START DATA. Keys: ${map.keys}");
        
        if (_currentLobby != null) {
          _currentLobby!.started = true;
          
          if (map['quizData'] != null) {
             final List rawList = map['quizData'];
             debugPrint("QUIZ DATA FOUND. Items: ${rawList.length}");
             
             // Ensure robust casting
             _currentLobby!.quizData = rawList.map((item) {
                return item as Map<String, dynamic>;
             }).toList();
          } else {
             debugPrint("WARNING: quizData IS NULL IN PAYLOAD!");
          }
          
          _currentLobby!.currentQuestionIndex = map['questionIndex'] ?? 0;
        } else {
           debugPrint("ERROR: Current Lobby is null during Start Game");
        }
        
        // Update State
        _appState = AppState.quiz; 
        _currentStreak = 0;
        notifyListeners(); 
      } catch (e) {
        debugPrint("CRITICAL ERROR in _handleGameStart: $e");
        _errorMessage = "Failed to load quiz data.";
        notifyListeners();
      }
  }

  void setPlayerInfo(String name, String avatar) { _myName = name; _myAvatar = avatar; notifyListeners(); }
  
  // --- ACTIONS ---
  
  Future<void> createLobby(String name, String mode, int qCount, String category, int timer, String difficulty, String customCode) async { 
    _myName = name; 
    initMusic();
    await _service.createGame(name, mode, qCount, category, timer, difficulty, customCode); 
  }

  Future<void> joinLobby(String code, String name, String avatar) async { 
    _myName = name; 
    _myAvatar = avatar; 
    initMusic();
    await _service.joinGame(code, name, avatar, false); 
  }

  Future<void> updateSettings(String mode, int qCount, String category, int timer, String difficulty) async { 
    if (_currentLobby != null) await _service.updateSettings(_currentLobby!.code, mode, qCount, category, timer, difficulty); 
  }

  Future<void> startGame() async { 
    if (_currentLobby != null) await _service.startGame(_currentLobby!.code); 
  }

  Future<void> submitAnswer(String answer, double time, int questionId) async { 
    if (_currentLobby != null) await _service.submitAnswer(_currentLobby!.code, questionId, answer, time); 
  }

  Future<void> nextQuestion() async { 
    if (_currentLobby != null) await _service.nextQuestion(_currentLobby!.code); 
  }

  Future<void> sendChat(String msg) async { 
    if (_currentLobby != null) await _service.postChat(_currentLobby!.code, msg); 
  }

  Future<void> leaveLobby() async { 
    debugPrint("PROVIDER: Leaving Lobby...");
    if (_currentLobby != null) { 
      _service.leaveLobby(_currentLobby!.code).catchError((e) => print("Leave error: $e"));
    }
    _appState = AppState.welcome; 
    _currentLobby = null; 
    _currentStreak = 0;
    _lastResults = null;
    notifyListeners(); 
  }

  Future<void> toggleReady(bool isReady) async { 
    if (_currentLobby != null) await _service.toggleReady(_currentLobby!.code, isReady); 
  }

  Future<void> playAgain() async { 
    if (_currentLobby != null) await _service.playAgain(_currentLobby!.code); 
  }

  Future<void> resetToLobby() async { 
    if (_currentLobby != null) await _service.resetToLobby(_currentLobby!.code); 
  }
}