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

/// State (data) yang merepresentasikan kondisi timer fokus saat ini.
///
/// Kelas ini bersifat **immutable**. Setiap perubahan menghasilkan objek baru
/// via [copyWith], yang memicu pembaruan UI secara reaktif di Riverpod.
class FocusTimerState {
  /// Sisa waktu timer dalam satuan detik.
  final int remainingSeconds;

  /// Durasi awal yang dipilih pengguna dalam satuan detik.
  /// Digunakan untuk mereset timer ke posisi awal.
  final int initialSeconds;

  /// Apakah timer sedang berjalan (`true`) atau berhenti/dijeda (`false`).
  final bool isRunning;

  /// Tugas yang sedang dikerjakan dalam sesi fokus ini. Bisa `null` jika
  /// pengguna memulai sesi tanpa memilih tugas.
  final Task? selectedTask;

  /// Jika `true`, tugas yang sedang terhubung akan otomatis ditandai selesai
  /// saat timer berakhir.
  final bool autoCompleteTask;

  /// Jika `true`, pengguna tidak dapat meninggalkan layar timer saat sedang berjalan.
  final bool isStrictMode;

  FocusTimerState({
    required this.remainingSeconds,
    required this.initialSeconds,
    required this.isRunning,
    this.selectedTask,
    this.autoCompleteTask = false,
    this.isStrictMode = false,
  });

  /// Membuat salinan state dengan beberapa field yang diubah.
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

/// Notifier yang mengelola logika dan state timer fokus (sesi Pomodoro-style).
///
/// Mengelola siklus hidup timer menggunakan `dart:async Timer` dan
/// berinteraksi dengan tiga layanan lain:
/// - [NotificationService]: mengirim notifikasi saat timer selesai.
/// - [FirestoreService]: menyimpan riwayat sesi fokus.
/// - [TaskNotifier]: auto-complete tugas terhubung saat timer selesai.
///
/// Gunakan [focusTimerProvider] untuk mengakses instance ini.
class FocusTimerNotifier extends StateNotifier<FocusTimerState> {
  final Ref _ref;

  /// Timer internal Dart yang berdetak setiap 1 detik. `null` saat timer tidak berjalan.
  Timer? _timer;

  /// State awal: 25 menit (1500 detik), tidak berjalan, tanpa tugas terpilih.
  FocusTimerNotifier(this._ref)
      : super(FocusTimerState(remainingSeconds: 1500, initialSeconds: 1500, isRunning: false));

  /// Mengubah durasi timer. Hanya bisa dilakukan saat timer tidak berjalan.
  ///
  /// Mengupdate [FocusTimerState.remainingSeconds] dan [FocusTimerState.initialSeconds]
  /// sekaligus agar tombol reset selalu kembali ke durasi yang baru diset.
  void setDuration(int seconds) {
    if (state.isRunning) return;
    state = state.copyWith(remainingSeconds: seconds, initialSeconds: seconds);
  }

  /// Menghubungkan sebuah tugas ke sesi fokus ini dan mereset timer ke awal.
  ///
  /// Jika ada timer yang sedang berjalan, timer akan dibatalkan dan state
  /// direset sehingga pengguna harus memulai ulang secara manual.
  void setTask(Task task) {
    state = state.copyWith(
      selectedTask: task,
      remainingSeconds: state.initialSeconds,
      isRunning: false,
    );
    _timer?.cancel();
    _timer = null;
  }

  /// Mengubah preferensi auto-complete tugas saat timer selesai.
  void toggleAutoComplete(bool value) {
    state = state.copyWith(autoCompleteTask: value);
  }

  /// Mengubah mode ketat (strict mode) — mencegah pengguna meninggalkan layar timer.
  void toggleStrictMode(bool value) {
    state = state.copyWith(isStrictMode: value);
  }

  /// Menghentikan timer, menyimpan progres parsial, dan mereset state ke awal.
  ///
  /// Sesi parsial disimpan ke Firestore hanya jika pengguna sudah berfokus
  /// lebih dari 30 detik (menghindari data sesi yang tidak berarti).
  void stopAndSave() {
    _timer?.cancel();
    _timer = null;
    _ref.read(audioProvider.notifier).stopAudio();

    final elapsed = state.initialSeconds - state.remainingSeconds;
    if (elapsed > 30) {
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

  /// Menghapus tugas yang sedang terhubung dari state tanpa menghentikan timer.
  void clearTask() {
    state = state.copyWith(selectedTask: null);
  }

  /// Memulai atau melanjutkan timer.
  ///
  /// Menggunakan `_timer ??=` (null-coalescing assignment) untuk memastikan
  /// hanya ada satu Timer instance yang berjalan pada satu waktu.
  /// Audio sesi fokus juga diaktifkan saat ini.
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

  /// Menjeda timer tanpa mereset countdown.
  ///
  /// Timer (`_timer`) dibatalkan dan di-null-kan sehingga pemanggilan [start]
  /// berikutnya akan membuat Timer baru dari posisi yang sama.
  void pause() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(isRunning: false);
    _ref.read(audioProvider.notifier).pauseAudio();
  }

  /// Mereset timer ke [FocusTimerState.initialSeconds] tanpa menyimpan sesi.
  void reset() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(remainingSeconds: state.initialSeconds, isRunning: false);
    _ref.read(audioProvider.notifier).stopAudio();
  }

  /// Dipanggil secara internal saat countdown mencapai nol.
  ///
  /// Urutan operasi yang dilakukan:
  /// 1. Hentikan timer dan audio.
  /// 2. Auto-complete tugas terhubung jika opsi aktif.
  /// 3. Simpan sesi lengkap ke Firestore.
  /// 4. Kirim notifikasi lokal ke pengguna.
  void _completeTimer(Timer timer) {
    timer.cancel();
    _timer = null;
    _ref.read(audioProvider.notifier).stopAudio();

    final completedDuration = state.initialSeconds;
    final task = state.selectedTask;
    final shouldComplete = state.autoCompleteTask;

    state = state.copyWith(isRunning: false);

    // Auto-complete tugas terhubung jika opsi diaktifkan
    if (shouldComplete && task != null && !task.isCompleted) {
      _ref.read(taskActionProvider).toggleTask(task);
    }

    _saveSession(completedDuration, completed: true);

    // Kirim notifikasi lokal sebagai tanda sesi selesai
    _ref.read(notificationServiceProvider).showTimerCompleteNotification(
      taskName: task?.title ?? 'Focus Session',
    );
  }

  /// Menyimpan data sesi fokus ke Firestore.
  ///
  /// ID sesi menggunakan `millisecondsSinceEpoch` sebagai string untuk
  /// memastikan keunikan tanpa memerlukan UUID.
  ///
  /// Sesi tidak disimpan jika tidak ada pengguna yang login atau durasi = 0.
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

  /// Membersihkan timer saat provider di-dispose untuk mencegah memory leak.
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Provider utama untuk state dan kontrol timer fokus.
///
/// Gunakan `ref.watch(focusTimerProvider)` untuk membaca [FocusTimerState].
/// Gunakan `ref.read(focusTimerProvider.notifier)` untuk memanggil aksi seperti
/// `start()`, `pause()`, `reset()`, dll.
final focusTimerProvider =
    StateNotifierProvider<FocusTimerNotifier, FocusTimerState>(
  (ref) => FocusTimerNotifier(ref),
);

/// Provider untuk mengambil riwayat sesi fokus pengguna secara real-time dari Firestore,
/// diurutkan dari yang paling terbaru.
///
/// Memancarkan list kosong (`[]`) jika tidak ada pengguna yang sedang login.
final focusSessionsProvider = StreamProvider<List<FocusSession>>((ref) {
  final user = ref.watch(userProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getFocusSessionsStream(user.id);
});