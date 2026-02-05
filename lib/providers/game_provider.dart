import 'dart:async';
import 'dart:math';
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
    // ✅ FIX: No 'assets/' prefix here. The UI adds it safely.
    this.logoPath = "logo2.png", 
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

  // --- OPTION B (PAIRING) ---
  String? _hostKey;
  String get hostKey => _hostKey ?? "";

  // --- STATE ---
  AppState _appState = AppState.welcome;
  LobbyData? _currentLobby;
  Map<String, dynamic>? _lastResults;
  String? _errorMessage;

  String? _pendingTvCode;
  String? get pendingTvCode => _pendingTvCode;

  String _myName = "Player";
  String _myAvatar = "assets/avatars/avatar_0.png";

  int _currentStreak = 0;
  int _lastChatReadIndex = 0;

  // --- SETTINGS ---
  String _colorScheme = "Default";
  String _wallpaper = "assets/bg/background_default.png"; 
  String _bgMusic = "assets/music/background-music.mp3";
  Brightness _brightness = Brightness.dark;

  bool _isMusicEnabled = false; 
  bool _isPlaying = false;
  double _volume = 0.5;

  // --- DATA ---
  final Map<String, String> gameModes = const {
    "General Knowledge": "general-knowledge",
    "Math Calculations": "calculations",
    "Guess the Flag": "flags",
    "Country Capitals": "capitals",
    "Music Quiz": "music",
    "Odd One Out": "odd_one_out",
    "Fill In The Blank": "fill_in_the_blank",
    "True / False": "true_false",
    "Population": "population",
  };

  final Map<String, String> musicOptions = {
    "KnowItAll": "assets/music/background-music.mp3",
    "Chill Lo-Fi": "assets/music/synth.mp3",
    "High Energy": "assets/music/dubstep.mp3",
    "Dreamy": "assets/music/dreams.mp3",
    "Retro": "assets/music/terminal.mp3",
    "Space": "assets/music/nebula.mp3",
    "Nature": "assets/music/forest_ambient.mp3",
    "Classical": "assets/music/RondoAllegro.mp3",
  };

  final Map<String, String> wallpaperOptions = {
    "Default": "assets/bg/background_default.png",
    "Neon City": "assets/bg/cyberpunk.jpg",
    "Digital Rain": "assets/bg/matrix_rain.jpg",
    "Deep Galaxy": "assets/bg/galaxy.jpg",
    "Volcanic": "assets/bg/magma.jpg",
    "Mystic Forest": "assets/bg/forest.jpg",
    "Underwater": "assets/bg/underwater.jpg",
    "Ancient Castle": "assets/bg/castle.jpg",
    "Anime Style": "assets/bg/hentai6.jpg",
    "Synthwave": "assets/bg/synth.jpg",
  };

  // --- GETTERS ---
  AppState get appState => _appState;
  LobbyData? get lobby => _currentLobby;
  Map<String, dynamic>? get lastResults => _lastResults;
  String? get error => _errorMessage;
  String get myName => _myName;
  String get myAvatar => _myAvatar;
  bool get amIHost => _currentLobby != null && _currentLobby!.host.trim().toLowerCase() == _myName.trim().toLowerCase();
  String get currentScheme => _colorScheme;
  
  // ✅ FIX: Restored themeColor getter that was causing errors
  Color get themeColor => AppTheme.schemes[_colorScheme]?.primary ?? const Color(0xFFE91E63);

  String get wallpaper => _wallpaper;
  String get currentMusic => _bgMusic;
  bool get isMusicEnabled => _isMusicEnabled;
  bool get isMusicPlaying => _isPlaying;
  int get currentStreak => _currentStreak;
  Brightness get brightness => _brightness;
  int get unreadCount => _currentLobby == null ? 0 : (_currentLobby!.chat.length - _lastChatReadIndex).clamp(0, 99);

  GameProvider() {
    _loadUser();
  }

  // --- METHODS ---

  // ✅ FIX: Restored setAppState method that was missing
  void setAppState(AppState s) {
    if (_appState == s) return;
    _appState = s;
    notifyListeners();
  }

  String _newHostKey() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final r = Random.secure().nextInt(1 << 30);
    return "HK_${now}_${r.toRadixString(16).toUpperCase()}";
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _myName = prefs.getString('username') ?? "Player";
    _myAvatar = prefs.getString('avatar') ?? "assets/avatars/avatar_0.png";
    if (prefs.containsKey('theme_scheme')) _colorScheme = prefs.getString('theme_scheme')!;
    if (prefs.containsKey('theme_wallpaper')) _wallpaper = prefs.getString('theme_wallpaper')!;
    if (prefs.containsKey('theme_music')) _bgMusic = prefs.getString('theme_music')!;
    if (prefs.containsKey('theme_bright')) _brightness = prefs.getBool('theme_bright')! ? Brightness.dark : Brightness.light;
    _hostKey = null;
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

  // --- AUDIO LOGIC ---
  Future<void> initMusic() async {
    if (!_isMusicEnabled) return;
    
    // ✅ FIX: Never auto-play lobby music if we are in Music Quiz Mode
    if (_currentLobby?.mode.toLowerCase() == "music") return;

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

  Future<void> stopMusic({bool notify = true}) async {
    try {
      await _musicPlayer.stop();
    } catch (_) {}
    _isPlaying = false;
    if (notify) notifyListeners();
  }

  void toggleMusic(bool enable) {
    _isMusicEnabled = enable;
    if (enable) {
      initMusic();
    } else {
      stopMusic();
    }
    notifyListeners();
  }

  void setMusicTrack(String track) {
    _bgMusic = track;
    SharedPreferences.getInstance().then((prefs) => prefs.setString('theme_music', track));
    if (_isMusicEnabled) {
      // Restart music with new track (unless in music quiz mode)
      stopMusic();
      initMusic();
    }
    notifyListeners();
  }

  Future<void> playSfx(String type) async {
    try {
      String file = "";
      switch (type) {
        case "correct": file = "audio/correct.mp3"; break;
        case "wrong": file = "audio/wrong.mp3"; break;
        case "streak": file = "audio/streak.mp3"; break;
        case "gameover": file = "audio/gameover.mp3"; break;
      }
      if (file.isNotEmpty) {
        await _sfxPlayer.stop();
        await _sfxPlayer.play(AssetSource(file), mode: PlayerMode.lowLatency);
      }
    } catch (_) {}
  }

  void updateTheme({String? scheme, String? bg, Brightness? brightness}) {
    if (scheme != null) _colorScheme = scheme;
    if (bg != null) _wallpaper = bg;
    if (brightness != null) _brightness = brightness;

    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('theme_scheme', _colorScheme);
      prefs.setString('theme_wallpaper', _wallpaper);
      prefs.setBool('theme_bright', _brightness == Brightness.dark);
    });

    if (_currentLobby != null) syncTvTheme();
    notifyListeners();
  }

  // --- SIGNALR & LOBBY ---
  Future<void> linkTv(String tvCode) async {
    final canon = tvCode.trim().toUpperCase();
    if (canon.isEmpty) return;
    _pendingTvCode = canon;
    _hostKey = _newHostKey();
    notifyListeners();
    if (_hubConnection == null || _hubConnection!.state != HubConnectionState.Connected) return;
    await _pairTvNow();
  }

  Future<void> _pairTvNow() async {
    if (_hubConnection == null) return;
    try {
      await _hubConnection!.invoke("PairTV", args: <Object>[_pendingTvCode!, _hostKey!]);
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = "TV pairing failed: $e";
      notifyListeners();
    }
  }

  Future<void> syncTvTheme() async {
    if (_hubConnection == null || _currentLobby == null) return;
    try {
      await _hubConnection!.invoke("SyncTheme", args: <Object>[_currentLobby!.code, _wallpaper, _bgMusic, _isMusicEnabled, _volume]);
    } catch (_) {}
  }

  Future<void> connect(String url) async {
  // If we already have a live connection, do nothing
  if (_hubConnection != null && _hubConnection!.state == HubConnectionState.Connected) {
    return;
  }

  // If we have a dead connection object, drop it so a clean retry is possible
  if (_hubConnection != null && _hubConnection!.state != HubConnectionState.Connected) {
    try { await _hubConnection!.stop(); } catch (_) {}
    _hubConnection = null;
  }

  _hubConnection = HubConnectionBuilder()
      .withUrl(url)
      .withAutomaticReconnect()
      .build();

  // (Re)register handlers
  _hubConnection!.on("game_created", _handleLobbyUpdate);
  _hubConnection!.on("game_joined", _handleLobbyUpdate);
  _hubConnection!.on("lobby_update", _handleLobbyUpdate);
  _hubConnection!.on("error", (args) {
    _errorMessage = args?[0]?.toString();
    notifyListeners();
  });

  _hubConnection!.on("game_started", (args) {
    if (args == null || args.isEmpty) return;
    _handleLobbyUpdate(args);
    _appState = AppState.quiz;
    _currentStreak = 0;
    if ((_currentLobby?.mode ?? "").toLowerCase() == "music") {
      stopMusic(notify: false);
    }
    notifyListeners();
  });

  _hubConnection!.on("new_round", (args) {
    if (args == null || args.isEmpty) return;
    final map = args[0] as Map<String, dynamic>;
    _handleLobbyUpdate(args);
    if (_currentLobby != null) _currentLobby!.currentQuestionIndex = map['questionIndex'] ?? 0;
    _appState = AppState.quiz;
    notifyListeners();
  });

  _hubConnection!.on("question_results", (args) {
    if (args == null || args.isEmpty) return;
    _lastResults = args[0] as Map<String, dynamic>;
    _handleStreakUpdate(_lastResults);
    _appState = AppState.results;
    notifyListeners();
  });

  _hubConnection!.on("game_over", (_) {
    _appState = AppState.gameOver;
    playSfx("gameover");
    notifyListeners();
  });

  _hubConnection!.on("lobby_deleted", (_) {
    _appState = AppState.welcome;
    _currentLobby = null;
    _hostKey = null;
    notifyListeners();
  });

  _hubConnection!.on("game_reset", (_) {
    _appState = AppState.lobby;
    _currentStreak = 0;
    notifyListeners();
  });

  try {
    await _hubConnection!.start();

    if (_pendingTvCode != null && _hostKey == null) _hostKey = _newHostKey();
    if (_pendingTvCode != null) await _pairTvNow();
  } catch (e) {
    // Critical: allow the UI to retry cleanly
    _errorMessage = e.toString();
    try { await _hubConnection!.stop(); } catch (_) {}
    _hubConnection = null;
    notifyListeners();
    rethrow;
  }
}



  void _handleStreakUpdate(Map<String, dynamic>? results) {
    if (results == null) return;
    final list = (results['results'] ?? []) as List;
    final myResult = list.firstWhere((r) => r['name'] == _myName, orElse: () => null);
    if (myResult != null) {
      if (myResult['correct'] == true) {
        _currentStreak++;
        playSfx(_currentStreak > 2 ? "streak" : "correct");
      } else {
        _currentStreak = 0;
        playSfx("wrong");
      }
    }
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
      if (_lobbyCompleter != null && !_lobbyCompleter!.isCompleted) _lobbyCompleter!.complete();
      notifyListeners();
    }
  }

  // Lobby actions
  Future<void> createLobby(String name, String avatar, String mode, int qCount, String cat, int timer, String diff, String customCode) async {
    if (_hubConnection == null) return;
    _myName = name;
    
    // ✅ FIX: Check mode before playing music
    if (mode.toLowerCase() == "music") {
      stopMusic();
    } else {
      initMusic();
    }

    _lobbyCompleter = Completer<void>();
    await _hubConnection!.invoke("CreateGame", args: <Object>[name, avatar, mode, qCount, cat, timer, diff, customCode, _hostKey ?? ""]);
    await _lobbyCompleter!.future.timeout(const Duration(seconds: 5), onTimeout: () => null);
    if (_currentLobby != null) { _appState = AppState.lobby; await syncTvTheme(); notifyListeners(); }
  }

  Future<void> joinLobby(String code, String name, String avatar) async {
    if (_hubConnection == null) return;
    _myName = name;
    initMusic();
    _lobbyCompleter = Completer<void>();
    await _hubConnection!.invoke("JoinGame", args: <Object>[code, name, avatar, false, _hostKey ?? ""]);
    await _lobbyCompleter!.future.timeout(const Duration(seconds: 5), onTimeout: () => null);
    if (_currentLobby != null) {
      _appState = AppState.lobby;
      // ✅ FIX: Check mode on join
      if (_currentLobby?.mode.toLowerCase() == "music") stopMusic();
      await syncTvTheme();
      notifyListeners();
    }
  }

  Future<void> leaveLobby() async {
    if (_hubConnection != null && _currentLobby != null) await _hubConnection!.invoke("LeaveLobby", args: <Object>[_currentLobby!.code]);
    _appState = AppState.welcome; _currentLobby = null; _hostKey = null; notifyListeners();
  }

  Future<void> updateSettings(String mode, int qCount, String cat, int timer, String diff) async {
    if (_currentLobby != null) await _hubConnection!.invoke("UpdateSettings", args: <Object>[_currentLobby!.code, mode, qCount, cat, timer, diff]);
  }
  
  Future<void> startGame() async { if (_currentLobby != null) await _hubConnection!.invoke("StartGame", args: <Object>[_currentLobby!.code]); }
  Future<void> submitAnswer(String answer, double time, int qIndex) async { if (_currentLobby != null) await _hubConnection!.invoke("SubmitAnswer", args: <Object>[_currentLobby!.code, qIndex, answer, time]); }
  Future<void> nextQuestion() async { if (_currentLobby != null) await _hubConnection!.invoke("NextQuestion", args: <Object>[_currentLobby!.code]); }
  Future<void> playAgain() async { if (_currentLobby != null) await _hubConnection!.invoke("PlayAgain", args: <Object>[_currentLobby!.code]); }
  Future<void> resetToLobby() async { if (_currentLobby != null) await _hubConnection!.invoke("ResetToLobby", args: <Object>[_currentLobby!.code]); }
  Future<void> toggleReady(bool isReady) async { if (_currentLobby != null) await _hubConnection!.invoke("ToggleReady", args: <Object>[_currentLobby!.code, isReady]); }
  Future<void> sendChat(String msg) async { if (_currentLobby != null) await _hubConnection!.invoke("PostChat", args: <Object>[_currentLobby!.code, msg]); }
}