import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AuthService {
  String get _baseUrl {
    if (kIsWeb) {
      if (kReleaseMode) return "${Uri.base.scheme}://${Uri.base.host}${Uri.base.hasPort ? ':${Uri.base.port}' : ''}/api/auth";
      return "http://127.0.0.1:5074/api/auth";
    }
    return "http://10.0.2.2:5074/api/auth";
  }

Future<List<dynamic>> getLeaderboard() async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/leaderboard"));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return [];
  }
  
  // inside AuthService class
Future<void> updateAvatar(int userId, String newAvatar) async {
  await http.post(
    Uri.parse("$_baseUrl/avatar"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"userId": userId, "avatar": newAvatar}),
  );
}

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      // Try to parse server error message
      String msg = "Login failed";
      try {
        final err = jsonDecode(response.body);
        msg = err['message'] ?? err['title'] ?? msg; // ASP.NET often sends 'title' or custom 'message'
      } catch (_) {
        msg = response.body; // Fallback to raw text
      }
      throw Exception(msg);
    }
  }

Future<Map<String, dynamic>> getUserStats(int userId) async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/stats/$userId"));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    
    // Return zeros if fail
    return {
      "gamesPlayed": 0,
      "wins": 0,
      "totalPoints": 0,
      "bestTopics": []
    };
  }

  


  Future<void> register(String username, String email, String password, String avatar) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "email": email,
        "password": password,
        "avatar": avatar
      }),
    );

    if (response.statusCode != 200) {
      String msg = "Registration failed";
      try {
        // If server returns simple string (e.g. BadRequest("User exists"))
        if (response.headers['content-type']?.contains('text/plain') ?? false) {
           msg = response.body;
        } else {
           final err = jsonDecode(response.body);
           msg = err['message'] ?? err['title'] ?? msg;
        }
      } catch (_) {}
      throw Exception(msg);
    }
  }
}