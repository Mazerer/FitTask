import 'package:flutter/material.dart';

// Прогресс целей
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Прогресс'),
      ),
      body: const Center(
        child: Text('Экран прогресса'),
      ),
    );
  }
}
