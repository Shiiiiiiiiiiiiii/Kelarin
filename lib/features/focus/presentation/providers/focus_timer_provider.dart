import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../task/domain/entities/task.dart';
import '../../../task/presentation/providers/task_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../auth/presentation/providers/user_provider.dart';
import '../../domain/entities/focus_session.dart';
import 'audio_provider.dart';

class FocusTimerState {
  final int remainingSeconds;
  final int initialSeconds;
  final bool isRunning;
  final Task? selectedTask;
  final bool autoCompleteTask;
  final bool isStrictMode;

  FocusTimerState({
    required this.remainingSeconds,
    required this.initialSeconds,
    required this.isRunning,
    this.selectedTask,
    this.autoCompleteTask = false,
    this.isStrictMode = false,
  });

  FocusTimerState copyWith({
    int? remainingSeconds,
    int? initialSeconds,
    bool? isRunning,
    Task? selectedTask,
    bool? autoCompleteTask,
    bool? isStrictMode,
  }) {
    return FocusTimerState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      initialSeconds: initialSeconds ?? this.initialSeconds,
      isRunning: isRunning ?? this.isRunning,
      selectedTask: selectedTask ?? this.selectedTask,
      autoCompleteTask: autoCompleteTask ?? this.autoCompleteTask,
      isStrictMode: isStrictMode ?? this.isStrictMode,
    );
  }
}

class FocusTimerNotifier extends StateNotifier<FocusTimerState> {
  final Ref _ref;
  Timer? _timer;

  FocusTimerNotifier(this._ref)
      : super(FocusTimerState(remainingSeconds: 1500, initialSeconds: 1500, isRunning: false));

  void setDuration(int seconds) {
    if (state.isRunning) return;
    state = state.copyWith(remainingSeconds: seconds, initialSeconds: seconds);
  }

  void setTask(Task task) {
    state = state.copyWith(
      selectedTask: task,
      remainingSeconds: state.initialSeconds,
      isRunning: false,
    );
    _timer?.cancel();
    _timer = null;
  }

  void toggleAutoComplete(bool value) {
    state = state.copyWith(autoCompleteTask: value);
  }

  void toggleStrictMode(bool value) {
    state = state.copyWith(isStrictMode: value);
  }

  void stopAndSave() {
    _timer?.cancel();
    _timer = null;
    _ref.read(audioProvider.notifier).stopAudio();

    // Save partial progress if there's any
    final elapsed = state.initialSeconds - state.remainingSeconds;
    if (elapsed > 30) { // Only save if more than 30 seconds
      _saveSession(elapsed, completed: false);
    }

    state = FocusTimerState(
      remainingSeconds: state.initialSeconds,
      initialSeconds: state.initialSeconds,
      isRunning: false,
      selectedTask: null,
      autoCompleteTask: state.autoCompleteTask,
      isStrictMode: state.isStrictMode,
    );
  }

  void clearTask() {
    state = state.copyWith(selectedTask: null);
  }

  void start() {
    if (state.isRunning) return;

    state = state.copyWith(isRunning: true);
    _ref.read(audioProvider.notifier).playIfEnabled();
    _timer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        _completeTimer(timer);
      }
    });
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(isRunning: false);
    _ref.read(audioProvider.notifier).pauseAudio();
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(remainingSeconds: state.initialSeconds, isRunning: false);
    _ref.read(audioProvider.notifier).stopAudio();
  }

  void _completeTimer(Timer timer) {
    timer.cancel();
    _timer = null;
    _ref.read(audioProvider.notifier).stopAudio();

    final completedDuration = state.initialSeconds;
    final task = state.selectedTask;
    final shouldComplete = state.autoCompleteTask;

    state = state.copyWith(isRunning: false);

    // Auto-complete linked task if option is enabled
    if (shouldComplete && task != null && !task.isCompleted) {
      _ref.read(taskActionProvider).toggleTask(task);
    }

    _saveSession(completedDuration, completed: true);

    // Trigger local notification
    _ref.read(notificationServiceProvider).showTimerCompleteNotification(
      taskName: task?.title ?? 'Focus Session',
    );
  }

  void _saveSession(int durationSeconds, {required bool completed}) {
    final user = _ref.read(userProvider);
    final task = state.selectedTask;
    
    if (user != null && durationSeconds > 0) {
      final session = FocusSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.id,
        durationSeconds: durationSeconds,
        linkedTaskId: task?.id,
        linkedTaskTitle: task?.title,
        completedAt: DateTime.now(),
      );
      _ref.read(firestoreServiceProvider).saveFocusSession(session);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final focusTimerProvider =
    StateNotifierProvider<FocusTimerNotifier, FocusTimerState>(
  (ref) => FocusTimerNotifier(ref),
);

// Provider untuk stream sesi fokus milik user
final focusSessionsProvider = StreamProvider<List<FocusSession>>((ref) {
  final user = ref.watch(userProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getFocusSessionsStream(user.id);
});