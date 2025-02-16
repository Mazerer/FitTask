import 'package:flutter/material.dart';

class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тренировочные планы'),
      ),
      body: const Center(
        child: Text('Экран тренировочных планов'),
      ),
    );
  }
}
