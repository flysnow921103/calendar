import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../db/todo_database.dart';
import '../widgets/todo_item.dart';
import '../utils/notification_service.dart';
import 'settings_page.dart';
import 'about_page.dart';
import 'stats_page.dart';
import 'package:provider/provider.dart';
import '../provider/theme_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> dateList = [];
  Map<String, List<Todo>> todoMap = {};

  @override
  void initState() {
    super.initState();
    NotificationService.init();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    DateTime now = DateTime.now();
    DateTime startDate = now;
    DateTime endDate = now.add(const Duration(days: 29)); // 往後30天

    // 建立30天的日期列表
    dateList = List.generate(
      30,
          (index) => DateFormat('yyyy-MM-dd').format(now.add(Duration(days: index))),
    );

    // 查詢資料庫中這30天的待辦事項
    final todos = await TodoDatabase.getTodosInRange(startDate, endDate);

    // 把todos按照日期分類
    todoMap.clear();
    for (var date in dateList) {
      todoMap[date] = [];
    }
    for (var todo in todos) {
      if (todoMap.containsKey(todo.date)) {
        todoMap[todo.date]!.add(todo);
      }
    }

    setState(() {});
  }

  Future<void> _addTodo() async {
    TextEditingController controller = TextEditingController();
    DateTime selectedDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('新增待辦'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: '輸入事項...'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 29)),
                );
                if (picked != null) {
                  selectedDate = picked;
                }
              },
              child: const Text('選擇日期'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final newTodo = Todo(
                  date: DateFormat('yyyy-MM-dd').format(selectedDate),
                  title: controller.text,
                );
                await TodoDatabase.insertTodo(newTodo);
                await _loadTodos();
                NotificationService.showNotification(
                  title: "新增待辦提醒",
                  body: controller.text,
                );
              }
              Navigator.pop(context);
            },
            child: const Text('新增'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTodoCompletion(Todo todo) async {
    todo.isCompleted = !todo.isCompleted;
    await TodoDatabase.updateTodo(todo);
    await _loadTodos();
  }

  Future<void> _deleteTodo(Todo todo) async {
    await TodoDatabase.deleteTodo(todo.id!);
    await _loadTodos();
  }

  void _navigateTo(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('每日待辦清單'),
      ),
      drawer: Drawer(
        child: Column( // 使用 Column 來管理各個元素
          children: [
            Container(
              height: 80, // 設定較小的高度
              decoration: const BoxDecoration(color: Colors.blue),
              child: const Center(
                child: Text(
                  '選單',
                  style: TextStyle(color: Colors.white, fontSize: 18), // 可以調整字型大小
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('主畫面'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('統計頁'),
              onTap: () {
                Navigator.pop(context);
                _navigateTo(const StatsPage());
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('設定頁'),
              onTap: () {
                Navigator.pop(context);
                _navigateTo(const SettingsPage());
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('關於頁'),
              onTap: () {
                Navigator.pop(context);
                _navigateTo(const AboutPage());
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: dateList.length,
              itemBuilder: (context, index) {
                final date = dateList[index];
                final todos = todoMap[date] ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        DateFormat('yyyy年MM月dd日').format(DateTime.parse(date)),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    if (todos.isNotEmpty)
                      ...todos.map((todo) => TodoItem(
                        text: todo.title,
                        isCompleted: todo.isCompleted,
                        onTap: () => _toggleTodoCompletion(todo),
                        onLongPress: () => _deleteTodo(todo),
                      ))
                    else
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                        child: Text(
                          '（無事項）',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTodo,
        child: const Icon(Icons.add),
      ),
    );
  }
}
