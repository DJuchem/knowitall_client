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

  // ----------------------------
  // OPTION B (PAIRING SESSION)
  // ----------------------------
  // IMPORTANT: this is NOT a stable/persisted host key anymore.
  // We generate a NEW hostKey every time the phone pairs to a TV code.
  String? _hostKey;
  String get hostKey => _hostKey ?? "";

  // --- STATE ---
  AppState _appState = AppState.welcome;
  LobbyData? _currentLobby;
  Map<String, dynamic>? _lastResults;
  String? _errorMessage;

  // pairing
  String? _pendingTvCode; // canonical TV code (AAAA)
  String? get pendingTvCode => _pendingTvCode;

  String _myName = "Player";
  String _myAvatar = "assets/avatars/avatar_0.png";

  // ✅ STREAK & CHAT TRACKING
  int _currentStreak = 0;
  int _lastChatReadIndex = 0;

  // --- INDEPENDENT SETTINGS ---
  String _colorScheme = "Default";
  String _wallpaper = "assets/bg/background_default.webp";
  String _bgMusic = "assets/music/default.mp3";
  Brightness _brightness = Brightness.dark;

  bool _isMusicEnabled = false; // Off by default
  bool _isPlaying = false;
  double _volume = 0.5;

  // --- CENTRALIZED DATA ---
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
    "High Energy (Dubstep)": "assets/music/dubstep.mp3",
    "Dreamy Atmosphere": "assets/music/dreams.mp3",
    "Retro Terminal": "assets/music/terminal.mp3",
    "Deep Space": "assets/music/nebula.mp3",
    "Nature Sounds": "assets/music/forest_ambient.mp3",
    "Classical Focus": "assets/music/RondoAllegro.mp3",
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
    "Synthwave Sun": "assets/bg/synth.jpg",
  };

  // --- GETTERS ---
  AppState get appState => _appState;
  LobbyData? get lobby => _currentLobby;
  Map<String, dynamic>? get lastResults => _lastResults;
  String? get error => _errorMessage;

  String get myName => _myName;
  String get myAvatar => _myAvatar;

  bool get amIHost =>
      _currentLobby != null &&
      _currentLobby!.host.trim().toLowerCase() == _myName.trim().toLowerCase();

  String get currentScheme => _colorScheme;
  Color get themeColor => AppTheme.schemes[_colorScheme]?.primary ?? const Color(0xFFE91E63);

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

  // --- HOST KEY (PAIRING SESSION) ---
  String _newHostKey() {
    // No deps, robust enough, unique per pairing
    final now = DateTime.now().microsecondsSinceEpoch;
    final r = Random.secure().nextInt(1 << 30);
    return "HK_${now}_${r.toRadixString(16).toUpperCase()}";
  }

  // --- METHODS ---
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _myName = prefs.getString('username') ?? "Player";
    _myAvatar = prefs.getString('avatar') ?? "assets/avatars/avatar_0.png";

    if (prefs.containsKey('theme_scheme')) _colorScheme = prefs.getString('theme_scheme')!;
    if (prefs.containsKey('theme_wallpaper')) _wallpaper = prefs.getString('theme_wallpaper')!;
    if (prefs.containsKey('theme_music')) _bgMusic = prefs.getString('theme_music')!;

    if (prefs.containsKey('theme_bright')) {
      _brightness = prefs.getBool('theme_bright')! ? Brightness.dark : Brightness.light;
    }

    // IMPORTANT CHANGE:
    // We DO NOT restore a stable hostKey anymore.
    // Pairing creates a fresh hostKey each time.
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

  // ✅ MISSING METHOD RESTORED
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

 Future<void> stopMusic({bool notify = true}) async {
  try {
    await _musicPlayer.stop();
  } catch (_) {
    // ignore
  }
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

  void setAppState(AppState s) {
    if (_appState == s) return;
    _appState = s;
    notifyListeners();
  }

  // -----------------------------------------------------------
  // OPTION B: Pair TV => generate new hostKey each pairing
  // -----------------------------------------------------------
  Future<void> linkTv(String tvCode) async {
    final canon = tvCode.trim().toUpperCase();
    if (canon.isEmpty) {
      _errorMessage = "TV code is empty";
      notifyListeners();
      return;
    }

    _pendingTvCode = canon;

    // NEW: generate a new hostKey for THIS pairing session
    _hostKey = _newHostKey();

    notifyListeners();

    if (_hubConnection == null || _hubConnection!.state != HubConnectionState.Connected) {
      // not connected yet -> PairTV will be attempted after connect()
      return;
    }

    await _pairTvNow();
  }

  Future<void> _pairTvNow() async {
    if (_hubConnection == null) return;
    if (_pendingTvCode == null || _pendingTvCode!.trim().isEmpty) return;
    if (_hostKey == null || _hostKey!.trim().isEmpty) return;

    try {
      await _hubConnection!.invoke("PairTV", args: <Object>[_pendingTvCode!, _hostKey!]);
      // keep _pendingTvCode as "paired tv", no need to clear; Create/Join will use hostKey anyway
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      // do not clear; allow retry after reconnect
      _errorMessage = "TV pairing failed: $e";
      debugPrint("PairTV failed: $e");
      notifyListeners();
    }
  }

  Future<void> syncTvTheme() async {
    if (_hubConnection == null || _currentLobby == null) return;

    try {
      await _hubConnection!.invoke(
        "SyncTheme",
        args: <Object>[
          _currentLobby!.code,
          _wallpaper,
          _bgMusic,
          _isMusicEnabled, // host controls whether TV is allowed to play lobby music
          _volume,
        ],
      );
    } catch (_) {}
  }

  Future<void> connect(String url, {bool enableTvTrace = false}) async {
  if (_hubConnection != null) return;

  _hubConnection = HubConnectionBuilder()
      .withUrl(url)
      .withAutomaticReconnect()
      .build();

  _hubConnection!.on("game_created", _handleLobbyUpdate);
  _hubConnection!.on("game_joined", _handleLobbyUpdate);
  _hubConnection!.on("lobby_update", _handleLobbyUpdate);

  _hubConnection!.on("error", (args) {
    final msg = (args != null && args.isNotEmpty) ? args[0]?.toString() : "Unknown server error";
    _errorMessage = msg;
    notifyListeners();
  });

  _hubConnection!.on("tv_paired_success", (_) {
    _errorMessage = null;
    notifyListeners();
  });

  _hubConnection!.on("tv_attach_success", (args) {
    if (enableTvTrace) {
      debugPrint("TV attached: $args");
    }
  });

  if (enableTvTrace) {
    _hubConnection!.on("tv_trace", (args) {
      final String msg = (args != null && args.isNotEmpty && args[0] != null)
          ? args[0].toString()
          : "";
      if (msg.trim().isNotEmpty) {
        debugPrint("[tv_trace] $msg");
      }
    });
  }

  _hubConnection!.on("game_started", (args) {
    if (args == null || args.isEmpty) return;

    _handleLobbyUpdate(args);
    _appState = AppState.quiz;
    _currentStreak = 0;

    // If it is music quiz, stop lobby bg music WITHOUT forcing a provider rebuild mid-build
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
    _currentStreak = 0;
    _hostKey = null;
    notifyListeners();
  });

  _hubConnection!.on("game_reset", (_) {
    _appState = AppState.lobby;
    _currentStreak = 0;
    notifyListeners();
  });

  await _hubConnection!.start();

  // If user already entered TV code before connection completed, pair now.
  if (_pendingTvCode != null && _pendingTvCode!.trim().isNotEmpty) {
    if (_hostKey == null || _hostKey!.trim().isEmpty) {
      _hostKey = _newHostKey();
    }
    await _pairTvNow();
  }
}


  // ✅ STREAK CALCULATION LOGIC RESTORED
  void _handleStreakUpdate(Map<String, dynamic>? results) {
    if (results == null) return;
    final list = (results['results'] ?? []) as List;
    final myResult = list.firstWhere((r) => r['name'] == _myName, orElse: () => null);

    if (myResult != null) {
      final bool correct = myResult['correct'] == true;
      if (correct) {
        _currentStreak++;
        if (_currentStreak > 2) {
          playSfx("streak");
        } else {
          playSfx("correct");
        }
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

      if (_lobbyCompleter != null && !_lobbyCompleter!.isCompleted) {
        _lobbyCompleter!.complete();
      }

      notifyListeners();
    }
  }

  Future<void> createLobby(
      String name, String avatar, String mode, int qCount, String cat, int timer, String diff, String customCode) async {
    if (_hubConnection == null) return;

    _myName = name;

    // Lobby music is allowed only if enabled AND not in music quiz
    if (mode.toLowerCase() == "music") {
      stopMusic();
    } else {
      initMusic();
    }

    _lobbyCompleter = Completer<void>();

    // IMPORTANT: hostKey must be the pairing-session key.
    // If user didn't pair TV, hostKey will be empty => server won't attach any TV (expected).
    final hk = _hostKey ?? "";

    await _hubConnection!.invoke(
      "CreateGame",
      args: <Object>[name, avatar, mode, qCount, cat, timer, diff, customCode, hk],
    );

    await _lobbyCompleter!.future.timeout(const Duration(seconds: 5), onTimeout: () => null);

    if (_currentLobby != null) {
      _appState = AppState.lobby;

      // host syncs theme to TV (TV will still pause during music quiz)
      await syncTvTheme();
      notifyListeners();
    }
  }

  Future<void> joinLobby(String code, String name, String avatar) async {
    if (_hubConnection == null) return;

    _myName = name;

    // For join, we play lobby music only if enabled and (later) if lobby mode is not music.
    initMusic();

    _lobbyCompleter = Completer<void>();

    final hk = _hostKey ?? "";

    await _hubConnection!.invoke("JoinGame", args: <Object>[code, name, avatar, false, hk]);

    await _lobbyCompleter!.future.timeout(const Duration(seconds: 5), onTimeout: () => null);

    if (_currentLobby != null) {
      _appState = AppState.lobby;

      // If the lobby is music mode, immediately stop lobby bg music.
      if ((_currentLobby?.mode ?? "").toLowerCase() == "music") {
        stopMusic();
      }

      await syncTvTheme();
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

    // Pairing-session ends when host leaves lobby (clean slate)
    _hostKey = null;

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
