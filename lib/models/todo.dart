// Removed: import 'dart:convert';

class Todo {
  final String id;
  final String title;
  bool completed;
  String priority;
  DateTime? dueDate;
  final DateTime createdAt;

  Todo({
    required this.id,
    required this.title,
    this.completed = false,
    this.priority = 'low',
    this.dueDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        completed: json['completed'] ?? false,
        priority: (json['priority'] ?? 'low').toLowerCase(),
        dueDate:
            json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now());
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'completed': completed,
      'priority': priority,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
