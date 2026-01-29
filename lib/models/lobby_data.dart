import 'dart:convert';

class LobbyData {
  String code;
  String host;
  List<Player> players;
  List<Player> spectators;
  List<ChatMessage> chat;
  bool started;
  String mode;
  int timer;
  String? difficulty;
  int currentQuestionIndex; 
  List<dynamic>? quizData;

  LobbyData({
    required this.code,
    required this.host,
    required this.players,
    required this.spectators,
    required this.chat,
    required this.started,
    required this.mode,
    required this.timer,
    this.difficulty,
    required this.currentQuestionIndex,
    this.quizData,
  });

  factory LobbyData.fromJson(Map<String, dynamic> json) {
    var pList = json['players'] as List? ?? [];
    var sList = json['spectators'] as List? ?? [];
    var cList = json['chat'] as List? ?? [];

    return LobbyData(
      code: json['code'] ?? '',
      host: json['host'] ?? '',
      players: pList.map((i) => Player.fromJson(i)).toList(),
      spectators: sList.map((i) => Player.fromJson(i)).toList(),
      chat: cList.map((i) => ChatMessage.fromJson(i)).toList(),
      started: json['started'] ?? false,
      mode: json['mode'] ?? 'unknown',
      timer: json['timer'] ?? 30,
      difficulty: json['difficulty'],
      currentQuestionIndex: json['questionIndex'] ?? 0, 
      quizData: json['quizData'],
    );
  }
}

class Player {
  String name;
  int score;
  bool isOnline;
  bool isReady;
  String? avatar;

  Player({
    required this.name, 
    required this.score, 
    required this.isOnline, 
    required this.isReady, 
    this.avatar
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      name: json['name'] ?? 'Unknown',
      score: json['score'] ?? 0,
      isOnline: json['online'] ?? false,
      isReady: json['ready'] ?? false, 
      avatar: json['avatar'],
    );
  }
}

class ChatMessage {
  String from;
  String text;
  String? avatar;

  ChatMessage({required this.from, required this.text, this.avatar});

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      from: json['from'] ?? '?',
      text: json['text'] ?? '',
      avatar: json['avatar'],
    );
  }
}