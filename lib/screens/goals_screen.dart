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
    print('Загрузка activeGoals: $activeGoalsString'); // Отладка
    if (activeGoalsString != null) {
      setState(() {
        _goals.clear();
        _goals.addAll(Goal.decode(activeGoalsString));
        print('Декодировано в _goals: $_goals'); // Отладка
      });
    } else {
      print('Нет данных в activeGoals'); // Отладка
    }
  }

  Future<void> _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedGoals = Goal.encode(_goals);
    final success = await prefs.setString('activeGoals', encodedGoals);
    print('Сохранение activeGoals: $encodedGoals, успех: $success'); // Отладка
  }

  Future<void> _saveCompletedGoal(Goal goal) async {
    final prefs = await SharedPreferences.getInstance();
    final completedGoalsString = prefs.getString('completedGoals') ?? '[]';
    print('Текущие completedGoals: $completedGoalsString'); // Отладка
    final completedGoals = Goal.decode(completedGoalsString);
    completedGoals.add(goal);
    final encodedCompletedGoals = Goal.encode(completedGoals);
    final success =
        await prefs.setString('completedGoals', encodedCompletedGoals);
    print(
        'Сохранение completedGoals: $encodedCompletedGoals, успех: $success'); // Отладка
  }

  void _addGoal() {
    final title = _titleController.text;
    final dueDate = _selectedDate;

    if (title.isEmpty || dueDate == null) {
      print('Ошибка: пустой title или dueDate'); // Отладка
      return;
    }

    setState(() {
      final newGoal = Goal(title: title, dueDate: dueDate);
      _goals.add(newGoal);
      _titleController.clear();
      _selectedDate = null;
      print('Добавлена цель: $newGoal'); // Отладка
    });
    _saveGoals();
  }

  void _toggleGoal(Goal goal) {
    setState(() {
      if (!goal.isCompleted) {
        final completedGoal = goal.copyWith(
          isCompleted: true,
          completionDate: DateTime.now(),
        );
        _goals.removeWhere((g) => g.id == goal.id);
        print('Цель завершена: $completedGoal'); // Отладка
        print('Оставшиеся activeGoals: $_goals'); // Отладка
        _saveGoals();
        _saveCompletedGoal(completedGoal);
      } else {
        print('Цель уже завершена: $goal'); // Отладка
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
        print('Выбрана дата: $_selectedDate'); // Отладка
      });
    }
  }

  void _viewHistory() {
    print('Переход в HistoryScreen'); // Отладка
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
                        : DateFormat.yMd().format(_selectedDate!),
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
                    duration: const Duration(seconds: 1),
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
                        subtitle: Text(DateFormat.yMd().format(goal.dueDate)),
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
