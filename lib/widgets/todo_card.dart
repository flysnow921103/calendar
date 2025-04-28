import 'package:flutter/material.dart';

class TodoCard extends StatelessWidget {
  final String date;
  final List<String> todos;
  final bool isToday;
  final Function(String) onTap;

  const TodoCard({
    required this.date,
    required this.todos,
    required this.isToday,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 1,
      child: InkWell(
        onTap: () => onTap(date),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isToday ? "$date（今天）" : date,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              ),
              const SizedBox(height: 4),
              if (todos.isEmpty)
                const Text("尚無事項", style: TextStyle(color: Colors.grey, fontSize: 10))
              else
                ...todos.take(2).map((t) => Text("• $t", style: const TextStyle(fontSize: 9))),
              const Spacer(),
              const Align(
                alignment: Alignment.bottomRight,
                child: Icon(Icons.add, size: 16, color: Colors.teal),
              )
            ],
          ),
        ),
      ),
    );
  }
}
