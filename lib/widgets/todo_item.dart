// lib/widgets/todo_item.dart
import 'package:flutter/material.dart';

class TodoItem extends StatelessWidget {
  final String text;
  final bool isCompleted;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const TodoItem({
    super.key,
    required this.text,
    this.isCompleted = false,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        text,
        style: TextStyle(
          decoration: isCompleted ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing: Icon(
        isCompleted ? Icons.check_circle : Icons.circle_outlined,
        color: isCompleted ? Colors.green : Colors.grey,
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
