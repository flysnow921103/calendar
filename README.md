# Calendar 應用程式

這是一個使用 Flutter 開發的現代化行事曆應用程式，提供完整的行事曆管理功能。

## 功能特點

- 📅 完整的行事曆管理功能
- 🔔 本地通知提醒
- 🔐 Firebase 身份驗證
- 📱 跨平台支援 (iOS, Android, Web, Windows, macOS, Linux)
- 💾 本地資料儲存 (SQLite)
- 📊 資料視覺化圖表
- 🔄 雲端同步功能

## 技術架構

- Flutter SDK (>=3.2.3)
- Firebase 服務整合
- Riverpod 狀態管理
- SQLite 本地資料庫
- Flutter Local Notifications
- Fl Chart 圖表庫

## 安裝需求

- Flutter SDK
- Dart SDK
- Android Studio / VS Code
- Firebase 專案設定

## 安裝步驟

1. 克隆專案
```bash
git clone https://github.com/flysnow921103/calendar.git
```

2. 安裝依賴
```bash
flutter pub get
```

3. 設定 Firebase
   - 在 Firebase Console 建立新專案
   - 下載並設定 Firebase 設定檔
   - 啟用需要的 Firebase 服務

4. 執行專案
```bash
flutter run
```

## 專案結構

```
lib/
├── config/      # 設定檔
├── db/          # 資料庫相關
├── models/      # 資料模型
├── pages/       # 頁面元件
├── provider/    # 狀態管理
├── services/    # 服務層
├── utils/       # 工具函數
└── widgets/     # 共用元件
```

## 開發者

曾子恩

