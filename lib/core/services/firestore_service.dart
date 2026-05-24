import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/task/domain/entities/task.dart';
import '../../features/focus/domain/entities/focus_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Koleksi tasks
  CollectionReference get _tasksRef => _db.collection('tasks');

  // Koleksi focus_sessions
  CollectionReference get _sessionsRef => _db.collection('focus_sessions');

  // Stream tasks berdasarkan User ID
  Stream<List<Task>> getTasksStream(String userId) {
    return _tasksRef.where('userId', isEqualTo: userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Task.fromFirestore(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Menambah tugas baru
  Future<void> addTask(Task task) async {
    await _tasksRef.doc(task.id).set(task.toMap());
  }

  // Memperbarui tugas
  Future<void> updateTask(Task task) async {
    await _tasksRef.doc(task.id).update(task.toMap());
  }

  // Menghapus tugas
  Future<void> deleteTask(String id) async {
    await _tasksRef.doc(id).delete();
  }

  // Menyimpan sesi fokus yang selesai
  Future<void> saveFocusSession(FocusSession session) async {
    await _sessionsRef.doc(session.id).set(session.toMap());
  }

  // Stream untuk sesi fokus berdasarkan User ID
  Stream<List<FocusSession>> getFocusSessionsStream(String userId) {
    return _sessionsRef
        .where('userId', isEqualTo: userId)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FocusSession.fromFirestore(doc.data() as Map<String, dynamic>))
            .toList());
  }
}

final firestoreServiceProvider = Provider((ref) => FirestoreService());
