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

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      title: json['title'],
      dueDate: DateTime.tryParse(json['dueDate'] ?? '') ?? DateTime.now(),
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  static String encode(List<Goal> goals) => jsonEncode(
        goals.map((goal) => goal.toJson()).toList(),
      );

  static List<Goal> decode(String goals) {
    try {
      return (jsonDecode(goals) as List<dynamic>)
          .map((item) => Goal.fromJson(item))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Goal copyWith({
    String? title,
    DateTime? dueDate,
    bool? isCompleted,
  }) {
    return Goal(
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  String toString() {
    return 'Goal(title: $title, dueDate: $dueDate, isCompleted: $isCompleted)';
  }
}
