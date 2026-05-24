import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../domain/entities/task.dart';
import '../../../../core/services/firestore_service.dart';

import '../../../auth/presentation/providers/user_provider.dart';

import '../../../../core/services/notification_service.dart';

class TaskNotifier extends StateNotifier<void> {
  final FirestoreService _firestoreService;
  final NotificationService _notificationService;

  TaskNotifier(this._firestoreService, this._notificationService) : super(null);

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

  Future<void> addTask(Task task) async {
    await _firestoreService.addTask(task);
  }

  Future<void> deleteTask(String id) async {
    await _firestoreService.deleteTask(id);
    // Bersihkan alarm khusus task ini jika dihapus
    await _notificationService.manageTaskDailyReminder(
      taskId: id,
      taskName: '',
      deadline: DateTime.now(), // deadline tidak penting saat disable
      isEnabled: false,
      isCompleted: true, // pastikan alarm dihapus
    );
  }

  Future<void> editTask(Task updatedTask) async {
    await _firestoreService.updateTask(updatedTask);
    
    // Perbarui atau jadwal ulang alarm harian jika posisinya ON
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

  Future<void> updateTaskProgress(Task task, double progress) async {
    final bool willComplete = progress >= 1.0;
    final updatedTask = task.copyWith(
      taskProgress: progress,
      isCompleted: willComplete,
      lastCompletedAt: willComplete ? DateTime.now() : task.lastCompletedAt,
    );
    await _firestoreService.updateTask(updatedTask);
    
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

// Provider untuk aksi/mutasi
final taskActionProvider = Provider((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return TaskNotifier(firestoreService, notificationService);
});

// Provider untuk data real-time berdasarkan User ID
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
        // Async update to Firestore without blocking the stream
        ref.read(taskActionProvider).editTask(resetTask);
      }
    }
    return tasks.map((t) => t.shouldReset ? t.copyWith(isCompleted: false, taskProgress: 0.0) : t).toList();
  });
});