import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/history_screen.dart';
import 'screens/workouts_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitTask',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
      routes: {
        '/goals': (context) => GoalsScreen(),
        '/progress': (context) => ProgressScreen(),
        '/history': (context) => GoalHistoryScreen(
              completedGoals: [],
            ),
        '/workouts': (context) => WorkoutsScreen()
      },
    );
  }
}
