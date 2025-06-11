import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'provider/theme_provider.dart';
import 'services/auth_service.dart';
import 'services/auto_backup_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final autoBackupService = AutoBackupService();
  await autoBackupService.startAutoBackup();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<AutoBackupService>(create: (_) => autoBackupService),
      ],
      child: const DailyTodoApp(),
    ),
  );
}

class DailyTodoApp extends StatelessWidget {
  const DailyTodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<AuthService>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: StreamBuilder(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          print('StreamBuilder: 認證狀態變化 - ${snapshot.connectionState}');
          print('StreamBuilder: 是否有數據 - ${snapshot.hasData}');

          // 如果沒有數據，直接顯示登入頁面
          if (!snapshot.hasData) {
            print('StreamBuilder: 用戶未登入，顯示 LoginPage');
            return const LoginPage();
          }

          // 如果有數據，顯示主頁面
          print('StreamBuilder: 用戶已登入，導航到 HomePage');
          return const HomePage();
        },
      ),
    );
  }
}
