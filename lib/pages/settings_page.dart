import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/theme_provider.dart';
import 'package:intl/intl.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 Provider 來取得當前主題狀態
    bool isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    // 獲取當前日期
    String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 根據主題設定日期顏色
            Text(
              formattedDate,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black, // 日期顏色根據主題調整
                fontSize: 24,
              ),
            ),
            SwitchListTile(
              title: const Text('深色模式'),
              value: isDarkMode,
              onChanged: (value) {
                // 切換主題
                Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
              },
            ),
          ],
        ),
      ),
    );
  }
}
