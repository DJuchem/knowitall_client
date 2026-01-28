import 'package:signalr_netcore/signalr_client.dart';

class SignalRService {
  late HubConnection _hubConnection;
  
  // Events
  Function(dynamic)? onGameCreated;
  Function(dynamic)? onGameJoined;
  Function(dynamic)? onLobbyUpdate;
  Function(dynamic)? onGameStarted;
  Function(dynamic)? onError;
  Function(dynamic)? onQuestionResults;

  Future<void> init(String serverUrl) async {
    _hubConnection = HubConnectionBuilder()
        .withUrl(serverUrl)
        .withAutomaticReconnect()
        .build();

    _registerHubHandlers();

    await _hubConnection.start();
    print("SignalR Connected with ID: ${_hubConnection.connectionId}");
  }

  void _registerHubHandlers() {
    _hubConnection.on("game_created", (args) => onGameCreated?.call(args![0]));
    _hubConnection.on("game_joined", (args) => onGameJoined?.call(args![0]));
    _hubConnection.on("lobby_update", (args) => onLobbyUpdate?.call(args![0]));
    _hubConnection.on("game_started", (args) => onGameStarted?.call(args![0]));
    _hubConnection.on("error", (args) => onError?.call(args![0]));
    _hubConnection.on("question_results", (args) => onQuestionResults?.call(args![0]));
  }

  // --- ACTIONS ---
Future<void> createGame(String name, String mode, int qCount, String category, String difficulty) async {
    // 7 Arguments matching C# Hub
    await _hubConnection.invoke("CreateGame", args: [
      name, 
      mode, 
      qCount, 
      category, 
      30, 
      difficulty, 
      ""
    ]);
  }

  Future<void> startGame(String code) async {
    await _hubConnection.invoke("StartGame", args: [code]);
  }
  Future<void> joinGame(String code, String name) async {
    await _hubConnection.invoke("JoinGame", args: [code, name, "avatar1.webp", false]);
  }

  Future<void> postChat(String code, String msg) async {
    await _hubConnection.invoke("PostChat", args: [code, msg]);
  }

  Future<void> nextQuestion(String code) async {
  await _hubConnection.invoke("NextQuestion", args: [code]);
}

Future<void> submitAnswer(String code, int qIndex, String answer, double time) async {
    // Matches Hub: SubmitAnswer(string lobbyCode, int questionIndex, string answer, double time)
    await _hubConnection.invoke("SubmitAnswer", args: [code, qIndex, answer, time]);
  }
}