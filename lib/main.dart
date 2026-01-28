import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/quiz_screen.dart'; 
import 'screens/results_screen.dart'; 
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KnowItAll',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: GameRouter(),
    );
  }
}

class GameRouter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameProvider>().appState;

    // Simple routing based on state enum
    if (state == AppState.welcome) return WelcomeScreen();
    if (state == AppState.lobby) return LobbyScreen();
    if (state == AppState.quiz) return QuizScreen();
    if (state == AppState.results) return ResultsScreen();
    
    return Scaffold(body: Center(child: Text("Quiz Screen Coming Soon...")));
  }
}