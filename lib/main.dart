import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/workouts_screen.dart'; // Убедись, что этот файл существует
import 'screens/progress_screen.dart'; // Убедись, что этот файл существует

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitTask',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(),
      routes: {
        '/goals': (context) => GoalsScreen(),
        '/workouts': (context) =>
            WorkoutsScreen(), // Убедись, что класс WorkoutsScreen существует
        '/progress': (context) =>
            ProgressScreen(), // Убедись, что класс ProgressScreen существует
      },
    );
  }
}
