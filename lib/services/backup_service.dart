import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/todo.dart';

class BackupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 備份所有待辦事項
  Future<void> backupTodos(List<Todo> todos) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('用戶未登入');

    final batch = _firestore.batch();
    final todosRef =
        _firestore.collection('users').doc(user.uid).collection('todos');

    // 先刪除所有現有的備份
    final existingTodos = await todosRef.get();
    for (var doc in existingTodos.docs) {
      batch.delete(doc.reference);
    }

    // 添加新的待辦事項
    for (var todo in todos) {
      final docRef = todosRef.doc();
      batch.set(docRef, {
        'title': todo.title,
        'date': todo.date,
        'isCompleted': todo.isCompleted,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // 還原所有待辦事項
  Future<List<Todo>> restoreTodos() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('用戶未登入');

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('todos')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Todo(
        title: data['title'] as String,
        date: data['date'] as String,
        isCompleted: data['isCompleted'] as bool,
      );
    }).toList();
  }
}
