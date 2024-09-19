import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Goal {
  String title;
  DateTime dueDate;
  bool isCompleted;

  Goal({required this.title, required this.dueDate, this.isCompleted = false});
}

class GoalsScreen extends StatefulWidget {
  @override
  _GoalsScreenState createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final List<Goal> _goals = [];
  final _titleController = TextEditingController();
  DateTime? _selectedDate;

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
  }

  void _toggleGoal(Goal goal) {
    setState(() {
      goal.isCompleted = !goal.isCompleted;
      if (goal.isCompleted) {
        Future.delayed(Duration(seconds: 6), () {
          setState(() {
            _goals.remove(goal);
          });
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
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
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
            // Список целей
            Expanded(
              child: ListView.builder(
                itemCount: _goals.length,
                itemBuilder: (ctx, index) {
                  final goal = _goals[index];
                  return AnimatedOpacity(
                    opacity: goal.isCompleted ? 0.0 : 1.0,
                    duration: Duration(seconds: 3),
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
                            if (goal.isCompleted) {
                              Future.delayed(Duration(seconds: 3), () {
                                setState(() {
                                  _goals.remove(goal);
                                });
                              });
                            }
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
