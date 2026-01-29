import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/game_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/create_game_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/results_screen.dart';
import 'screens/game_over_screen.dart';

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (_, game, __) {
        switch (game.appState) {
          case AppState.welcome:
            return const WelcomeScreen();

          case AppState.create:
            return const CreateGameScreen();

          case AppState.lobby:
            return const LobbyScreen();

          case AppState.quiz:
            return const QuizScreen();

          case AppState.results:
            return const ResultsScreen();

          case AppState.gameOver:
            return const GameOverScreen();
        }
      },
    );
  }
}
