import 'package:flutter/material.dart';
import '../models/goal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Goal> _completedGoals = [];

  @override
  void initState() {
    super.initState();
    print('Инициализация HistoryScreen'); // Отладка
    _loadCompletedGoals();
  }

  Future<void> _loadCompletedGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final completedGoalsString = prefs.getString('completedGoals');
    print(
        'Загружено из SharedPreferences (completedGoals): $completedGoalsString'); // Отладка
    if (completedGoalsString != null) {
      setState(() {
        _completedGoals = Goal.decode(completedGoalsString);
        print('Декодировано в _completedGoals: $_completedGoals'); // Отладка
      });
    } else {
      print('Нет данных в completedGoals'); // Отладка
    }
  }

  Future<void> _deleteGoal(Goal goal) async {
    setState(() {
      _completedGoals.removeWhere((g) => g.id == goal.id);
      print('Удалена цель из _completedGoals: $goal'); // Отладка
      print('Оставшиеся completedGoals: $_completedGoals'); // Отладка
    });
    final prefs = await SharedPreferences.getInstance();
    final encodedGoals = Goal.encode(_completedGoals);
    final success = await prefs.setString('completedGoals', encodedGoals);
    print(
        'Сохранение completedGoals после удаления: $encodedGoals, успех: $success'); // Отладка
  }

  @override
  Widget build(BuildContext context) {
    print('Отрисовка HistoryScreen, текущие цели: $_completedGoals'); // Отладка
    return Scaffold(
      appBar: AppBar(
        title: const Text('История целей'),
      ),
      body: _completedGoals.isEmpty
          ? const Center(child: Text('Нет завершённых целей'))
          : ListView.builder(
              itemCount: _completedGoals.length,
              itemBuilder: (context, index) {
                final goal = _completedGoals[index];
                return ListTile(
                  title: Text(goal.title),
                  subtitle: goal.completionDate != null
                      ? Text('Завершена: ${goal.completionDate!.toLocal()}')
                      : Text('Дата завершения неизвестна'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteGoal(goal),
                  ),
                );
              },
            ),
    );
  }
}
