import 'package:flutter/material.dart';
import '../models/goal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoalHistoryScreen extends StatefulWidget {
  final List<Goal> completedGoals;

  GoalHistoryScreen({required this.completedGoals});

  @override
  _GoalHistoryScreenState createState() => _GoalHistoryScreenState();
}

class _GoalHistoryScreenState extends State<GoalHistoryScreen> {
  late List<Goal> _completedGoals;

  @override
  void initState() {
    super.initState();
    _completedGoals = widget.completedGoals;
  }

  Future<void> _deleteGoal(Goal goal) async {
    setState(() {
      _completedGoals.remove(goal);
    });

    // Обновляем сохраненные данные
    final prefs = await SharedPreferences.getInstance();
    final goalsData = _completedGoals
        .map((goal) =>
            '${goal.title}|${goal.dueDate.toIso8601String()}|${goal.isCompleted}')
        .toList();
    prefs.setStringList('goals', goalsData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('История целей'),
      ),
      body: _completedGoals.isEmpty
          ? Center(child: Text('Нет завершённых целей'))
          : ListView.builder(
              itemCount: _completedGoals.length,
              itemBuilder: (context, index) {
                final goal = _completedGoals[index];
                return ListTile(
                  title: Text(goal.title),
                  subtitle: Text('Завершена: ${goal.dueDate.toLocal()}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _deleteGoal(goal),
                  ),
                );
              },
            ),
    );
  }
}
