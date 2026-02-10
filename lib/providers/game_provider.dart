import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lobby_data.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

// 🟢 MODEL: Rich Game Mode Definition
class GameModeDefinition {
  final String id;
  final String label;
  final String asset;
  final IconData icon;
  final Color color;

  const GameModeDefinition({
    required this.id,
    required this.label,
    required this.asset,
    required this.icon,
    required this.color,
  });
}

class GameConfig {
  String appTitle;
  String logoPath;
  GameConfig({
    this.appTitle = "KNOW IT ALL",
    this.logoPath = "logo2.png", 
  });
}

enum AppState { welcome, create, lobby, quiz, results, gameOver }

class GameProvider extends ChangeNotifier {
  // --- SERVICES ---
  HubConnection? _hubConnection;
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final GameConfig config = GameConfig();
  final AuthService _authService = AuthService();
  
  Completer<void>? _lobbyCompleter;
  
  // --- USER DATA ---
  int _myUserId = 0; 
  String? _authToken;
  String _myName = "Player";
  String _myAvatar = "assets/avatars/avatar_0.png";
  
  // --- PAIRING ---
  String? _hostKey;
  String? _pendingTvCode;

  // --- STATE ---
  AppState _appState = AppState.welcome;
  LobbyData? _currentLobby;
  Map<String, dynamic>? _lastResults;
  String? _errorMessage;
  int _currentStreak = 0;
  int _lastChatReadIndex = 0;

  // --- SETTINGS ---
  String _colorScheme = "Default";
  String _wallpaper = "assets/bg/background_default.webp"; 
  String _bgMusic = "assets/music/background-music.mp3";
  Brightness _brightness = Brightness.dark;
  bool _isMusicEnabled = false; 
  bool _isPlaying = false;
  double _volume = 0.5;

  // 🟢 1. MASTER MODE LIST (Fixes "Missing Modes")
  final List<GameModeDefinition> availableModes = [
    GameModeDefinition(id: "general-knowledge", label: "General Knowledge", asset: "assets/modes/general.png", icon: Icons.school_rounded, color: Colors.blueAccent),
    GameModeDefinition(id: "music", label: "Music Quiz", asset: "assets/modes/music.png", icon: Icons.music_note_rounded, color: Colors.pinkAccent),
    GameModeDefinition(id: "calculations", label: "Math Chaos", asset: "assets/modes/math.png", icon: Icons.calculate_rounded, color: Colors.orangeAccent),
    GameModeDefinition(id: "image", label: "Images", asset: "assets/modes/image.png", icon: Icons.image_rounded, color: Colors.purpleAccent),
    GameModeDefinition(id: "flags", label: "Guess the Flag", asset: "assets/modes/flags.png", icon: Icons.flag_rounded, color: Colors.redAccent),
    GameModeDefinition(id: "capitals", label: "Capitals", asset: "assets/modes/capitals.png", icon: Icons.location_city_rounded, color: Colors.deepPurpleAccent),
    GameModeDefinition(id: "odd_one_out", label: "Odd One Out", asset: "assets/modes/odd.png", icon: Icons.rule_rounded, color: Colors.greenAccent),
    GameModeDefinition(id: "fill_in_the_blank", label: "Fill The Blank", asset: "assets/modes/fill.png", icon: Icons.text_fields_rounded, color: Colors.tealAccent),
    GameModeDefinition(id: "true_false", label: "True / False", asset: "assets/modes/tf.png", icon: Icons.check_circle_outline, color: Colors.cyanAccent),
    GameModeDefinition(id: "population", label: "Population", asset: "assets/modes/pop.png", icon: Icons.groups_rounded, color: Colors.indigoAccent),
    GameModeDefinition(id: "star_trek", label: "Star Trek", asset: "assets/modes/startrek.png", icon: Icons.rocket_launch_rounded, color: Colors.blueGrey),
    GameModeDefinition(id: "kpop", label: "K-Pop", asset: "assets/modes/kpop.png", icon: Icons.queue_music_rounded, color: Colors.pink),
    GameModeDefinition(id: "thai_culture", label: "Thai Culture", asset: "assets/modes/thai.png", icon: Icons.temple_buddhist_rounded, color: Colors.amber),
  ];

  // 🟢 2. CONFIG OPTIONS (Fixes "Undefined Getter" errors)
  final Map<String, String> musicOptions = {
    "KnowItAll": "assets/music/background-music.mp3",
    "KnowItAll II": "assets/music/default.mp3",
    "Chill Lo-Fi": "assets/music/synth.mp3",
    "High Energy": "assets/music/dubstep.mp3",
    "Dreamy": "assets/music/dreams.mp3",
    "Millionaire": "assets/music/millionaire1.mp3",
    "Space": "assets/music/space.mp3",
    "Funky": "assets/music/pink.mp3",
    "Hell March": "assets/music/hellmarch.mp3",
    "Super Metroid": "assets/music/metroid.mp3",
    "Classical": "assets/music/RondoAllegro.mp3",
    "Jazz Fusion": "assets/music/DaveWecklBand.mp3",
  };

  final Map<String, String> wallpaperOptions = {
    "KnowItAll": "assets/bg/background_default.webp",
    "Neon City": "assets/bg/cyberpunk.jpg",
    "Digital Rain": "assets/bg/matrix_rain.jpg",
    "Deep Galaxy": "assets/bg/galaxy.jpg",
    "Volcanic": "assets/bg/magma.jpg",
    "Mystic Mountain": "assets/bg/dark.png",
    "Hentai": "assets/bg/hentai6.jpg",
    "Hentai II": "assets/bg/hentai10.jpg",
    "Synthwave": "assets/bg/synth.jpg",
  };

  // Helper to find mode details
  GameModeDefinition getMode(String id) {
    return availableModes.firstWhere(
      (m) => m.id == id, 
      orElse: () => availableModes.first
    );
  }

  // --- GETTERS ---
  AppState get appState => _appState;
  LobbyData? get lobby => _currentLobby;
  Map<String, dynamic>? get lastResults => _lastResults;
  String? get error => _errorMessage;
  String get myName => _myName;
  String get myAvatar => _myAvatar;
  int get myUserId => _myUserId;
  bool get isLoggedIn => _authToken != null;
  bool get amIHost => _currentLobby != null && _currentLobby!.host.trim().toLowerCase() == _myName.trim().toLowerCase();
  
  String get currentScheme => _colorScheme;
  Color get themeColor => AppTheme.schemes[_colorScheme]?.primary ?? const Color(0xFFE91E63);
  String get wallpaper => _wallpaper;
  String get currentMusic => _bgMusic;
  bool get isMusicEnabled => _isMusicEnabled;
  bool get isMusicPlaying => _isPlaying;
  int get currentStreak => _currentStreak;
  Brightness get brightness => _brightness;
  int get unreadCount => _currentLobby == null ? 0 : (_currentLobby!.chat.length - _lastChatReadIndex).clamp(0, 99);
  String get hostKey => _hostKey ?? "";
  String? get pendingTvCode => _pendingTvCode;

  GameProvider() {
    _loadUser();
  }

  // --- METHODS ---

  void setAppState(AppState s) {
    if (_appState == s) return;
    _appState = s;
    notifyListeners();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    _myUserId = prefs.getInt('user_id') ?? 0; 
    _myName = prefs.getString('username') ?? "Player";
    _myAvatar = prefs.getString('avatar') ?? "assets/avatars/avatar_0.png";

    if (_authToken != null && _myUserId == 0) {
       logout(); // Call regular logout, don't await void
       return;
    }

    if (prefs.containsKey('theme_scheme')) _colorScheme = prefs.getString('theme_scheme')!;
    if (prefs.containsKey('theme_wallpaper')) _wallpaper = prefs.getString('theme_wallpaper')!;
    if (prefs.containsKey('theme_music')) _bgMusic = prefs.getString('theme_music')!;
    if (prefs.containsKey('theme_bright')) _brightness = prefs.getBool('theme_bright')! ? Brightness.dark : Brightness.light;

    await _ensureHostKey();
    notifyListeners();
  }

  Future<void> login(String loginIdentifier, String password) async {
    try {
      final data = await _authService.login(loginIdentifier, password);
      _myUserId = data['userId'] ?? data['UserId'] ?? 0;
      _authToken = data['token'];
      _myName = data['username'];
      _myAvatar = data['avatar'];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _authToken!);
      await prefs.setString('username', _myName);
      await prefs.setString('avatar', _myAvatar);
      await prefs.setInt('user_id', _myUserId); 
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  void logout() async {
    _authToken = null;
    _myUserId = 0;
    _myName = "Guest";
    _myAvatar = "assets/avatars/avatar_0.png";
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    notifyListeners();
  }

  Future<void> register(String username, String email, String password, String avatar) async {
    await _authService.register(username, email, password, avatar);
  }

  Future<Map<String, dynamic>> getMyStats() async {
    if (_myUserId == 0) return {};
    return await _authService.getUserStats(_myUserId);
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

  Future<void> updateAvatarOnServer(String newAvatarPath) async {
    if (!isLoggedIn) return;
    try {
      await _authService.updateAvatar(_myUserId, newAvatarPath);
      _myAvatar = newAvatarPath;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('avatar', _myAvatar);
      notifyListeners();
    } catch (e) {
      debugPrint("Avatar update failed: $e");
    }
  }

  String _newHostKey() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final r = Random.secure().nextInt(1 << 30);
    return "HK_${now}_${r.toRadixString(16).toUpperCase()}";
  }

  Future<void> _ensureHostKey() async {
    if (_hostKey != null && _hostKey!.trim().isNotEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('host_key');
    if (existing != null && existing.trim().isNotEmpty) {
      _hostKey = existing.trim();
      return;
    }
    _hostKey = _newHostKey();
    await prefs.setString('host_key', _hostKey!);
  }

  Future<void> initMusic() async {
    if (!_isMusicEnabled) return;
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
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> stopMusic({bool notify = true}) async {
    try { await _musicPlayer.stop(); } catch (_) {}
    _isPlaying = false;
    if (notify) notifyListeners();
  }

  void toggleMusic(bool enable) {
    _isMusicEnabled = enable;
    if (enable) initMusic(); else stopMusic();
    notifyListeners();
  }

  void setMusicTrack(String track) {
    _bgMusic = track;
    SharedPreferences.getInstance().then((prefs) => prefs.setString('theme_music', track));
    if (_isMusicEnabled) {
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

  // 🟢 3. THEME UPDATE METHOD (Fixes "Undefined Method" error)
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
  Future<void> connect(String url) async {
    if (_hubConnection != null && _hubConnection!.state == HubConnectionState.Connected) return;
    if (_hubConnection != null) {
      try { await _hubConnection!.stop(); } catch (_) {}
      _hubConnection = null;
    }
    _hubConnection = HubConnectionBuilder().withUrl(url).withAutomaticReconnect().build();

    _hubConnection!.on("game_created", _handleLobbyUpdate);
    _hubConnection!.on("game_joined", _handleLobbyUpdate);
    _hubConnection!.on("lobby_update", _handleLobbyUpdate);
    _hubConnection!.on("error", (args) { _errorMessage = args?[0]?.toString(); notifyListeners(); });

    _hubConnection!.on("game_started", (args) {
      if (args == null || args.isEmpty) return;
      _handleLobbyUpdate(args);
      _appState = AppState.quiz;
      _currentStreak = 0;
      if ((_currentLobby?.mode ?? "").toLowerCase() == "music") stopMusic(notify: false);
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
      await _ensureHostKey();
      if (_pendingTvCode != null) {
        await _pairTvNow();
        await syncTvTheme();
      }
    } catch (e) {
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

  // LOBBY ACTIONS
  Future<void> createLobby(String name, String avatar, String mode, int qCount, String cat, int timer, String diff, String customCode) async {
    if (_hubConnection == null) return;
    _myName = name;
    if (mode.toLowerCase() == "music") stopMusic(); else initMusic();
    _lobbyCompleter = Completer<void>();
    await _hubConnection!.invoke("CreateGame", args: <Object>[
      name, avatar, mode, qCount, cat, timer, diff, customCode, _hostKey ?? "", _myUserId
    ]);
    await _lobbyCompleter!.future.timeout(const Duration(seconds: 5), onTimeout: () => null);
    if (_currentLobby != null) { _appState = AppState.lobby; await syncTvTheme(); notifyListeners(); }
  }

  Future<void> joinLobby(String code, String name, String avatar) async {
    if (_hubConnection == null) return;
    _myName = name;
    initMusic();
    _lobbyCompleter = Completer<void>();
    await _hubConnection!.invoke("JoinGame", args: <Object>[
      code, name, avatar, false, _hostKey ?? "", _myUserId
    ]);
    await _lobbyCompleter!.future.timeout(const Duration(seconds: 5), onTimeout: () => null);
    if (_currentLobby != null) {
      _appState = AppState.lobby;
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
  
  void markChatAsRead() {
    if (_currentLobby != null) {
      _lastChatReadIndex = _currentLobby!.chat.length;
      notifyListeners();
    }
  }

  // TV Pairing
  Future<void> linkTv(String tvCode) async {
    final canon = tvCode.trim().toUpperCase();
    if (canon.isEmpty) return;
    _pendingTvCode = canon;
    await _ensureHostKey();
    notifyListeners();
    if (_hubConnection != null && _hubConnection!.state == HubConnectionState.Connected) {
      await _pairTvNow();
      await syncTvTheme();
    }
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

  // 🟢 4. SYNC METHOD (Fixes "Undefined Method" error)
  Future<void> syncTvTheme() async {
    if (_hubConnection == null || _currentLobby == null) return;
    try {
      await _hubConnection!.invoke("SyncTheme", args: <Object>[_currentLobby!.code, _wallpaper, _bgMusic, _isMusicEnabled, _volume]);
    } catch (_) {}
  }
}