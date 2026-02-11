import '../providers/game_provider.dart';

class AppNavRules {
  static bool shouldShowAppMenu(AppState state) {
    switch (state) {
      case AppState.welcome:
      case AppState.create:
      case AppState.lobby:
      case AppState.results:
      case AppState.gameOver:
        return true;
      case AppState.quiz:
        return false;
    }
  }

  /// Conservative: pairing is OK pre-quiz.
  static bool canConnectTv(AppState state) {
    switch (state) {
      case AppState.welcome:
      case AppState.create:
        return true;
      case AppState.lobby:
      case AppState.quiz:
      case AppState.results:
      case AppState.gameOver:
        return false;
    }
  }
}
