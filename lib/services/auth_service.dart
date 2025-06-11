import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 獲取當前用戶
  User? get currentUser => _auth.currentUser;

  // 使用 Google 登入
  Future<UserCredential?> signInWithGoogle() async {
    try {
      print('AuthService: 開始 Google 登入流程');
      
      // 檢查當前登入狀態 (考慮是否需要在此處強制登出，或交由用戶處理)
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        print('AuthService: 發現已登入用戶，正在登出舊會話...');
        // 暫時保留此處的登出，但請注意這可能影響用戶體驗
        await signOut(); 
      }

      // 觸發 Google 登入流程
      print('AuthService: 請求 Google 登入...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('AuthService: Google 登入被用戶取消');
        return null; // 用戶取消登入時返回 null
      }

      print('AuthService: 成功獲取 Google 帳戶資訊');
      
      // 獲取 Google 登入的認證信息
      print('AuthService: 獲取 Google 認證資訊...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print('AuthService: Google 認證資訊不完整');
        // 這是一個明確的失敗，抛出異常
        throw FirebaseAuthException(
          code: 'google-auth-incomplete',
          message: 'Google authentication information is incomplete.',
        );
      }

      print('AuthService: 創建 Firebase 認證憑證');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('AuthService: 使用憑證登入 Firebase...');
      final userCredential = await _auth.signInWithCredential(credential);
      
      print('AuthService: 重新載入用戶資料...');
      await userCredential.user?.reload();
      
      print('AuthService: 登入成功：${userCredential.user?.email}');
      return userCredential;
    } catch (e, stackTrace) {
      print('AuthService: Google 登入錯誤: $e');
      print('AuthService: 錯誤堆疊: $stackTrace');
      rethrow; // 重新抛出異常，讓調用者處理
    }
  }

  // 登出功能 (已包含對 PlatformException 的忽略處理)
  Future<void> signOut() async {
    try {
      print('AuthService: 開始登出流程');
      await _auth.signOut();
      print('AuthService: 登出 Firebase...');
      await _googleSignIn.signOut();
      print('AuthService: 登出 Google...');
      try {
        print('AuthService: 嘗試 Google disconnect...');
        await _googleSignIn.disconnect();
        print('AuthService: Google disconnect 完成');
      } on PlatformException catch (e) {
        print('AuthService: Google disconnect 錯誤（可忽略的 PlatformException）：$e');
      } catch (e) {
        print('AuthService: Google disconnect 錯誤（其他）：$e');
      }
      print('AuthService: 等待登出完成...');
      await Future.delayed(const Duration(milliseconds: 500));
      print('AuthService: 登出完成');
    } catch (e, stackTrace) {
      print('AuthService: 登出錯誤（非 disconnect 錯誤）：$e');
      print('AuthService: 錯誤堆疊: $stackTrace');
      rethrow;
    }
  }

  // 監聽認證狀態變化
  Stream<User?> get authStateChanges => _auth.authStateChanges();
} 