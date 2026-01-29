import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/game_provider.dart';
import 'app_router.dart';

void main() {
  runApp(const KnowItAllApp());
}

class KnowItAllApp extends StatelessWidget {
  const KnowItAllApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameProvider(),
      child: Consumer<GameProvider>(
        builder: (_, game, __) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: game.config.appTitle,
            theme: ThemeData(
              brightness: game.brightness,
              useMaterial3: true,
            ),
            home: const AppRouter(),
          );
        },
      ),
    );
  }
}
