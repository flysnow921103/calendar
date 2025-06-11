import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'backup_service.dart';
import '../db/todo_database.dart';

class AutoBackupService {
  Timer? _backupTimer;
  final BackupService _backupService = BackupService();

  Future<void> startAutoBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final autoBackup = prefs.getBool('auto_backup') ?? false;
    final frequency = prefs.getString('backup_frequency') ?? '每天';

    if (!autoBackup) {
      stopAutoBackup();
      return;
    }

    Duration interval;
    switch (frequency) {
      case '每天':
        interval = const Duration(days: 1);
        break;
      case '每週':
        interval = const Duration(days: 7);
        break;
      case '每月':
        interval = const Duration(days: 30);
        break;
      default:
        interval = const Duration(days: 1);
    }

    _backupTimer?.cancel();
    _backupTimer = Timer.periodic(interval, (_) async {
      try {
        final todos = await TodoDatabase.getAllTodos();
        await _backupService.backupTodos(todos);
      } catch (e) {
        print('自動備份失敗：$e');
      }
    });
  }

  void stopAutoBackup() {
    _backupTimer?.cancel();
    _backupTimer = null;
  }
}
