import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:device_info_plus/device_info_plus.dart';
import '../models/goal.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  _GoalsScreenState createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final List<Goal> _goals = [];
  final _titleController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  Timer? _overdueTimer; // <--- добавьте это поле

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _loadGoals().then((_) => _checkOverdueGoals());
    _startOverdueTimer();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // --- Создание канала уведомлений ---
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'goals_channel',
      'Уведомления целей',
      importance: Importance.max,
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // --- Запрос разрешения на уведомления для Android 13+ ---
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }
    }
  }

  @override
  void dispose() {
    _overdueTimer?.cancel(); // <--- отмена таймера при уничтожении
    super.dispose();
  }

  void _startOverdueTimer() {
    _overdueTimer?.cancel();
    _overdueTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkOverdueGoals();
    });
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

  Future<void> _checkOverdueGoals() async {
    final now = DateTime.now();
    final overdueGoals = _goals.where((g) =>
      !g.isCompleted && g.dueDate.isBefore(now)
    ).toList();

    if (overdueGoals.isNotEmpty) {
      for (var goal in overdueGoals) {
        goal.isCompleted = true;
        goal.completionDate = goal.dueDate;
        goal.isOverdue = true;
        await _saveCompletedGoal(goal);

        // --- Уведомление о просроченной цели ---
        await flutterLocalNotificationsPlugin.show(
          goal.id.hashCode + 10000, // уникальный id для уведомления
          'FitTask',
          'Цель просрочена: ${goal.title}',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'goals_channel',
              'Уведомления целей',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
      setState(() {
        _goals.removeWhere((g) => overdueGoals.contains(g));
      });
      _saveGoals();
    }
  }

  void _addGoal() {
    final title = _titleController.text;
    final dueDate = _selectedDate;
    final dueTime = _selectedTime;

    String? errorMessage;
    final now = DateTime.now();

    if (title.isEmpty) {
      errorMessage = 'Пожалуйста, введите заголовок цели.';
    } else if (dueDate == null) {
      errorMessage = 'Пожалуйста, выберите дату дедлайна.';
    } else if (dueTime == null) {
      errorMessage = 'Пожалуйста, выберите время дедлайна.';
    } else {
      final selectedDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
      final nowDateOnly = DateTime(now.year, now.month, now.day);

      if (selectedDateOnly.isBefore(nowDateOnly)) {
        errorMessage = 'Вы выбрали дату, которая уже прошла!';
      } else if (selectedDateOnly.isAtSameMomentAs(nowDateOnly)) {
        final selectedDateTime = DateTime(
          dueDate.year, dueDate.month, dueDate.day, dueTime.hour, dueTime.minute,
        );
        if (selectedDateTime.isBefore(now)) {
          errorMessage = 'Вы выбрали время, которое уже прошло!';
        }
      }
    }

    if (errorMessage != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ошибка'),
          content: Text(errorMessage!),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ОК'),
            ),
          ],
        ),
      );
      return;
    }

    final fullDueDate = DateTime(
      dueDate!.year,
      dueDate.month,
      dueDate.day,
      dueTime!.hour,
      dueTime.minute,
    );

    setState(() {
      final newGoal = Goal(title: title, dueDate: fullDueDate);
      _goals.add(newGoal);
      _titleController.clear();
      _selectedDate = null;
      _selectedTime = null;
      print('Добавлена цель: $newGoal');
      _scheduleGoalNotifications(newGoal); // <-- переместили сюда
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

    Future.delayed(const Duration(milliseconds: 1000), () {
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
      locale: const Locale('ru'),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        print('Выбрана дата: $_selectedDate');
        print('Первый день недели (по локали): ${DateFormat('EEEE', 'ru').format(DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)))}');
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        print('Выбрано время: $_selectedTime');
      });
    }
  }

  void _viewHistory() {
    print('Переход в историю');
    Navigator.pushNamed(context, '/history');
  }

  void _scheduleGoalNotifications(Goal goal) {
    final now = DateTime.now();
    final due = goal.dueDate;

    final List<Map<String, dynamic>> notifications = [
      {
        'delay': due.subtract(const Duration(days: 3)).difference(now),
        'text': 'Через 3 дня дедлайн по цели: ${goal.title}',
        'id': goal.id.hashCode + 1,
      },
      {
        'delay': due.subtract(const Duration(days: 1)).difference(now),
        'text': 'Завтра дедлайн по цели: ${goal.title}',
        'id': goal.id.hashCode + 2,
      },
      {
        'delay': due.subtract(const Duration(hours: 12)).difference(now),
        'text': 'Через 12 часов дедлайн по цели: ${goal.title}',
        'id': goal.id.hashCode + 3,
      },
      {
        'delay': due.subtract(const Duration(hours: 1)).difference(now),
        'text': 'Через 1 час дедлайн по цели: ${goal.title}',
        'id': goal.id.hashCode + 4,
      },
    ];

    for (final notif in notifications) {
      final delay = notif['delay'] as Duration;
      if (delay.inSeconds > 0) {
        Timer(delay, () async {
          await flutterLocalNotificationsPlugin.show(
            notif['id'] as int,
            'FitTask',
            notif['text'] as String,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'goals_channel',
                'Уведомления целей',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
          );
          print('Показано уведомление: ${notif['text']}');
        });
        print('Таймер для уведомления: ${notif['text']} через ${delay.inSeconds} секунд');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Цели'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      backgroundColor: Colors.deepPurple[50],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Что сделать',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedDate == null
                              ? 'Выберите дату'
                              : DateFormat.yMd('ru').format(_selectedDate!),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today, color: Colors.deepPurple),
                        onPressed: _selectDate,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedTime == null
                              ? 'Выберите время'
                              : _selectedTime!.format(context),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.access_time, color: Colors.deepPurple),
                        onPressed: _selectTime,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить цель'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _addGoal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.history),
                      label: const Text('Посмотреть историю целей'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.deepPurple,
                        side: const BorderSide(color: Colors.deepPurple),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _viewHistory,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _goals.isEmpty
                  ? Center(
                      child: Text(
                        'Нет активных целей',
                        style: TextStyle(
                          color: Colors.deepPurple[300],
                          fontSize: 18,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _goals.length,
                      itemBuilder: (ctx, index) {
                        final goal = _goals[index];
                        return AnimatedOpacity(
                          opacity: goal.isCompleted ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 1000),
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            color: goal.isCompleted
                                ? Colors.green[100]
                                : Colors.white,
                            child: ListTile(
                              title: Text(
                                goal.title,
                                style: TextStyle(
                                  decoration: goal.isCompleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 17,
                                ),
                              ),
                              subtitle: Text(
                                'Дедлайн: ${DateFormat('dd.MM.yyyy HH:mm').format(goal.dueDate)}',
                                style: const TextStyle(fontSize: 15),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  goal.isCompleted
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: goal.isCompleted
                                      ? Colors.green
                                      : Colors.deepPurple,
                                ),
                                onPressed: () => _toggleGoal(goal),
                              ),
                              tileColor: Colors.transparent,
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