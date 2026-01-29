import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

class SignalRService {
  HubConnection? _hubConnection;

  // Events
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
    if (_hubConnection?.state == HubConnectionState.Connected) return;

    _hubConnection = HubConnectionBuilder()
        .withUrl(url, options: HttpConnectionOptions(
            skipNegotiation: true, // Force WebSockets on Web to avoid some CORS pre-flight issues
            transport: HttpTransportType.WebSockets
        ))
        .withAutomaticReconnect()
        .build();

    _hubConnection?.onclose(({Exception? error}) {
      debugPrint("SignalR Connection Closed: $error");
      onError?.call("Disconnected from server.");
    });

    // Register Listeners
    _hubConnection?.on("lobby_update", (args) => onLobbyUpdate?.call(args![0]));
    _hubConnection?.on("game_created", (args) => onGameCreated?.call(args![0]));
    _hubConnection?.on("game_joined", (args) => onGameJoined?.call(args![0]));
    _hubConnection?.on("game_started", (args) => onGameStarted?.call(args![0]));
    _hubConnection?.on("new_round", (args) => onNewRound?.call(args![0]));
    _hubConnection?.on("question_results", (args) => onQuestionResults?.call(args![0]));
    _hubConnection?.on("game_over", (args) => onGameOver?.call(args![0]));
    _hubConnection?.on("game_reset", (args) => onGameReset?.call(null));
    _hubConnection?.on("lobby_deleted", (args) => onLobbyDeleted?.call(null));

    // Start Connection
    try {
      await _hubConnection?.start();
      debugPrint("SignalR Connected ID: ${_hubConnection?.connectionId}");
    } catch (e) {
      debugPrint("SignalR Connection Failed: $e");
      rethrow; // Pass error to Provider to show UI message
    }
  }

  // Invokers
  Future<void> createGame(String n, String m, int q, String c, int t, String d, String code) async {
    await _hubConnection?.invoke("CreateGame", args: [n, m, q, c, t, d, code]);
  }

  Future<void> joinGame(String code, String name, String avatar, bool spectator) async {
    await _hubConnection?.invoke("JoinGame", args: [code, name, avatar, spectator]);
  }

  Future<void> updateSettings(String code, String m, int q, String c, int t, String d) async {
    await _hubConnection?.invoke("UpdateSettings", args: [code, m, q, c, t, d]);
  }

  Future<void> startGame(String code) async => await _hubConnection?.invoke("StartGame", args: [code]);
  Future<void> nextQuestion(String code) async => await _hubConnection?.invoke("NextQuestion", args: [code]);
  Future<void> submitAnswer(String code, int qId, String ans, double time) async => await _hubConnection?.invoke("SubmitAnswer", args: [code, qId, ans, time]);
  Future<void> postChat(String code, String msg) async => await _hubConnection?.invoke("PostChat", args: [code, msg]);
  Future<void> toggleReady(String code, bool isReady) async => await _hubConnection?.invoke("ToggleReady", args: [code, isReady]);
  Future<void> leaveLobby(String code) async => await _hubConnection?.invoke("LeaveLobby", args: [code]);
  Future<void> playAgain(String code) async => await _hubConnection?.invoke("PlayAgain", args: [code]);
  Future<void> resetToLobby(String code) async => await _hubConnection?.invoke("ResetToLobby", args: [code]);
}