import 'package:flutter/material.dart';

class ProgressScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Прогресс'),
      ),
      body: Center(
        child: Text('Экран прогресса'),
      ),
    );
  }
}
