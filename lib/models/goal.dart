import 'dart:convert';

class Goal {
  String title;
  DateTime dueDate;
  bool isCompleted;

  Goal({
    required this.title,
    required this.dueDate,
    this.isCompleted = false,
  });

  // Метод для преобразования объекта Goal в JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  // Метод для создания объекта Goal из JSON
  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      title: json['title'],
      dueDate: DateTime.parse(json['dueDate']),
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  // Метод для преобразования списка целей в JSON-строку
  static String encode(List<Goal> goals) => jsonEncode(
        goals.map((goal) => goal.toJson()).toList(),
      );

  // Метод для декодирования списка целей из JSON-строки
  static List<Goal> decode(String goals) => (jsonDecode(goals) as List<dynamic>)
      .map((item) => Goal.fromJson(item))
      .toList();
}
