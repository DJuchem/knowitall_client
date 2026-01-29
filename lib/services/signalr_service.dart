import 'package:signalr_netcore/signalr_client.dart';

class SignalRService {
  HubConnection? _hubConnection;

  Function(dynamic)? onLobbyUpdate;
  Function(dynamic)? onGameCreated;
  Function(dynamic)? onGameJoined;
  Function(dynamic)? onGameStarted;
  Function(dynamic)? onNewRound;
  Function(dynamic)? onQuestionResults;
  Function(dynamic)? onGameOver;
  Function(dynamic)? onGameReset;
  Function(dynamic)? onLobbyDeleted;
  Function(dynamic)? onAnswerSubmitted;
  Function(dynamic)? onError;

  Future<void> init(String url) async {
    _hubConnection = HubConnectionBuilder().withUrl(url).build();

 _hubConnection?.onclose(({Exception? error}) {
  onError?.call("Connection closed: ${error?.toString() ?? 'no error'}");
});

    _hubConnection?.on("lobby_update", (args) => onLobbyUpdate?.call(args![0]));
    _hubConnection?.on("game_created", (args) => onGameCreated?.call(args![0]));
    _hubConnection?.on("game_joined", (args) => onGameJoined?.call(args![0]));
    _hubConnection?.on("game_started", (args) => onGameStarted?.call(args![0]));
    _hubConnection?.on("new_round", (args) => onNewRound?.call(args![0]));
    _hubConnection?.on("question_results", (args) => onQuestionResults?.call(args![0]));
    _hubConnection?.on("game_over", (args) => onGameOver?.call(args![0]));
    _hubConnection?.on("game_reset", (args) => onGameReset?.call(args));
    _hubConnection?.on("lobby_deleted", (args) => onLobbyDeleted?.call(args));
    _hubConnection?.on("answer_submitted", (args) => onAnswerSubmitted?.call(args![0]));
    _hubConnection?.on("error", (args) => onError?.call(args![0]));

    await _hubConnection?.start();
  }

  // --- ACTIONS ---

  Future<void> createGame(String name, String mode, int qCount, String category, int timer, String difficulty, String customCode) async {
    await _hubConnection?.invoke("CreateGame", args: [name, mode, qCount, category, timer, difficulty, customCode]);
  }

  Future<void> joinGame(String code, String name, String avatar, bool spectator) async {
    await _hubConnection?.invoke("JoinGame", args: [code, name, avatar, spectator]);
  }

  Future<void> updateSettings(String code, String mode, int timer, String difficulty) async {
    await _hubConnection?.invoke("UpdateSettings", args: [code, mode, timer, difficulty]);
  }

  Future<void> startGame(String code) async { await _hubConnection?.invoke("StartGame", args: [code]); }
  Future<void> nextQuestion(String code) async { await _hubConnection?.invoke("NextQuestion", args: [code]); }
  Future<void> submitAnswer(String code, int qIndex, String answer, double time) async { await _hubConnection?.invoke("SubmitAnswer", args: [code, qIndex, answer, time]); }
  Future<void> postChat(String code, String msg) async { await _hubConnection?.invoke("PostChat", args: [code, msg]); }
  Future<void> toggleReady(String code, bool isReady) async { await _hubConnection?.invoke("ToggleReady", args: [code, isReady]); }
  Future<void> leaveLobby(String code) async { await _hubConnection?.invoke("LeaveLobby", args: [code]); }
  Future<void> playAgain(String code) async { await _hubConnection?.invoke("PlayAgain", args: [code]); }
  Future<void> resetToLobby(String code) async { await _hubConnection?.invoke("ResetToLobby", args: [code]); }
}