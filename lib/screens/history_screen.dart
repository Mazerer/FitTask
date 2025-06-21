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
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      backgroundColor: Colors.deepPurple[50],
      body: _completedGoals.isEmpty
          ? Center(
              child: Text(
                'Нет завершённых целей',
                style: TextStyle(
                  color: Colors.deepPurple[300],
                  fontSize: 18,
                ),
              ),
            )
          : ListView.builder(
              itemCount: _goalsByMonth.keys.length,
              itemBuilder: (context, index) {
                final monthKey = _goalsByMonth.keys.elementAt(index);
                final goalsForMonth = _goalsByMonth[monthKey]!;
                final monthName = DateFormat.yMMMM('ru').format(monthKey);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      child: Text(
                        monthName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                          letterSpacing: 0.5,
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
                              horizontal: 16.0, vertical: 6.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          color: Colors.white,
                          child: ListTile(
                            leading: Icon(
                              Icons.flag,
                              color: Colors.deepPurple[300],
                            ),
                            title: Text(
                              goal.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 17,
                              ),
                            ),
                            subtitle: goal.completionDate != null
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Завершена: ${DateFormat('dd.MM.yyyy HH:mm').format(goal.completionDate!.toLocal())}',
                                          style: const TextStyle(fontSize: 15),
                                        ),
                                        Text(
                                          'Дедлайн: ${DateFormat('dd.MM.yyyy HH:mm').format(goal.dueDate.toLocal())}',
                                          style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.deepPurple),
                                        ),
                                      ],
                                    ),
                                  )
                                : const Text('Дата завершения неизвестна'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => _deleteGoal(goal),
                              tooltip: 'Удалить',
                            ),
                            tileColor: Colors.transparent,
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
