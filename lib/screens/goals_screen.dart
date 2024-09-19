import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/goal.dart';
import 'history_screen.dart'; // Импортируем экран истории целей

class GoalsScreen extends StatefulWidget {
  @override
  _GoalsScreenState createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final List<Goal> _goals = [];
  final _titleController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final goalsData = prefs.getStringList('goals') ?? [];
    setState(() {
      _goals.clear();
      for (var goalData in goalsData) {
        final parts = goalData.split('|');
        if (parts.length == 3) {
          final title = parts[0];
          final dueDate = DateTime.parse(parts[1]);
          final isCompleted = parts[2] == 'true';
          _goals.add(
              Goal(title: title, dueDate: dueDate, isCompleted: isCompleted));
        }
      }
    });
  }

  Future<void> _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final goalsData = _goals
        .map((goal) =>
            '${goal.title}|${goal.dueDate.toIso8601String()}|${goal.isCompleted}')
        .toList();
    prefs.setStringList('goals', goalsData);
  }

  void _addGoal() {
    final title = _titleController.text;
    final dueDate = _selectedDate;

    if (title.isEmpty || dueDate == null) {
      return;
    }

    setState(() {
      _goals.add(Goal(title: title, dueDate: dueDate));
      _titleController.clear();
      _selectedDate = null;
    });

    _saveGoals(); // Сохраняем цели после добавления
  }

  void _toggleGoal(Goal goal) {
    setState(() {
      goal.isCompleted = !goal.isCompleted;
      if (goal.isCompleted) {
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _goals.remove(goal);
              _saveGoals(); // Обновляем сохранение после удаления
            });
          }
        });
      } else {
        _saveGoals(); // Обновляем сохранение при изменении статуса
      }
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _viewHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoalHistoryScreen(
          completedGoals: _goals.where((g) => g.isCompleted).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Цели'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Форма для ввода целей
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Что сделать',
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? 'Выберите дату'
                        : DateFormat.yMd().format(_selectedDate!),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: _selectDate,
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addGoal,
              child: Text('Добавить цель'),
            ),
            SizedBox(height: 20),
            // Кнопка для просмотра истории целей
            ElevatedButton(
              onPressed: _viewHistory,
              child: Text('Посмотреть историю выполненных целей'),
            ),
            SizedBox(height: 20),
            // Список целей
            Expanded(
              child: ListView.builder(
                itemCount: _goals.length,
                itemBuilder: (ctx, index) {
                  final goal = _goals[index];
                  return AnimatedOpacity(
                    opacity: goal.isCompleted ? 0.0 : 1.0,
                    duration: Duration(seconds: 1),
                    child: Card(
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(
                          goal.title,
                          style: TextStyle(
                            decoration: goal.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        subtitle: Text(DateFormat.yMd().format(goal.dueDate)),
                        trailing: IconButton(
                          icon: Icon(
                            goal.isCompleted
                                ? Icons.check_circle
                                : Icons.circle,
                            color: goal.isCompleted ? Colors.green : null,
                          ),
                          onPressed: () {
                            _toggleGoal(goal);
                          },
                        ),
                        tileColor: goal.isCompleted ? Colors.green[100] : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
