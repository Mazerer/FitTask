import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/goal.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

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
    final activeGoalsString = prefs.getString('activeGoals');
    print('Загрузка activeGoals: $activeGoalsString');
    if (activeGoalsString != null) {
      setState(() {
        _goals.clear();
        _goals.addAll(Goal.decode(activeGoalsString));
        print('Декодировано в _goals: $_goals');
      });
    } else {
      print('Нет данных в activeGoals');
    }
  }

  Future<void> _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedGoals = Goal.encode(_goals);
    final success = await prefs.setString('activeGoals', encodedGoals);
    print('Сохранение activeGoals: $encodedGoals, успех: $success');
  }

  Future<void> _saveCompletedGoal(Goal goal) async {
    final prefs = await SharedPreferences.getInstance();
    final completedGoalsString = prefs.getString('completedGoals') ?? '[]';
    print('Текущие completedGoals: $completedGoalsString');
    final completedGoals = Goal.decode(completedGoalsString);
    completedGoals.add(goal);
    final encodedCompletedGoals = Goal.encode(completedGoals);
    final success = await prefs.setString('completedGoals', encodedCompletedGoals);
    print('Сохранение completedGoals: $encodedCompletedGoals, успех: $success');
  }

  void _addGoal() {
    final title = _titleController.text;
    final dueDate = _selectedDate;

    if (title.isEmpty || dueDate == null) {
      print('Ошибка: пустой title или dueDate');
      return;
    }

    setState(() {
      final newGoal = Goal(title: title, dueDate: dueDate);
      _goals.add(newGoal);
      _titleController.clear();
      _selectedDate = null;
      print('Добавлена цель: $newGoal');
    });
    _saveGoals();
  }

  void _toggleGoal(Goal goal) {
    setState(() {
      if (!goal.isCompleted) {
        goal.isCompleted = true;
        goal.completionDate = DateTime.now();
        print('Цель отмечена как завершённая: $goal');
      }
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          final completedGoal = goal.copyWith(
            isCompleted: true,
            completionDate: goal.completionDate,
          );
          _goals.removeWhere((g) => g.id == goal.id);
          print('Цель удалена из activeGoals: $_goals');
          _saveGoals();
          _saveCompletedGoal(completedGoal);
        });
      }
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      // firstDayOfWeek: DateTime.monday, // Раскомментируй после обновления Flutter
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        print('Выбрана дата: $_selectedDate');
        print('Первый день недели (по локали): ${DateFormat('EEEE', 'ru').format(DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)))}');
      });
    }
  }

  void _viewHistory() {
    print('Переход в HistoryScreen');
    Navigator.pushNamed(context, '/history');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Цели'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Что сделать'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? 'Выберите дату'
                        : DateFormat.yMd('ru').format(_selectedDate!),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _selectDate,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addGoal,
              child: const Text('Добавить цель'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _viewHistory,
              child: const Text('Посмотреть историю выполненных целей'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _goals.length,
                itemBuilder: (ctx, index) {
                  final goal = _goals[index];
                  return AnimatedOpacity(
                    opacity: goal.isCompleted ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 1500),
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(
                          goal.title,
                          style: TextStyle(
                            decoration: goal.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        subtitle: Text(DateFormat.yMd('ru').format(goal.dueDate)),
                        trailing: IconButton(
                          icon: Icon(
                            goal.isCompleted
                                ? Icons.check_circle
                                : Icons.circle,
                            color: goal.isCompleted ? Colors.green : null,
                          ),
                          onPressed: () => _toggleGoal(goal),
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