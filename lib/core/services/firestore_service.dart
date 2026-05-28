import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/task/domain/entities/task.dart';
import '../../features/focus/domain/entities/focus_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Layanan yang mengelola seluruh operasi baca/tulis ke Cloud Firestore.
///
/// Bertanggung jawab atas dua koleksi utama:
/// - **`tasks`**: Data tugas milik pengguna.
/// - **`focus_sessions`**: Riwayat sesi fokus yang telah diselesaikan.
///
/// Semua query difilter berdasarkan `userId` untuk memastikan pengguna
/// hanya dapat mengakses data miliknya sendiri.
///
/// Gunakan [firestoreServiceProvider] untuk mengakses instance-nya via Riverpod.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Referensi ke koleksi `tasks` di Firestore.
  CollectionReference get _tasksRef => _db.collection('tasks');

  /// Referensi ke koleksi `focus_sessions` di Firestore.
  CollectionReference get _sessionsRef => _db.collection('focus_sessions');

  // ─── Tasks ──────────────────────────────────────────────────────────────

  /// Mengembalikan stream real-time daftar tugas milik pengguna dengan [userId].
  ///
  /// Stream ini secara otomatis memperbarui UI setiap kali ada perubahan
  /// di Firestore (tambah, edit, hapus tugas).
  Stream<List<Task>> getTasksStream(String userId) {
    return _tasksRef.where('userId', isEqualTo: userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Task.fromFirestore(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  /// Menambahkan tugas baru ke Firestore.
  ///
  /// Menggunakan `task.id` sebagai document ID agar mudah di-query dan di-update.
  Future<void> addTask(Task task) async {
    await _tasksRef.doc(task.id).set(task.toMap());
  }

  /// Memperbarui data tugas yang sudah ada di Firestore.
  ///
  /// Hanya field yang berubah yang akan diperbarui menggunakan `update()`.
  Future<void> updateTask(Task task) async {
    await _tasksRef.doc(task.id).update(task.toMap());
  }

  /// Menghapus tugas berdasarkan [id] dokumennya dari Firestore.
  Future<void> deleteTask(String id) async {
    await _tasksRef.doc(id).delete();
  }

  // ─── Focus Sessions ──────────────────────────────────────────────────────

  /// Menyimpan satu sesi fokus yang sudah selesai ke Firestore.
  ///
  /// Dipanggil oleh [FocusTimerNotifier] saat timer selesai atau dihentikan
  /// manual (jika durasi > 30 detik).
  Future<void> saveFocusSession(FocusSession session) async {
    await _sessionsRef.doc(session.id).set(session.toMap());
  }

  /// Mengembalikan stream real-time daftar sesi fokus milik pengguna dengan [userId],
  /// diurutkan dari yang paling terbaru.
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

/// Provider untuk mengakses instance [FirestoreService].
final firestoreServiceProvider = Provider((ref) => FirestoreService());
