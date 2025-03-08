import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/goal.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Goal> _completedGoals = [];
  Map<DateTime, List<Goal>> _goalsByMonth = {};

  @override
  void initState() {
    super.initState();
    _loadCompletedGoals();
  }

  Future<void> _loadCompletedGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final completedGoalsString = prefs.getString('completedGoals');
    print(
        'Загружено из SharedPreferences (completedGoals): $completedGoalsString');

    if (completedGoalsString == null || completedGoalsString == '[]') {
      // Тестовые данные, если история пуста
      _completedGoals = [
        Goal(
          title: 'Цель 1 (Март 2025)',
          dueDate: DateTime(2025, 3, 10),
          isCompleted: true,
          completionDate: DateTime(2025, 3, 10, 14, 30),
        ),
        Goal(
          title: 'Цель 2 (Март 2025)',
          dueDate: DateTime(2025, 3, 8),
          isCompleted: true,
          completionDate: DateTime(2025, 3, 8, 9, 15),
        ),
        Goal(
          title: 'Цель 3 (Февраль 2025)',
          dueDate: DateTime(2025, 2, 15),
          isCompleted: true,
          completionDate: DateTime(2025, 2, 15, 12, 0),
        ),
        Goal(
          title: 'Цель 4 (Январь 2025)',
          dueDate: DateTime(2025, 1, 20),
          isCompleted: true,
          completionDate: DateTime(2025, 1, 20, 16, 45),
        ),
      ];
      final encodedGoals = Goal.encode(_completedGoals);
      await prefs.setString('completedGoals', encodedGoals);
      print('Созданы тестовые данные: $encodedGoals');
    } else {
      _completedGoals = Goal.decode(completedGoalsString);
      print('Декодировано в _completedGoals: $_completedGoals');
    }

    setState(() {
      _groupGoalsByMonth();
    });
  }

  void _groupGoalsByMonth() {
    final Map<DateTime, List<Goal>> groupedGoals = {};

    for (var goal in _completedGoals) {
      if (goal.completionDate == null)
        continue; // Пропускаем цели без даты завершения

      // Извлекаем год и месяц из completionDate
      final year = goal.completionDate!.year;
      final month = goal.completionDate!.month;
      final key = DateTime(year, month); // Ключ — первый день месяца

      if (!groupedGoals.containsKey(key)) {
        groupedGoals[key] = [];
      }
      groupedGoals[key]!.add(goal);
    }

    // Сортируем ключи (месяцы) по убыванию (новые вверху)
    final sortedKeys = groupedGoals.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final sortedGroupedGoals = <DateTime, List<Goal>>{};
    for (var key in sortedKeys) {
      sortedGroupedGoals[key] = groupedGoals[key]!;
      // Сортируем цели внутри каждого месяца по дате завершения (по убыванию)
      sortedGroupedGoals[key]!
          .sort((a, b) => b.completionDate!.compareTo(a.completionDate!));
    }

    setState(() {
      _goalsByMonth = sortedGroupedGoals;
    });
  }

  Future<void> _deleteGoal(Goal goal) async {
    setState(() {
      _completedGoals.removeWhere((g) => g.id == goal.id);
      print('Удалена цель из _completedGoals: $goal');
      print('Оставшиеся completedGoals: $_completedGoals');
      _groupGoalsByMonth(); // Обновляем группировку после удаления
    });

    final prefs = await SharedPreferences.getInstance();
    final encodedGoals = Goal.encode(_completedGoals);
    final success = await prefs.setString('completedGoals', encodedGoals);
    print(
        'Сохранение completedGoals после удаления: $encodedGoals, успех: $success');
  }

  @override
  Widget build(BuildContext context) {
    print('Отрисовка HistoryScreen, текущие цели: $_completedGoals');
    return Scaffold(
      appBar: AppBar(
        title: const Text('История целей'),
      ),
      body: _completedGoals.isEmpty
          ? const Center(child: Text('Нет завершённых целей'))
          : ListView.builder(
              itemCount: _goalsByMonth.keys.length,
              itemBuilder: (context, index) {
                final monthKey = _goalsByMonth.keys.elementAt(index);
                final goalsForMonth = _goalsByMonth[monthKey]!;
                final monthName = DateFormat.yMMMM('ru')
                    .format(monthKey); // Например, "Март 2025"

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        monthName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: goalsForMonth.length,
                      itemBuilder: (context, goalIndex) {
                        final goal = goalsForMonth[goalIndex];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 4.0),
                          child: ListTile(
                            title: Text(goal.title),
                            subtitle: goal.completionDate != null
                                ? Text(
                                    'Завершена: ${DateFormat('dd.MM.yyyy HH:mm').format(goal.completionDate!.toLocal())}',
                                  )
                                : const Text('Дата завершения неизвестна'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteGoal(goal),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
    );
  }
}
