import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/history_screen.dart';
import 'screens/workouts_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitTask',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
      routes: {
        '/goals': (context) => const GoalsScreen(),
        '/progress': (context) => const ProgressScreen(),
        '/history': (context) => const HistoryScreen(),
        '/workouts': (context) => const WorkoutsScreen(),
      },
    );
  }
}
