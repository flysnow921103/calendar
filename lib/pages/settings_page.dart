import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/theme_provider.dart';
import 'package:intl/intl.dart';
import '../services/backup_service.dart';
import '../services/auto_backup_service.dart';
import '../db/todo_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _autoBackup = false;
  String _backupFrequency = '每天';
  final List<String> _frequencies = ['每天', '每週', '每月'];

  @override
  void initState() {
    super.initState();
    _loadBackupSettings();
  }

  Future<void> _loadBackupSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoBackup = prefs.getBool('auto_backup') ?? false;
      _backupFrequency = prefs.getString('backup_frequency') ?? '每天';
    });
  }

  Future<void> _saveBackupSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_backup', _autoBackup);
    await prefs.setString('backup_frequency', _backupFrequency);

    // 重新啟動自動備份服務
    final autoBackupService =
        Provider.of<AutoBackupService>(context, listen: false);
    await autoBackupService.startAutoBackup();
  }

  Future<void> _backupData(BuildContext context) async {
    try {
      final backupService = BackupService();
      final todos = await TodoDatabase.getAllTodos();
      await backupService.backupTodos(todos);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('資料備份成功！')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('備份失敗：$e')),
        );
      }
    }
  }

  Future<void> _restoreData(BuildContext context) async {
    try {
      final backupService = BackupService();
      final todos = await backupService.restoreTodos();

      await TodoDatabase.deleteAllTodos();

      for (var todo in todos) {
        await TodoDatabase.insertTodo(todo);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('資料還原成功！')),
        );

        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('還原失敗：$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    String formattedDate = DateFormat('yyyy年MM月dd日').format(DateTime.now());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '設定',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '今日設定',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      '深色模式',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      '切換應用程式的主題',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    value: isDarkMode,
                    onChanged: (value) {
                      Provider.of<ThemeProvider>(context, listen: false)
                          .toggleTheme();
                    },
                    secondary: Icon(
                      isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      '自動備份',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      '定期自動備份您的待辦事項',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    value: _autoBackup,
                    onChanged: (value) {
                      setState(() {
                        _autoBackup = value;
                        _saveBackupSettings();
                      });
                    },
                    secondary: Icon(
                      Icons.schedule,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (_autoBackup) ...[
                    const Divider(height: 1),
                    ListTile(
                      title: const Text(
                        '備份頻率',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(_backupFrequency),
                      trailing: DropdownButton<String>(
                        value: _backupFrequency,
                        items: _frequencies.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _backupFrequency = newValue;
                              _saveBackupSettings();
                            });
                          }
                        },
                      ),
                    ),
                  ],
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.backup,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    title: const Text(
                      '立即備份',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      '手動備份您的待辦事項',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _backupData(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.restore,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    title: const Text(
                      '還原資料',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      '從雲端還原您的待辦事項',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _restoreData(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
