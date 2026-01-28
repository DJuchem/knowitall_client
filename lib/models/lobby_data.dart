import 'dart:convert';

class LobbyData {
  String code;
  String host;
  bool started;
  List<Player> players;
  List<ChatMessage> chat;
  int timer;
  List<dynamic> quizData; 
  int currentQuestionIndex;

  LobbyData({
    required this.code,
    required this.host,
    this.started = false,
    this.players = const [],
    this.chat = const [],
    this.timer = 0,
    this.quizData = const [],
    this.currentQuestionIndex = 0,
  });

  factory LobbyData.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse the Quiz JSON list
    List<dynamic> parseQuizData(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw;
      if (raw is String) {
        try { return jsonDecode(raw); } catch (_) { return []; }
      }
      return [];
    }

    return LobbyData(
      code: json['code'] ?? '',
      host: json['host'] ?? '',
      started: json['started'] ?? false,
      players: (json['players'] as List? ?? []).map((e) => Player.fromJson(e)).toList(),
      chat: (json['chat'] as List? ?? []).map((e) => ChatMessage.fromJson(e)).toList(),
      timer: json['timer'] ?? 0,
      quizData: parseQuizData(json['quizData'] ?? json['QuizDataJson']), // Handle both keys
      currentQuestionIndex: json['currentQuestionIndex'] ?? json['questionIndex'] ?? 0,
    );
  }
}

class Player {
  String name;
  int score;
  bool isOnline;
  bool isSpectator;

  Player({required this.name, this.score = 0, this.isOnline = true, this.isSpectator = false});

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      name: json['name'] ?? 'Unknown',
      score: json['score'] ?? 0,
      isOnline: json['online'] ?? json['isOnline'] ?? true,
      isSpectator: json['spectator'] ?? false,
    );
  }
}

class ChatMessage {
  String from;
  String text;
  ChatMessage({required this.from, required this.text});
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(from: json['from'] ?? '?', text: json['text'] ?? '');
  }
}