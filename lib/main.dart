import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 1. Import Provider source strictly
import 'providers/game_provider.dart'; 

// 2. Import WelcomeScreen but HIDE any accidental GameProvider inside it
import 'screens/welcome_screen.dart' hide GameProvider; 

import 'theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
      ],
      child: const KnowItAllApp(),
    ),
  );
}

class KnowItAllApp extends StatelessWidget {
  const KnowItAllApp({super.key});

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);

    return MaterialApp(
      title: 'KnowItAll',
      debugShowCheckedModeBanner: false,
      themeMode: game.brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: WelcomeScreen(),
    );
  }
}