import 'package:signalr_netcore/signalr_client.dart';

class SignalRService {
  HubConnection? _connection;

  Function(dynamic)? onLobbyUpdate;
  Function(dynamic)? onGameCreated;
  Function(dynamic)? onGameJoined;
  Function(dynamic)? onGameStarted;
  Function(dynamic)? onNewRound;
  Function(dynamic)? onQuestionResults;
  Function(dynamic)? onGameOver;
  Function(dynamic)? onGameReset;
  Function(dynamic)? onLobbyDeleted;
  Function(dynamic)? onError;

  // Optional debug hooks (useful for TV Option B)
  Function(dynamic)? onTvPairedSuccess;
  Function(dynamic)? onTvTrace;
  Function(dynamic)? onTvAttachSuccess;

  Future<void> init(String url) async {
    if (_connection?.state == HubConnectionState.Connected) return;

    _connection = HubConnectionBuilder()
        .withUrl(url)
        .withAutomaticReconnect()
        .build();

    _connection?.on("lobby_update", (args) => onLobbyUpdate?.call(args != null && args.isNotEmpty ? args[0] : null));
    _connection?.on("game_created", (args) => onGameCreated?.call(args != null && args.isNotEmpty ? args[0] : null));
    _connection?.on("game_joined", (args) => onGameJoined?.call(args != null && args.isNotEmpty ? args[0] : null));
    _connection?.on("game_started", (args) => onGameStarted?.call(args != null && args.isNotEmpty ? args[0] : null));
    _connection?.on("new_round", (args) => onNewRound?.call(args != null && args.isNotEmpty ? args[0] : null));
    _connection?.on("question_results", (args) => onQuestionResults?.call(args != null && args.isNotEmpty ? args[0] : null));
    _connection?.on("game_over", (args) => onGameOver?.call(args != null && args.isNotEmpty ? args[0] : null));
    _connection?.on("game_reset", (args) => onGameReset?.call(args != null && args.isNotEmpty ? args[0] : null));
    _connection?.on("lobby_deleted", (args) => onLobbyDeleted?.call(args != null && args.isNotEmpty ? args[0] : null));
    _connection?.on("error", (args) => onError?.call(args != null && args.isNotEmpty ? args[0] : null));

    // Option B debug/events (safe to have even if server doesn’t send them)
    _connection?.on("tv_paired_success", (args) => onTvPairedSuccess?.call(args != null && args.isNotEmpty ? args[0] : null));
    _connection?.on("tv_trace", (args) => onTvTrace?.call(args != null && args.isNotEmpty ? args[0] : null));
    _connection?.on("tv_attach_success", (args) => onTvAttachSuccess?.call(args != null && args.isNotEmpty ? args[0] : null));

    await _connection?.start();
  }

  Future<void> _invoke(String methodName, List<Object>? args) async {
    if (_connection == null || _connection!.state != HubConnectionState.Connected) {
      throw Exception("Connection lost. Please restart or check internet.");
    }
    await _connection!.invoke(methodName, args: args);
  }

  // -------------------------
  // OPTION B: TV pairing
  // -------------------------
  Future<void> pairTv(String tvCode, String hostKey) async {
    await _invoke("PairTV", [tvCode.trim().toUpperCase(), hostKey.trim()]);
  }

  Future<void> syncTheme(
    String lobbyCode,
    String wallpaper,
    String music,
    bool musicEnabled,
    double volume,
  ) async {
    await _invoke("SyncTheme", [lobbyCode, wallpaper, music, musicEnabled, volume]);
  }

  // -------------------------
  // Lobby lifecycle
  // -------------------------
  Future<void> createGame(
    String hostName,
    String hostAvatar,
    String mode,
    int questionCount,
    String category,
    int timer,
    String difficulty,
    String customCode,
    String hostKey, // ✅ NEW (Option B)
  ) async {
    await _invoke("CreateGame", [
      hostName,
      hostAvatar,
      mode,
      questionCount,
      category,
      timer,
      difficulty,
      customCode,
      hostKey, // ✅ server expects this as last arg
    ]);
  }

  Future<void> joinGame(
    String code,
    String name,
    String avatar,
    bool spectator, // ✅ rename: this is spectator, not isHost
    String hostKey,  // ✅ NEW (Option B)
  ) async {
    await _invoke("JoinGame", [
      code,
      name,
      avatar,
      spectator, // ✅ server expects spectator bool here
      hostKey,   // ✅ then hostKey
    ]);
  }

  Future<void> updateSettings(
    String code,
    String mode,
    int questionCount,
    String category,
    int timer,
    String difficulty,
  ) async {
    await _invoke("UpdateSettings", [code, mode, questionCount, category, timer, difficulty]);
  }

  Future<void> toggleReady(String code, bool isReady) async {
    await _invoke("ToggleReady", [code, isReady]);
  }

  Future<void> startGame(String code) async {
    await _invoke("StartGame", [code]);
  }

  Future<void> submitAnswer(String code, int questionId, String answer, double time) async {
    await _invoke("SubmitAnswer", [code, questionId, answer, time]);
  }

  Future<void> nextQuestion(String code) async {
    await _invoke("NextQuestion", [code]);
  }

  Future<void> postChat(String code, String msg) async {
    await _invoke("PostChat", [code, msg]);
  }

  Future<void> leaveLobby(String code) async {
    try {
      await _invoke("LeaveLobby", [code]);
    } catch (_) {
      // ignore
    }
  }

  Future<void> playAgain(String code) async {
    await _invoke("PlayAgain", [code]);
  }

  Future<void> resetToLobby(String code) async {
    await _invoke("ResetToLobby", [code]);
  }
}
