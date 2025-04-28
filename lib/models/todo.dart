// lib/models/todo.dart
class Todo {
  int? id;
  String date;
  String title;
  bool isCompleted;

  Todo({
    this.id,
    required this.date,
    required this.title,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'title': title,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  static Todo fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      date: map['date'],
      title: map['title'],
      isCompleted: map['isCompleted'] == 1,
    );
  }
}
