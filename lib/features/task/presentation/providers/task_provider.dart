import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../domain/entities/task.dart';
import '../../../../core/services/firestore_service.dart';

import '../../../auth/presentation/providers/user_provider.dart';

import '../../../../core/services/notification_service.dart';

/// Notifier yang mengelola semua operasi mutasi (CRUD) pada data tugas.
///
/// Bertindak sebagai jembatan antara UI, [FirestoreService], dan [NotificationService].
/// Setiap operasi akan memperbarui database Firestore dan secara otomatis
/// menyesuaikan alarm notifikasi yang terdaftar di perangkat.
///
/// Gunakan [taskActionProvider] untuk mengakses instance ini.
/// Untuk membaca daftar tugas secara real-time, gunakan [taskListProvider].
class TaskNotifier extends StateNotifier<void> {
  final FirestoreService _firestoreService;
  final NotificationService _notificationService;

  TaskNotifier(this._firestoreService, this._notificationService) : super(null);

  /// Mengubah status penyelesaian tugas (toggle selesai/belum selesai).
  ///
  /// Saat tugas ditandai **selesai**: progress diset ke `1.0` dan `lastCompletedAt` diperbarui.
  /// Saat tugas **dibatalkan selesainya**: progress tetap di `0.0`.
  ///
  /// Jika reminder harian aktif, alarm notifikasi akan diperbarui sesuai
  /// status penyelesaian baru (alarm dihapus jika tugas selesai).
  Future<void> toggleTask(Task task) async {
    final bool willComplete = !task.isCompleted;
    final updatedTask = task.copyWith(
      isCompleted: willComplete,
      taskProgress: willComplete ? 1.0 : 0.0,
      lastCompletedAt: willComplete ? DateTime.now() : task.lastCompletedAt,
    );
    await _firestoreService.updateTask(updatedTask);
    
    if (updatedTask.isDailyReminderEnabled) {
      await _notificationService.manageTaskDailyReminder(
        taskId: updatedTask.id,
        taskName: updatedTask.title,
        deadline: updatedTask.dueDate,
        isEnabled: updatedTask.isDailyReminderEnabled,
        isCompleted: updatedTask.isCompleted,
      );
    }
  }

  /// Menambahkan tugas baru ke Firestore.
  Future<void> addTask(Task task) async {
    await _firestoreService.addTask(task);
  }

  /// Menghapus tugas dari Firestore dan membersihkan semua alarm terkait.
  ///
  /// Alarm notifikasi untuk tugas yang dihapus selalu dibersihkan
  /// dengan memanggil [NotificationService.manageTaskDailyReminder]
  /// dengan `isEnabled: false` dan `isCompleted: true`.
  Future<void> deleteTask(String id) async {
    await _firestoreService.deleteTask(id);
    // Bersihkan alarm khusus task ini
    await _notificationService.manageTaskDailyReminder(
      taskId: id,
      taskName: '',
      deadline: DateTime.now(),
      isEnabled: false,
      isCompleted: true,
    );
  }

  /// Memperbarui data tugas yang sudah ada dan menjadwalkan ulang alarm jika diperlukan.
  ///
  /// Jika reminder harian aktif, alarm dijadwalkan ulang dari awal untuk
  /// mengakomodasi perubahan judul, deadline, atau status reminder.
  Future<void> editTask(Task updatedTask) async {
    await _firestoreService.updateTask(updatedTask);
    
    // Jadwalkan ulang alarm harian jika reminder aktif
    if (updatedTask.isDailyReminderEnabled) {
      await _notificationService.manageTaskDailyReminder(
        taskId: updatedTask.id,
        taskName: updatedTask.title,
        deadline: updatedTask.dueDate,
        isEnabled: true,
        isCompleted: updatedTask.isCompleted,
      );
    }
  }

  /// Memperbarui nilai progress tugas dalam rentang `0.0` hingga `1.0`.
  ///
  /// Jika [progress] mencapai atau melebihi `1.0`, tugas secara otomatis
  /// ditandai selesai dan alarm harian dihapus.
  Future<void> updateTaskProgress(Task task, double progress) async {
    final bool willComplete = progress >= 1.0;
    final updatedTask = task.copyWith(
      taskProgress: progress,
      isCompleted: willComplete,
      lastCompletedAt: willComplete ? DateTime.now() : task.lastCompletedAt,
    );
    await _firestoreService.updateTask(updatedTask);
    
    // Hapus alarm saat tugas selesai via progress bar
    if (updatedTask.isDailyReminderEnabled && updatedTask.isCompleted) {
       await _notificationService.manageTaskDailyReminder(
        taskId: updatedTask.id,
        taskName: updatedTask.title,
        deadline: updatedTask.dueDate,
        isEnabled: false,
        isCompleted: true,
      );
    }
  }
}

/// Provider untuk aksi/mutasi tugas. Gunakan ini untuk memanggil operasi
/// seperti tambah, edit, hapus, dan toggle tugas.
final taskActionProvider = Provider((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return TaskNotifier(firestoreService, notificationService);
});

/// Provider untuk membaca daftar tugas secara real-time dari Firestore.
///
/// Stream ini secara otomatis:
/// - Mengambil tugas milik pengguna yang sedang login.
/// - Mereset tugas berulang yang sudah melewati periode ulangnya ([Task.shouldReset]).
/// - Memancarkan list kosong (`[]`) jika tidak ada pengguna yang login.
///
/// Reset tugas berulang dilakukan dengan mengupdate Firestore secara async
/// tanpa memblokir stream UI.
final taskListProvider = StreamProvider<List<Task>>((ref) {
  final user = ref.watch(userProvider);
  if (user == null) return Stream.value([]);
  
  return ref.watch(firestoreServiceProvider).getTasksStream(user.id).map((tasks) {
    for (var task in tasks) {
      if (task.shouldReset) {
        final resetTask = task.copyWith(
          isCompleted: false, 
          taskProgress: 0.0,
        );
        // Update Firestore secara async tanpa memblokir pembaruan UI
        ref.read(taskActionProvider).editTask(resetTask);
      }
    }
    // Tampilkan status reset di UI secara langsung tanpa menunggu respons Firestore
    return tasks.map((t) => t.shouldReset ? t.copyWith(isCompleted: false, taskProgress: 0.0) : t).toList();
  });
});