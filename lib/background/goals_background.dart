import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import '../models/goal.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<bool> checkOverdueGoalsInBackground() async {
  WidgetsFlutterBinding.ensureInitialized();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'goals_channel',
    'Уведомления целей',
    description: 'Канал уведомлений для целей',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  tz.initializeTimeZones();

  final prefs = await SharedPreferences.getInstance();
  final activeGoalsString = prefs.getString('activeGoals') ?? '[]';
  final goals = Goal.decode(activeGoalsString);
  final now = DateTime.now();

  // --- Перенос просроченных целей в историю ---
  final overdueGoals =
      goals.where((g) => !g.isCompleted && g.dueDate.isBefore(now)).toList();

  if (overdueGoals.isNotEmpty) {
    // Получаем текущую историю
    final completedGoalsString = prefs.getString('completedGoals') ?? '[]';
    final completedGoals = Goal.decode(completedGoalsString);

    for (var goal in overdueGoals) {
      goal.isCompleted = true;
      goal.completionDate = goal.dueDate;
      goal.isOverdue = true;

      // Добавляем в историю (если её там ещё нет)
      final alreadyInHistory =
          completedGoals.any((g) => g.id == goal.id);
      if (!alreadyInHistory) {
        completedGoals.add(goal);

        // Уведомление о переносе в историю
        await flutterLocalNotificationsPlugin.show(
          goal.id.hashCode + 10000,
          'FitTask',
          'Цель просрочена и перенесена в историю: ${goal.title}',
          NotificationDetails(
            android: AndroidNotificationDetails(
              'goals_channel',
              'Уведомления целей',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    }

    // Сохраняем обновлённую историю
    await prefs.setString('completedGoals', Goal.encode(completedGoals));

    // Удаляем просроченные из активных целей
    goals.removeWhere((g) => overdueGoals.contains(g));
    await prefs.setString('activeGoals', Goal.encode(goals));
  }

  // --- проверка и отправка подготовленных уведомлений ---
  await _checkScheduledNotifications(prefs);

  return true;
}

Future<void> _checkScheduledNotifications(SharedPreferences prefs) async {
  final now = DateTime.now();
  final activeGoalsString = prefs.getString('activeGoals') ?? '[]';
  final goals = Goal.decode(activeGoalsString);

  for (var goal in goals) {
    final notificationKey = 'notif_${goal.id}';
    final sentNotifications = prefs.getStringList(notificationKey) ?? [];

    final notifications = [
      {
        'id': goal.id.hashCode + 1,
        'offset': Duration(days: 3),
        'text': 'Через 3 дня дедлайн по цели: ${goal.title}'
      },
      {
        'id': goal.id.hashCode + 2,
        'offset': Duration(days: 1),
        'text': 'Завтра дедлайн по цели: ${goal.title}'
      },
      {
        'id': goal.id.hashCode + 3,
        'offset': Duration(hours: 12),
        'text': 'Через 12 часов дедлайн по цели: ${goal.title}'
      },
      {
        'id': goal.id.hashCode + 4,
        'offset': Duration(hours: 1),
        'text': 'Через 1 час дедлайн по цели: ${goal.title}'
      },
    ];

    for (final notif in notifications) {
      final notifId = notif['id'] as int;
      final notifKey = notifId.toString();
      if (sentNotifications.contains(notifKey)) continue;

      final notifTime = goal.dueDate.subtract(notif['offset'] as Duration);
      if (now.isAfter(notifTime) && now.difference(notifTime).inMinutes < 15) {
        await flutterLocalNotificationsPlugin.show(
          notifId,
          'FitTask',
          notif['text'] as String,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'goals_channel',
              'Уведомления целей',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
        sentNotifications.add(notifKey);
        await prefs.setStringList(notificationKey, sentNotifications);
      }
    }
  }
}