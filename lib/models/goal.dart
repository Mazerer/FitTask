import 'dart:convert';
import 'package:uuid/uuid.dart';

class Goal {
  String id;
  String title;
  DateTime dueDate;
  bool isCompleted;
  DateTime? completionDate;
  bool isOverdue;

  Goal({
    String? id,
    required this.title,
    required this.dueDate,
    this.isCompleted = false,
    this.completionDate,
    this.isOverdue = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
      'completionDate': completionDate?.toIso8601String(),
      'isOverdue': isOverdue,
    };
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'],
      title: json['title'],
      dueDate: DateTime.tryParse(json['dueDate'] ?? '') ?? DateTime.now(),
      isCompleted: json['isCompleted'] ?? false,
      completionDate: json['completionDate'] != null
          ? DateTime.tryParse(json['completionDate'])
          : null,
      isOverdue: json['isOverdue'] ?? false,
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
      print('Ошибка декодирования целей: $e');
      return [];
    }
  }

  Goal copyWith({
    String? id,
    String? title,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? completionDate,
    bool? isOverdue,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completionDate: completionDate ?? this.completionDate,
      isOverdue: isOverdue ?? this.isOverdue,
    );
  }

  @override
  String toString() {
    return 'Goal(id: $id, title: $title, dueDate: $dueDate, isCompleted: $isCompleted, completionDate: $completionDate, isOverdue: $isOverdue)';
  }
}
