/// Tingkat prioritas sebuah tugas.
///
/// Digunakan untuk mengelompokkan dan mengurutkan tugas berdasarkan urgensinya.
/// Nilai disimpan ke Firestore sebagai string (nama enum: `'low'`, `'medium'`, `'high'`).
enum TaskPriority { low, medium, high }

/// Pola pengulangan sebuah tugas.
///
/// Saat sebuah tugas yang berulang ditandai selesai, tugas tersebut akan
/// direset otomatis (isCompleted → false, progress → 0.0) saat dibuka kembali
/// setelah periode pengulangan berakhir. Logika reset ada di getter [Task.shouldReset].
///
/// Nilai disimpan ke Firestore sebagai string (nama enum: `'none'`, `'daily'`, dll).
enum TaskRecurrence { none, daily, weekly, monthly }

/// Model data yang merepresentasikan sebuah tugas (task) di aplikasi Kelarin.
///
/// Kelas ini bersifat **immutable** — semua properti adalah `final`.
/// Untuk mengubah nilai, gunakan method [copyWith].
///
/// **Penyimpanan**: Data tugas disimpan di Firestore dengan struktur yang
/// didefinisikan oleh [toMap] dan dipulihkan via [Task.fromFirestore].
///
/// **Notifikasi**: Field [isDailyReminderEnabled] mengontrol apakah alarm harian
/// countdown diaktifkan untuk tugas ini. Perubahan pada field ini akan secara
/// otomatis memicu update alarm di [NotificationService] via [TaskNotifier].
class Task {
  /// ID unik tugas, biasanya dihasilkan dari timestamp atau UUID.
  final String id;

  /// ID pengguna pemilik tugas. Digunakan untuk memfilter query Firestore
  /// agar pengguna hanya bisa mengakses datanya sendiri.
  final String userId;

  /// Judul singkat tugas yang ditampilkan di daftar.
  final String title;

  /// Deskripsi atau catatan detail tentang tugas ini.
  final String description;

  /// Tingkat prioritas tugas (rendah, sedang, tinggi).
  final TaskPriority priority;

  /// Label kategori tugas, misalnya "Kuliah", "Pribadi", dll.
  final String category;

  /// Status penyelesaian tugas. `true` berarti tugas sudah selesai.
  final bool isCompleted;

  /// Progres penyelesaian tugas dalam rentang `0.0` (belum dimulai) hingga `1.0` (selesai).
  /// Saat [isCompleted] menjadi `true`, nilai ini diset ke `1.0`.
  final double taskProgress;

  /// Tanggal batas waktu (deadline) penyelesaian tugas. Bisa `null` jika tidak ada deadline.
  final DateTime? dueDate;

  /// Apakah reminder harian countdown aktif untuk tugas ini.
  /// Jika `true`, [NotificationService.manageTaskDailyReminder] akan menjadwalkan
  /// alarm setiap jam 07.00 pagi hingga deadline.
  final bool isDailyReminderEnabled;

  /// Pola pengulangan tugas. Default-nya [TaskRecurrence.none] (tidak berulang).
  final TaskRecurrence recurrence;

  /// Timestamp terakhir tugas ini diselesaikan. Digunakan oleh [shouldReset]
  /// untuk menentukan apakah tugas perlu direset berdasarkan pola pengulangan.
  final DateTime? lastCompletedAt;

  const Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
    this.isCompleted = false,
    this.taskProgress = 0.0,
    this.dueDate,
    this.isDailyReminderEnabled = false,
    this.recurrence = TaskRecurrence.none,
    this.lastCompletedAt,
  });

  /// Membuat salinan tugas dengan beberapa field yang diubah.
  ///
  /// Field yang tidak disertakan akan menggunakan nilai dari objek saat ini.
  Task copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    TaskPriority? priority,
    bool? isCompleted,
    double? taskProgress,
    DateTime? dueDate,
    String? category,
    bool? isDailyReminderEnabled,
    TaskRecurrence? recurrence,
    DateTime? lastCompletedAt,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      taskProgress: taskProgress ?? this.taskProgress,
      dueDate: dueDate ?? this.dueDate,
      isDailyReminderEnabled: isDailyReminderEnabled ?? this.isDailyReminderEnabled,
      recurrence: recurrence ?? this.recurrence,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
    );
  }

  /// Mengonversi objek Task menjadi Map untuk disimpan ke Firestore.
  ///
  /// Tanggal disimpan dalam format ISO 8601 string agar kompatibel dengan Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'priority': priority.name,
      'category': category,
      'isCompleted': isCompleted,
      'taskProgress': taskProgress,
      'dueDate': dueDate?.toIso8601String(),
      'isDailyReminderEnabled': isDailyReminderEnabled,
      'recurrence': recurrence.name,
      'lastCompletedAt': lastCompletedAt?.toIso8601String(),
    };
  }

  /// Membuat objek Task dari data dokumen Firestore.
  ///
  /// Memberikan nilai default yang aman jika field tidak ada di dokumen,
  /// untuk menjaga kompatibilitas mundur saat ada penambahan field baru.
  factory Task.fromFirestore(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == (map['priority'] ?? 'low'),
        orElse: () => TaskPriority.low,
      ),
      category: map['category'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      taskProgress: (map['taskProgress'] ?? 0.0).toDouble(),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      isDailyReminderEnabled: map['isDailyReminderEnabled'] ?? false,
      recurrence: TaskRecurrence.values.firstWhere(
        (e) => e.name == (map['recurrence'] ?? 'none'),
        orElse: () => TaskRecurrence.none,
      ),
      lastCompletedAt: map['lastCompletedAt'] != null ? DateTime.parse(map['lastCompletedAt']) : null,
    );
  }

  /// Menentukan apakah tugas berulang ini perlu direset ke status belum selesai.
  ///
  /// Mengembalikan `true` jika:
  /// - Tugas sudah selesai ([isCompleted] = true)
  /// - Tugas punya riwayat penyelesaian ([lastCompletedAt] tidak null)
  /// - Tugas bersifat berulang ([recurrence] != none)
  /// - Periode pengulangan sudah berakhir sejak terakhir diselesaikan
  ///
  /// Dipanggil di `taskListProvider` setiap kali data dari Firestore diterima.
  bool get shouldReset {
    if (!isCompleted || lastCompletedAt == null || recurrence == TaskRecurrence.none) return false;
    
    final now = DateTime.now();
    final last = lastCompletedAt!;
    
    switch (recurrence) {
      case TaskRecurrence.daily:
        // Reset jika sudah berganti hari
        return now.day != last.day || now.month != last.month || now.year != last.year;
      case TaskRecurrence.weekly:
        final daysDiff = now.difference(last).inDays;
        if (daysDiff >= 7) return true;
        // Reset jika sudah berganti minggu (Senin = 1 di Dart DateTime)
        if (now.weekday < last.weekday && daysDiff > 0) return true;
        return false;
      case TaskRecurrence.monthly:
        // Reset jika sudah berganti bulan
        return now.month != last.month || now.year != last.year;
      case TaskRecurrence.none:
        return false;
    }
  }
}