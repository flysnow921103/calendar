import 'package:flutter/material.dart';
import '../db/todo_database.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  int completed = 0;
  int uncompleted = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final todos = await TodoDatabase.getAllTodos();
    int completedCount = todos.where((t) => t.isCompleted).length;
    int uncompletedCount = todos.length - completedCount;

    setState(() {
      completed = completedCount;
      uncompleted = uncompletedCount;
    });
  }

  // 清除所有待辦事項
  Future<void> _clearAllTodos() async {
    await TodoDatabase.deleteAllTodos(); // 假設你有一個方法來刪除所有待辦事項
    _loadStats(); // 刪除後重新加載統計
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('所有待辦事項已清除！')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('統計'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('完成數量：$completed', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            Text('未完成數量：$uncompleted', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _clearAllTodos,
              child: const Text('清除所有事項'),
            ),
          ],
        ),
      ),
    );
  }
}
