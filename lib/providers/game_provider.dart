import 'dart:async';
import 'package:flutter/material.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lobby_data.dart';

class GameConfig {
  String appTitle;
  String logoPath;
  List<String> enabledModes;

  GameConfig({
    this.appTitle = "KNOW IT ALL",
    this.logoPath = "assets/images/logo2.png", // Adjusted to match your assets folder
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

  // --- STATE ---
  AppState _appState = AppState.welcome;
  LobbyData? _currentLobby;
  Map<String, dynamic>? _lastResults;
  String? _errorMessage;
  String? _pendingTvCode; // For TV Linking

  // --- USER DATA ---
  String _myName = "Player";
  String _myAvatar = "assets/avatars/avatar_0.png";
  int _currentStreak = 0;
  int _unreadCount = 0;

  // --- SETTINGS & THEME ---
  Color _themeColor = const Color(0xFFE91E63);
  String _wallpaper = "assets/bg/cyberpunk.jpg";
  String _bgMusic = "assets/music/default.mp3";
  Brightness _brightness = Brightness.dark;
  
  bool _isMusicEnabled = true;
  bool _isPlaying = false;
  double _volume = 0.5;

  // --- OPTIONS MAPS ---
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

  Color get themeColor => _themeColor;
  String get wallpaper => _wallpaper;
  String get currentMusic => _bgMusic;
  bool get isMusicEnabled => _isMusicEnabled;
  bool get isMusicPlaying => _isPlaying;
  int get currentStreak => _currentStreak;
  Brightness get brightness => _brightness;
  int get unreadCount => _unreadCount;

  // --- CONSTRUCTOR ---
  GameProvider() {
    _loadUser();
  }

  // --- USER PERSISTENCE ---
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _myName = prefs.getString('username') ?? "Player";
    _myAvatar = prefs.getString('avatar') ?? "assets/avatars/avatar_0.png";
    notifyListeners();
  }

  Future<void> saveUser(String name, String avatar) async {
    _myName = name;
    _myAvatar = avatar;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', name);
    await prefs.setString('avatar', avatar);
    notifyListeners();
  }

  // ✅ FIX: Missing method called by WelcomeScreen
  void setPlayerInfo(String name, String avatar) {
    saveUser(name, avatar);
  }

  // --- AUDIO SYSTEM ---
  Future<void> initMusic() async {
    if (!_isMusicEnabled) return;
    // Don't restart if already playing the correct track
    if (_isPlaying && _musicPlayer.state == PlayerState.playing) return;

    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(_volume);

      // Clean path for Audioplayers (removes assets/ prefix if needed)
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

  // ✅ FIX: Missing method called by QuizScreen
  void stopMusic() {
    _musicPlayer.stop();
    _isPlaying = false;
    notifyListeners();
  }

  void toggleMusic(bool enable) {
    _isMusicEnabled = enable;
    if (enable) {
      initMusic();
    } else {
      stopMusic();
    }
  }

  void setMusicTrack(String track) {
    _bgMusic = track;
    if (_isMusicEnabled) {
      stopMusic(); // Stop old
      initMusic(); // Start new
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

  // --- THEME & STATE ---
  void updateTheme({Color? color, String? bg, Brightness? brightness}) {
    if (color != null) _themeColor = color;
    if (bg != null) _wallpaper = bg;
    if (brightness != null) _brightness = brightness;
    notifyListeners();
  }

  void setAppState(AppState s) {
    if (_appState == s) return;
    _appState = s;
    notifyListeners();
  }

  void resetUnreadCount() {
    _unreadCount = 0;
    notifyListeners();
  }

  // --- TV LINKING ---
  // ✅ FIX: Missing method called by WelcomeScreen
  Future<void> linkTv(String tvCode) async {
    _pendingTvCode = tvCode;
    notifyListeners();
  }

  Future<void> _tryLinkTv(String lobbyCode) async {
    if (_pendingTvCode != null && _hubConnection != null) {
      try {
        await _hubConnection!.invoke("LinkTV", args: [_pendingTvCode ?? "", lobbyCode]);
        debugPrint("TV Linked: $_pendingTvCode -> $lobbyCode");
        _pendingTvCode = null; // Clear after use
      } catch (e) {
        debugPrint("TV Link Failed: $e");
      }
    }
  }

  // --- SIGNALR CONNECTION & EVENTS ---
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
        _handleLobbyUpdate(args); // Update quiz data
        _appState = AppState.quiz;
        _currentStreak = 0;
        notifyListeners();
      }
    });

    _hubConnection!.on("new_round", (args) {
      if (args != null && args.isNotEmpty) {
        final map = args[0] as Map<String, dynamic>;
        // We can just re-parse the lobby or update index manually
        // But re-parsing handles sync better
        _handleLobbyUpdate(args);
        _appState = AppState.quiz;
        notifyListeners();
      }
    });

    _hubConnection!.on("question_results", (args) {
      if (args != null && args.isNotEmpty) {
        _lastResults = args[0] as Map<String, dynamic>;
        _appState = AppState.results;
        
        // Calculate Streak based on results
        if (_lastResults!['results'] != null) {
          final List resList = _lastResults!['results'] as List;
          final myRes = resList.firstWhere(
            (r) => r is Map && (r['name']?.toString() ?? '') == _myName,
            orElse: () => null,
          );
          if (myRes != null) {
            bool correct = myRes['correct'] == true;
            if (correct) {
              _currentStreak++;
              playSfx(_currentStreak > 0 && _currentStreak % 3 == 0 ? "streak" : "correct");
            } else {
              _currentStreak = 0;
              playSfx("wrong");
            }
          }
        }
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
      _errorMessage = "Host ended the session.";
      notifyListeners();
    });

    _hubConnection!.on("game_reset", (_) {
      _appState = AppState.lobby;
      _currentStreak = 0;
      notifyListeners();
    });

    await _hubConnection!.start();
  }

  // ✅ Helper to update lobby state
  void _handleLobbyUpdate(List<Object?>? args) {
    if (args != null && args.isNotEmpty) {
      final map = args[0] as Map<String, dynamic>;
      // ✅ FIX: Always create new instance to avoid 'updateFromMap' issues
      final newLobby = LobbyData.fromJson(map);
      
      // Preserve quiz data if new update doesn't have it but old one did
      if (_currentLobby?.quizData != null && (newLobby.quizData == null || newLobby.quizData!.isEmpty)) {
        newLobby.quizData = _currentLobby!.quizData;
      }

      // Chat unread count
      if (_currentLobby != null && newLobby.chat.length > _currentLobby!.chat.length) {
        _unreadCount += (newLobby.chat.length - _currentLobby!.chat.length);
      }

      _currentLobby = newLobby;
      notifyListeners();
    }
  }

  // --- ACTIONS ---

  Future<void> createLobby(String name, String avatar, String mode, int qCount, String cat, int timer, String diff, String customCode) async {
    if (_hubConnection == null) return;
    _myName = name;
    initMusic();
    
    // ✅ FIX: Use safe null-coalescing for List<Object>
    await _hubConnection!.invoke("CreateGame", args: [
      name, avatar, mode, qCount, cat, timer, diff, customCode
    ]);

    await Future.delayed(const Duration(milliseconds: 500));
    if (_currentLobby != null) {
      _appState = AppState.lobby;
      await _tryLinkTv(_currentLobby!.code);
    }
  }

  Future<void> joinLobby(String code, String name, String avatar) async {
    if (_hubConnection == null) return;
    _myName = name;
    initMusic();
    await _hubConnection!.invoke("JoinGame", args: [code, name, avatar, false]);
    
    _appState = AppState.lobby;
    await _tryLinkTv(code);
  }

  Future<void> leaveLobby() async {
    if (_hubConnection != null && _currentLobby != null) {
      await _hubConnection!.invoke("LeaveLobby", args: [_currentLobby!.code]);
    }
    _appState = AppState.welcome;
    _currentLobby = null;
    _currentStreak = 0;
    notifyListeners();
  }

  Future<void> updateSettings(String mode, int qCount, String category, int timer, String diff) async {
    if (_currentLobby != null) {
      await _hubConnection!.invoke("UpdateSettings", args: [_currentLobby!.code, mode, qCount, category, timer, diff]);
    }
  }

  Future<void> startGame() async {
    if (_currentLobby != null) await _hubConnection!.invoke("StartGame", args: [_currentLobby!.code]);
  }

  Future<void> submitAnswer(String answer, double time, int qIndex) async {
    if (_currentLobby != null) {
      await _hubConnection!.invoke("SubmitAnswer", args: [_currentLobby!.code, qIndex, answer, time]);
    }
  }

  Future<void> nextQuestion() async {
    if (_currentLobby != null) await _hubConnection!.invoke("NextQuestion", args: [_currentLobby!.code]);
  }

  Future<void> playAgain() async {
    if (_currentLobby != null) await _hubConnection!.invoke("PlayAgain", args: [_currentLobby!.code]);
  }

  Future<void> resetToLobby() async {
    if (_currentLobby != null) await _hubConnection!.invoke("ResetToLobby", args: [_currentLobby!.code]);
  }

  Future<void> toggleReady(bool isReady) async {
    if (_currentLobby != null) await _hubConnection!.invoke("ToggleReady", args: [_currentLobby!.code, isReady]);
  }

  Future<void> sendChat(String msg) async {
    if (_currentLobby != null) await _hubConnection!.invoke("PostChat", args: [_currentLobby!.code, msg]);
  }
}