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
import 'account_page.dart';
import 'ai_chat_page.dart';

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
      (index) =>
          DateFormat('yyyy-MM-dd').format(now.add(Duration(days: index))),
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

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _addTodo() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('新增待辦'),
              onTap: () async {
                Navigator.pop(context);
                await _showAddTodoDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('匯入文字'),
              onTap: () async {
                Navigator.pop(context);
                await _importText();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddTodoDialog() async {
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

  Future<void> _importText() async {
    TextEditingController controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('匯入文字'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '請輸入格式如：6/12作業1 6/12作業2 6/14作業3 6/15作業4',
              ),
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
                try {
                  final items = controller.text.split(' ');
                  final currentYear = DateTime.now().year;

                  int parsedCount = 0; // 記錄成功解析的項目數量

                  for (var item in items) {
                    // 跳過因多個空格可能產生的空字串
                    if (item.isEmpty) continue;

                    final parts = item.split('/');
                    if (parts.length == 2) {
                      try {
                        final month = int.parse(parts[0]);

                        String dayString = '';
                        String title = '';

                        int firstNonDigitIndex = -1;
                        for (int i = 0; i < parts[1].length; i++) {
                          if (!'0123456789'.contains(parts[1][i])) {
                            firstNonDigitIndex = i;
                            break;
                          }
                        }

                        if (firstNonDigitIndex != -1) {
                          dayString = parts[1].substring(0, firstNonDigitIndex);
                          title = parts[1].substring(firstNonDigitIndex);
                        } else {
                          // 如果 parts[1] 只有數字，則將其視為日期，事項為空
                          dayString = parts[1];
                          title = '';
                        }

                        // 在解析前驗證 dayString
                        if (dayString.isEmpty) {
                          print(
                              'Warning: Skipping item "$item" due to missing day number after slash.');
                          continue; // 跳過此項目
                        }

                        final day = int.parse(dayString);

                        // 對日期部分進行基本驗證
                        if (month < 1 || month > 12 || day < 1 || day > 31) {
                          print(
                              'Warning: Skipping item "$item" due to invalid date (Month: $month, Day: $day).');
                          continue; // 如果日期無效，跳過此項目
                        }

                        final date = DateTime(currentYear, month, day);
                        final newTodo = Todo(
                          date: DateFormat('yyyy-MM-dd').format(date),
                          title: title.trim(), // 清除標題前後的空格
                        );
                        await TodoDatabase.insertTodo(newTodo);
                        parsedCount++; // 成功解析並插入一項
                      } on FormatException catch (e) {
                        print('Parsing error for item "$item": ${e.message}');
                        // 記錄特定的解析錯誤，但不會停止整個程序
                      } catch (e) {
                        print('Database or unknown error for item "$item": $e');
                        // 記錄其他錯誤
                      }
                    } else {
                      print(
                          'Warning: Skipping item "$item" due to invalid format (Expected "month/dayTask").');
                    }
                  }

                  await _loadTodos();
                  if (mounted) {
                    if (parsedCount > 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('成功匯入 $parsedCount 筆待辦事項！')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('沒有有效的待辦事項可以匯入。請檢查您的輸入格式。')),
                      );
                    }
                  }
                } catch (e) {
                  // 捕捉在迴圈之前或之後可能發生的任何非預期錯誤
                  print(
                      'An unexpected error occurred during import process: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('匯入時發生非預期錯誤：$e')),
                    );
                  }
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('輸入內容不能為空。')),
                  );
                }
              }
              Navigator.pop(context); // 無論成功或失敗，都關閉對話框
            },
            child: const Text('匯入'),
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

  void _navigateTo(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
    // 當從其他頁面返回時，重新載入資料
    _loadTodos();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '每日待辦清單',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _importText,
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
            children: [
              Container(
                height: 120,
                padding: const EdgeInsets.only(top: 40),
                child: const Center(
                  child: Text(
                    '選單',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildDrawerItem(
                        icon: Icons.home,
                        title: '主畫面',
                        onTap: () => Navigator.pop(context),
                      ),
                      _buildDrawerItem(
                        icon: Icons.bar_chart,
                        title: '統計頁',
                        onTap: () {
                          Navigator.pop(context);
                          _navigateTo(const StatsPage());
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.chat,
                        title: 'AI 對話',
                        onTap: () {
                          Navigator.pop(context);
                          _navigateTo(const AiChatPage());
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.account_circle,
                        title: '帳戶',
                        onTap: () {
                          Navigator.pop(context);
                          _navigateTo(const AccountPage());
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.settings,
                        title: '設定頁',
                        onTap: () {
                          Navigator.pop(context);
                          _navigateTo(const SettingsPage());
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.info,
                        title: '關於頁',
                        onTap: () {
                          Navigator.pop(context);
                          _navigateTo(const AboutPage());
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          DateFormat('yyyy年MM月dd日')
                              .format(DateTime.parse(date)),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
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
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              '（無事項）',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTodoDialog,
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
