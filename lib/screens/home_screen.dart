import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

// Главный экран
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        final plugin = FlutterLocalNotificationsPlugin();
        await plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Запросить разрешение при открытии экрана
    _requestNotificationPermission();

    return Scaffold(
      appBar: AppBar(
        title: const Text('FitTask'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      backgroundColor: Colors.deepPurple[50],
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Добро пожаловать в FitTask!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 24),
              _HomeButton(
                icon: Icons.flag,
                label: 'Цели',
                onTap: () => Navigator.pushNamed(context, '/goals'),
              ),
              const SizedBox(height: 12),
              _HomeButton(
                icon: Icons.history,
                label: 'История целей',
                onTap: () => Navigator.pushNamed(context, '/history'),
              ),
              const SizedBox(height: 12),
              _HomeButton(
                icon: Icons.fitness_center,
                label: 'Тренировки',
                onTap: () => Navigator.pushNamed(context, '/workouts'),
              ),
              const SizedBox(height: 12),
              _HomeButton(
                icon: Icons.show_chart,
                label: 'Прогресс',
                onTap: () => Navigator.pushNamed(context, '/progress'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HomeButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 48,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
        onPressed: onTap,
      ),
    );
  }
}
