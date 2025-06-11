import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CloudService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 獲取用戶的資料集合引用
  CollectionReference get _userDataCollection {
    final user = _auth.currentUser;
    if (user == null) throw Exception('用戶未登入');
    return _firestore.collection('users').doc(user.uid).collection('calendar_data');
  }

  // 保存日曆事件到雲端
  Future<void> saveEvent(Map<String, dynamic> eventData) async {
    try {
      await _userDataCollection.add({
        ...eventData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('保存事件錯誤: $e');
      rethrow;
    }
  }

  // 更新日曆事件
  Future<void> updateEvent(String eventId, Map<String, dynamic> eventData) async {
    try {
      await _userDataCollection.doc(eventId).update({
        ...eventData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('更新事件錯誤: $e');
      rethrow;
    }
  }

  // 刪除日曆事件
  Future<void> deleteEvent(String eventId) async {
    try {
      await _userDataCollection.doc(eventId).delete();
    } catch (e) {
      print('刪除事件錯誤: $e');
      rethrow;
    }
  }

  // 獲取所有日曆事件
  Stream<QuerySnapshot> getEvents() {
    return _userDataCollection
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 同步本地資料到雲端
  Future<void> syncLocalData(List<Map<String, dynamic>> localEvents) async {
    try {
      // 獲取雲端資料
      final cloudEvents = await _userDataCollection.get();
      final cloudEventMap = {
        for (var doc in cloudEvents.docs)
          doc.id: doc.data() as Map<String, dynamic>
      };

      // 上傳本地資料到雲端
      for (var localEvent in localEvents) {
        if (!cloudEventMap.containsKey(localEvent['id'])) {
          await saveEvent(localEvent);
        }
      }
    } catch (e) {
      print('同步資料錯誤: $e');
      rethrow;
    }
  }
} 