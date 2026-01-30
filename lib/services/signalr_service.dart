import 'package:signalr_netcore/signalr_client.dart';

class SignalRService {
  // ✅ Change: Nullable to prevent 'LateInitializationError' crashes
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

  Future<void> init(String url) async {
    // Prevent re-initializing if already connected
    if (_connection?.state == HubConnectionState.Connected) return;

    _connection = HubConnectionBuilder()
        .withUrl(url)
        .withAutomaticReconnect()
        .build();

    _connection?.on("lobby_update", (args) => onLobbyUpdate?.call(args?[0]));
    _connection?.on("game_created", (args) => onGameCreated?.call(args?[0]));
    _connection?.on("game_joined", (args) => onGameJoined?.call(args?[0]));
    _connection?.on("game_started", (args) => onGameStarted?.call(args?[0]));
    _connection?.on("new_round", (args) => onNewRound?.call(args?[0]));
    _connection?.on("question_results", (args) => onQuestionResults?.call(args?[0]));
    _connection?.on("game_over", (args) => onGameOver?.call(args?[0]));
    _connection?.on("game_reset", (args) => onGameReset?.call(args?[0]));
    _connection?.on("lobby_deleted", (args) => onLobbyDeleted?.call(args?[0]));
    _connection?.on("error", (args) => onError?.call(args?[0]));

    await _connection?.start();
  }

  // ✅ Helper: Safely invokes methods, throwing a readable error if disconnected
  Future<void> _invoke(String methodName, List<Object>? args) async {
    if (_connection == null || _connection!.state != HubConnectionState.Connected) {
      throw Exception("Connection lost. Please restart or check internet.");
    }
    await _connection!.invoke(methodName, args: args);
  }

  Future<void> createGame(
    String hostName,
    String hostAvatar,
    String mode,
    int questionCount,
    String category,
    int timer,
    String difficulty,
    String customCode,
  ) async {
    await _invoke("CreateGame", [
      hostName,
      hostAvatar,
      mode,
      questionCount,
      category,
      timer,
      difficulty,
      customCode
    ]);
  }

  Future<void> joinGame(String code, String name, String avatar, bool isHost) async {
    await _invoke("JoinGame", [code, name, avatar, isHost]);
  }

  Future<void> updateSettings(String code, String mode, int questionCount, String category, int timer, String difficulty) async {
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
      // Ignore errors when leaving (e.g. if already disconnected)
    }
  }

  Future<void> playAgain(String code) async {
    await _invoke("PlayAgain", [code]);
  }

  Future<void> resetToLobby(String code) async {
    await _invoke("ResetToLobby", [code]);
  }
}