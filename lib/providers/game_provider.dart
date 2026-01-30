import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/lobby_data.dart';
import '../services/signalr_service.dart';

class GameConfig {
  String appTitle;
  String logoPath;
  List<String> enabledModes;

  GameConfig({
    this.appTitle = "KNOW IT ALL",
    this.logoPath = "logo2.png",
    this.enabledModes = const ["general-knowledge", "calculations", "flags", "music"],
  });
}

enum AppState { welcome, create, lobby, quiz, results, gameOver }

class GameProvider extends ChangeNotifier {
  final SignalRService _service = SignalRService();
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  final GameConfig config = GameConfig();

  final Map<String, String> _musicOptions = {
    "Know It All": "assets/music/default.mp3",
    "Chill Lo-Fi": "assets/music/synth.mp3",
    "Cyberpunk": "assets/music/dubstep.mp3",
    "Hentai": "assets/music/dreams.mp3",
  };

  final Map<String, String> _wallpaperOptions = {
    "Know It All": "assets/bg/background_default.png",
    "Cyberpunk": "assets/bg/cyberpunk.jpg",
    "Hentai": "assets/bg/hentai6.jpg",
    "Chill Lo-Fi": "assets/bg/synth.jpg",
  };

  Color _themeColor = const Color(0xFFE91E63);
  String _wallpaper = "assets/bg/cyberpunk.jpg";
  String _bgMusic = "assets/music/default.mp3";
  Brightness _brightness = Brightness.dark;

  bool _isMusicEnabled = true;
  bool _isPlaying = false;
  double _volume = 0.5;

  AppState _appState = AppState.welcome;
  LobbyData? _currentLobby;
  Map<String, dynamic>? _lastResults;
  String? _errorMessage;

  String _myName = "Player";
  String _myAvatar = "assets/avatars/avatar1.webp";
  int _currentStreak = 0;
  int _unreadCount = 0;

  AppState get appState => _appState;
  LobbyData? get lobby => _currentLobby;
  Map<String, dynamic>? get lastResults => _lastResults;
  String? get error => _errorMessage;

  String get myName => _myName;
  String get myAvatar => _myAvatar;

  bool get amIHost =>
      _currentLobby != null &&
      _currentLobby!.host.trim().toLowerCase() ==
          _myName.trim().toLowerCase();

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

  void resetUnreadCount() {
    _unreadCount = 0;
    notifyListeners();
  }

  void setAppState(AppState s) {
    if (_appState == s) return;
    _appState = s;
    notifyListeners();
  }

  void goToWelcome() {
    _appState = AppState.welcome;
    notifyListeners();
  }

  void goToCreate() {
    _appState = AppState.create;
    notifyListeners();
  }

  void updateTheme({Color? color, String? bg, Brightness? brightness}) {
    if (color != null) _themeColor = color;
    if (bg != null) _wallpaper = bg;
    if (brightness != null) _brightness = brightness;
    notifyListeners();
  }

  Future<void> initMusic() async {
    if (!_isMusicEnabled) return;
    if (_isPlaying && _musicPlayer.state == PlayerState.playing) return;

    try {
      _musicPlayer.setReleaseMode(ReleaseMode.loop);
      _musicPlayer.setVolume(_volume);

      final cleanPath =
          _bgMusic.startsWith("assets/") ? _bgMusic.substring(7) : _bgMusic;
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
      case "correct":
        file = "audio/correct.mp3";
        break;
      case "wrong":
        file = "audio/wrong.mp3";
        break;
      case "streak":
        file = "audio/streak.mp3";
        break;
      case "gameover":
        file = "audio/gameover.mp3";
        break;
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
      if (_currentStreak > 0 && _currentStreak % 3 == 0) {
        playSfx("streak");
      } else {
        playSfx("correct");
      }
    } else {
      _currentStreak = 0;
      playSfx("wrong");
    }
    notifyListeners();
  }

  Future<void> connect(String url) async {
    debugPrint("CONNECTING TO: $url");
    await _service.init(url);

    _service.onLobbyUpdate = (data) {
      if (data != null) {
        _mergeLobbyData(data);
        notifyListeners();
      }
    };

    _service.onGameCreated = (data) {
      _mergeLobbyData(data);
      _appState = AppState.lobby;
      notifyListeners();
    };

    _service.onGameJoined = (data) {
      _mergeLobbyData(data);
      _appState = AppState.lobby;
      notifyListeners();
    };

    _service.onGameStarted = (data) {
      _handleGameStart(data);
    };

    _service.onNewRound = (data) {
      final map = data as Map<String, dynamic>;
      if (_currentLobby != null) {
        _currentLobby!.currentQuestionIndex = map['questionIndex'] ?? 0;
      }
      _appState = AppState.quiz;
      notifyListeners();
    };

    _service.onQuestionResults = (data) {
      _lastResults = data as Map<String, dynamic>;
      _appState = AppState.results;

      bool amICorrect = false;
      if (_lastResults != null && _lastResults!['results'] != null) {
        final List resList = _lastResults!['results'] as List;
        final myRes = resList.firstWhere(
          (r) => r is Map && (r['name']?.toString() ?? '') == _myName,
          orElse: () => null,
        );
        if (myRes != null) {
          amICorrect = (myRes['correct'] == true);
        }
      }

      handleAnswerResult(amICorrect);
      notifyListeners();
    };

    _service.onGameOver = (data) {
      _appState = AppState.gameOver;
      playSfx("gameover");
      notifyListeners();
    };

    _service.onGameReset = (data) {
      _appState = AppState.lobby;
      _currentStreak = 0;
      notifyListeners();
    };

    _service.onLobbyDeleted = (data) {
      _appState = AppState.welcome;
      _currentLobby = null;
      _errorMessage = "Host ended session.";
      notifyListeners();
    };

    _service.onError = (err) {
      _errorMessage = err.toString();
      notifyListeners();
    };
  }

  void _mergeLobbyData(dynamic data) {
    final newLobby = LobbyData.fromJson(data);

    if (_currentLobby != null &&
        _currentLobby!.quizData != null &&
        _currentLobby!.quizData!.isNotEmpty) {
      if (newLobby.quizData == null || newLobby.quizData!.isEmpty) {
        newLobby.quizData = _currentLobby!.quizData;
      }
    }

    if (_currentLobby != null && newLobby.chat.length > _currentLobby!.chat.length) {
      _unreadCount += (newLobby.chat.length - _currentLobby!.chat.length);
    }

    _currentLobby = newLobby;
  }

  // ✅ FIX: avoid notifyListeners during build/layout
  void stopMusic() {
    _musicPlayer.stop();
    _isPlaying = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!hasListeners) return;
      notifyListeners();
    });
  }

  void _handleGameStart(dynamic data) {
    try {
      final map = data as Map<String, dynamic>;

      if (_currentLobby != null) {
        _currentLobby!.started = true;

        if (map['quizData'] != null) {
          final List rawList = map['quizData'];
          _currentLobby!.quizData = rawList
              .map((item) => item as Map<String, dynamic>)
              .toList();
        }

        _currentLobby!.currentQuestionIndex = map['questionIndex'] ?? 0;
      }

      _appState = AppState.quiz;
      _currentStreak = 0;
      notifyListeners();
    } catch (e) {
      debugPrint("CRITICAL ERROR in _handleGameStart: $e");
      _errorMessage = "Failed to load quiz data.";
      notifyListeners();
    }
  }

  void setPlayerInfo(String name, String avatar) {
    _myName = name;
    _myAvatar = avatar;
    notifyListeners();
  }

  // ✅ FIX: CreateLobby sends avatar too
  Future<void> createLobby(
    String name,
    String mode,
    int qCount,
    String category,
    int timer,
    String difficulty,
    String customCode,
  ) async {
    _myName = name;
    initMusic();

    await _service.createGame(
      _myName,
      _myAvatar,
      mode,
      qCount,
      category,
      timer,
      difficulty,
      customCode,
    );
  }

  Future<void> joinLobby(String code, String name, String avatar) async {
    _myName = name;
    _myAvatar = avatar;
    initMusic();
    await _service.joinGame(code, name, avatar, false);
  }

  Future<void> updateSettings(String mode, int qCount, String category, int timer, String difficulty) async {
    if (_currentLobby != null) {
      await _service.updateSettings(_currentLobby!.code, mode, qCount, category, timer, difficulty);
    }
  }

  Future<void> startGame() async {
    if (_currentLobby != null) await _service.startGame(_currentLobby!.code);
  }

  Future<void> submitAnswer(String answer, double time, int questionId) async {
    if (_currentLobby != null) {
      await _service.submitAnswer(_currentLobby!.code, questionId, answer, time);
    }
  }

  Future<void> nextQuestion() async {
    if (_currentLobby != null) await _service.nextQuestion(_currentLobby!.code);
  }

  Future<void> sendChat(String msg) async {
    if (_currentLobby != null) await _service.postChat(_currentLobby!.code, msg);
  }

  Future<void> leaveLobby() async {
    if (_currentLobby != null) {
      _service.leaveLobby(_currentLobby!.code).catchError((_) {});
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
