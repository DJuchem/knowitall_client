import 'dart:async';
import 'package:flutter/material.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lobby_data.dart';
import '../theme/app_theme.dart';

class GameConfig {
  String appTitle;
  String logoPath;
  List<String> enabledModes;

  GameConfig({
    this.appTitle = "KNOW IT ALL",
    this.logoPath = "assets/logo2.png",
    this.enabledModes = const ["general-knowledge", "calculations", "flags", "music"],
  });
}

enum AppState { welcome, create, lobby, quiz, results, gameOver }

class GameProvider extends ChangeNotifier {
  // --- SERVICES ---
  HubConnection? _hubConnection;
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  
  final GameConfig config = GameConfig();
  Completer<void>? _lobbyCompleter;

  // --- STATE ---
  AppState _appState = AppState.welcome;
  LobbyData? _currentLobby;
  Map<String, dynamic>? _lastResults;
  String? _errorMessage;
  String? _pendingTvCode; 

  // --- USER DATA ---
  String _myName = "Player";
  String _myAvatar = "assets/avatars/avatar_0.png";
  int _currentStreak = 0;
  int _lastChatReadIndex = 0; 

  // --- SETTINGS ---
  String _colorScheme = "Cyberpunk"; // Default Scheme
  String _wallpaper = "assets/bg/cyberpunk.jpg";
  String _bgMusic = "assets/music/default.mp3";
  Brightness _brightness = Brightness.dark;
  
  bool _isMusicEnabled = true;
  bool _isPlaying = false;
  double _volume = 0.5;

  // --- OPTIONS ---
  final Map<String, String> musicOptions = {
    "Know It All": "assets/music/default.mp3",
    "Chill Lo-Fi": "assets/music/synth.mp3",
    "Cyberpunk": "assets/music/dubstep.mp3",
    "Hentai": "assets/music/dreams.mp3",
  };

  final Map<String, String> wallpaperOptions = {
    "Know It All": "assets/bg/background_default.png",
    "Cyberpunk": "assets/bg/cyberpunk.jpg",
    "Hentai": "assets/bg/hentai6.jpg",
    "Chill Lo-Fi": "assets/bg/synth.jpg",
  };

  // --- GETTERS ---
  AppState get appState => _appState;
  LobbyData? get lobby => _currentLobby;
  Map<String, dynamic>? get lastResults => _lastResults;
  String? get error => _errorMessage;

  String get myName => _myName;
  String get myAvatar => _myAvatar;
  bool get amIHost => _currentLobby != null && _currentLobby!.host.trim().toLowerCase() == _myName.trim().toLowerCase();

  // Dynamic Theme Getters
  String get currentScheme => _colorScheme;
  Color get themeColor => AppTheme.schemes[_colorScheme]?.primary ?? const Color(0xFFFF58CC);
  
  String get wallpaper => _wallpaper;
  String get currentMusic => _bgMusic;
  bool get isMusicEnabled => _isMusicEnabled;
  bool get isMusicPlaying => _isPlaying;
  int get currentStreak => _currentStreak;
  Brightness get brightness => _brightness;
  
  int get unreadCount {
    if (_currentLobby == null) return 0;
    int total = _currentLobby!.chat.length;
    return (total - _lastChatReadIndex).clamp(0, 99);
  }

  GameProvider() {
    _loadUser();
  }

  // --- METHODS ---

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _myName = prefs.getString('username') ?? "Player";
    _myAvatar = prefs.getString('avatar') ?? "assets/avatars/avatar_0.png";
    
    // Load saved theme settings
    if (prefs.containsKey('theme_scheme')) _colorScheme = prefs.getString('theme_scheme')!;
    if (prefs.containsKey('theme_bright')) {
      _brightness = prefs.getBool('theme_bright')! ? Brightness.dark : Brightness.light;
    }
    
    notifyListeners();
  }

  void setPlayerInfo(String name, String avatar) {
    _myName = name;
    _myAvatar = avatar;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('username', name);
      prefs.setString('avatar', avatar);
    });
    notifyListeners();
  }

  void markChatAsRead() {
    if (_currentLobby != null) {
      _lastChatReadIndex = _currentLobby!.chat.length;
      notifyListeners();
    }
  }

  // --- AUDIO ---
  Future<void> initMusic() async {
    if (!_isMusicEnabled) return;
    if (_isPlaying && _musicPlayer.state == PlayerState.playing) return;

    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(_volume);
      
      String playPath = _bgMusic;
      if (playPath.startsWith("assets/")) playPath = playPath.substring(7);

      await _musicPlayer.play(AssetSource(playPath));
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint("Audio Error: $e");
      _isPlaying = false;
      notifyListeners();
    }
  }

  void stopMusic() {
    _musicPlayer.stop();
    _isPlaying = false;
    notifyListeners();
  }

  void toggleMusic(bool enable) {
    _isMusicEnabled = enable;
    if (enable) initMusic(); else stopMusic();
  }

  void setMusicTrack(String track) {
    _bgMusic = track;
    if (_isMusicEnabled) {
      stopMusic();
      initMusic();
    }
    notifyListeners();
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

  void updateTheme({String? scheme, String? bg, Brightness? brightness}) {
    if (scheme != null) _colorScheme = scheme;
    if (bg != null) _wallpaper = bg;
    if (brightness != null) _brightness = brightness;
    
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('theme_scheme', _colorScheme);
      prefs.setBool('theme_bright', _brightness == Brightness.dark);
    });
    
    notifyListeners();
  }

  void setAppState(AppState s) {
    if (_appState == s) return;
    _appState = s;
    notifyListeners();
  }

  // --- TV LINKING ---
  Future<void> linkTv(String tvCode) async {
    _pendingTvCode = tvCode;
    notifyListeners();
  }

  Future<void> _tryLinkTv(String lobbyCode) async {
    if (_pendingTvCode != null && _hubConnection != null) {
      try {
        await _hubConnection!.invoke("LinkTV", args: <Object>[_pendingTvCode!, lobbyCode]);
        _pendingTvCode = null; 
      } catch (e) {
        debugPrint("TV Link Failed: $e");
      }
    }
  }

  Future<void> syncTvTheme() async {
    if (_hubConnection != null && _currentLobby != null) {
      try {
        await _hubConnection!.invoke("SyncTheme", args: <Object>[
          _currentLobby!.code, 
          _wallpaper, 
          _bgMusic
        ]);
      } catch (_) {}
    }
  }

  // --- CONNECTION ---
  Future<void> connect(String url) async {
    if (_hubConnection != null) return;

    _hubConnection = HubConnectionBuilder()
        .withUrl(url)
        .withAutomaticReconnect()
        .build();

    _hubConnection!.on("game_created", _handleLobbyUpdate);
    _hubConnection!.on("game_joined", _handleLobbyUpdate);
    _hubConnection!.on("lobby_update", _handleLobbyUpdate);
    
    _hubConnection!.on("game_started", (args) {
      if (args != null && args.isNotEmpty) {
        _handleLobbyUpdate(args);
        _appState = AppState.quiz;
        _currentStreak = 0;
        notifyListeners();
      }
    });

    _hubConnection!.on("new_round", (args) {
      if (args != null && args.isNotEmpty) {
        final map = args[0] as Map<String, dynamic>;
        _handleLobbyUpdate(args);
        if (_currentLobby != null) {
          _currentLobby!.currentQuestionIndex = map['questionIndex'] ?? 0;
        }
        _appState = AppState.quiz;
        notifyListeners();
      }
    });

    _hubConnection!.on("question_results", (args) {
      if (args != null && args.isNotEmpty) {
        _lastResults = args[0] as Map<String, dynamic>;
        _appState = AppState.results;
        notifyListeners();
      }
    });

    _hubConnection!.on("game_over", (_) {
      _appState = AppState.gameOver;
      playSfx("gameover");
      notifyListeners();
    });

    _hubConnection!.on("lobby_deleted", (_) {
      _appState = AppState.welcome;
      _currentLobby = null;
      notifyListeners();
    });

    _hubConnection!.on("game_reset", (_) {
      _appState = AppState.lobby;
      _currentStreak = 0;
      notifyListeners();
    });

    await _hubConnection!.start();
  }

  void _handleLobbyUpdate(List<Object?>? args) {
    if (args != null && args.isNotEmpty) {
      final map = args[0] as Map<String, dynamic>;
      final newLobby = LobbyData.fromJson(map);
      
      if (_currentLobby?.quizData != null && (newLobby.quizData == null || newLobby.quizData!.isEmpty)) {
        newLobby.quizData = _currentLobby!.quizData;
      }

      if (_currentLobby == null || _currentLobby!.code != newLobby.code) {
        _lastChatReadIndex = newLobby.chat.length; 
      }

      _currentLobby = newLobby;
      
      if (_lobbyCompleter != null && !_lobbyCompleter!.isCompleted) {
        _lobbyCompleter!.complete();
      }
      
      notifyListeners();
    }
  }

  // --- ACTIONS ---

  Future<void> createLobby(String name, String avatar, String mode, int qCount, String cat, int timer, String diff, String customCode) async {
    if (_hubConnection == null) return;
    _myName = name;
    initMusic();
    
    _lobbyCompleter = Completer<void>();
    await _hubConnection!.invoke("CreateGame", args: <Object>[name, avatar, mode, qCount, cat, timer, diff, customCode]);
    await _lobbyCompleter!.future.timeout(const Duration(seconds: 5), onTimeout: () => null);

    if (_currentLobby != null) {
      _appState = AppState.lobby;
      await _tryLinkTv(_currentLobby!.code);
      await syncTvTheme();
      notifyListeners();
    }
  }

  Future<void> joinLobby(String code, String name, String avatar) async {
    if (_hubConnection == null) return;
    _myName = name;
    initMusic();
    
    _lobbyCompleter = Completer<void>();
    await _hubConnection!.invoke("JoinGame", args: <Object>[code, name, avatar, false]);
    await _lobbyCompleter!.future.timeout(const Duration(seconds: 5), onTimeout: () => null);

    if (_currentLobby != null) {
      _appState = AppState.lobby;
      await _tryLinkTv(code);
      notifyListeners();
    }
  }

  Future<void> leaveLobby() async {
    if (_hubConnection != null && _currentLobby != null) {
      await _hubConnection!.invoke("LeaveLobby", args: <Object>[_currentLobby!.code]);
    }
    _appState = AppState.welcome;
    _currentLobby = null;
    _currentStreak = 0;
    notifyListeners();
  }

  Future<void> updateSettings(String mode, int qCount, String cat, int timer, String diff) async {
    if (_currentLobby != null) {
      await _hubConnection!.invoke("UpdateSettings", args: <Object>[_currentLobby!.code, mode, qCount, cat, timer, diff]);
    }
  }

  Future<void> startGame() async {
    if (_currentLobby != null) await _hubConnection!.invoke("StartGame", args: <Object>[_currentLobby!.code]);
  }

  Future<void> submitAnswer(String answer, double time, int qIndex) async {
    if (_currentLobby != null) {
      await _hubConnection!.invoke("SubmitAnswer", args: <Object>[_currentLobby!.code, qIndex, answer, time]);
    }
  }

  Future<void> nextQuestion() async {
    if (_currentLobby != null) await _hubConnection!.invoke("NextQuestion", args: <Object>[_currentLobby!.code]);
  }

  Future<void> playAgain() async {
    if (_currentLobby != null) await _hubConnection!.invoke("PlayAgain", args: <Object>[_currentLobby!.code]);
  }

  Future<void> resetToLobby() async {
    if (_currentLobby != null) await _hubConnection!.invoke("ResetToLobby", args: <Object>[_currentLobby!.code]);
  }

  Future<void> toggleReady(bool isReady) async {
    if (_currentLobby != null) await _hubConnection!.invoke("ToggleReady", args: <Object>[_currentLobby!.code, isReady]);
  }

  Future<void> sendChat(String msg) async {
    if (_currentLobby != null) await _hubConnection!.invoke("PostChat", args: <Object>[_currentLobby!.code, msg]);
  }
}