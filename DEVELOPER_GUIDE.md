# 📖 Kelarin — Developer Guide

Panduan ini menjelaskan arsitektur, struktur folder, alur data, dan konvensi kode pada aplikasi **Kelarin**. Baca ini sebelum mulai kontribusi atau menambah fitur baru.

---

## 📌 Daftar Isi

1. [Gambaran Umum Aplikasi](#gambaran-umum-aplikasi)
2. [Struktur Folder](#struktur-folder)
3. [Arsitektur & State Management (Riverpod)](#arsitektur--state-management-riverpod)
4. [Alur Data: Firebase & Firestore](#alur-data-firebase--firestore)
5. [Sistem Notifikasi Lokal](#sistem-notifikasi-lokal)
6. [Alur Navigasi & Screens](#alur-navigasi--screens)
7. [Konvensi Kode](#konvensi-kode)
8. [Cara Menambah Fitur Baru](#cara-menambah-fitur-baru)
9. [Dependency Utama](#dependency-utama)

---

## Gambaran Umum Aplikasi

**Kelarin** adalah aplikasi manajemen tugas dan sesi fokus berbasis Flutter. Aplikasi ini membantu pengguna:
- Membuat dan mengelola tugas dengan prioritas, kategori, dan deadline.
- Menjalankan sesi fokus (Pomodoro-style) dengan timer.
- Menerima notifikasi pengingat harian dan alarm spesifik per tugas.
- Melacak progress belajar/kerja melalui riwayat sesi fokus.

---

## Struktur Folder

```
lib/
├── main.dart                          # Entry point aplikasi
│
├── core/                              # Kode yang digunakan lintas fitur
│   ├── services/
│   │   ├── auth_service.dart          # Autentikasi (Firebase Auth + Google Sign-In)
│   │   ├── firestore_service.dart     # CRUD database (Cloud Firestore)
│   │   └── notification_service.dart  # Notifikasi lokal (flutter_local_notifications)
│   └── theme/
│       ├── app_theme.dart             # Definisi tema terang & gelap
│       └── theme_provider.dart        # Provider untuk toggle dark/light mode
│
├── features/                          # Setiap sub-folder = 1 fitur mandiri
│   ├── auth/
│   │   └── presentation/
│   │       ├── auth_wrapper.dart      # Router: cek status login → arahkan ke screen yang tepat
│   │       ├── providers/
│   │       │   └── user_provider.dart # Provider untuk data User aktif
│   │       └── screens/
│   │           └── auth_screen.dart   # UI Login & Register
│   │
│   ├── focus/
│   │   ├── domain/entities/
│   │   │   └── focus_session.dart     # Model data untuk sesi fokus yang tersimpan
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── audio_provider.dart        # Manajemen audio saat sesi fokus
│   │       │   └── focus_timer_provider.dart  # State & logika timer fokus
│   │       └── screens/
│   │           ├── focus_screen.dart       # Halaman pemilihan tugas & pengaturan timer
│   │           └── focus_timer_screen.dart # Halaman timer berjalan
│   │
│   ├── home/
│   │   └── presentation/
│   │       ├── home_screen.dart            # Halaman utama (daftar tugas hari ini)
│   │       └── providers/
│   │           └── greeting_provider.dart  # Provider sapaan berdasarkan waktu
│   │
│   ├── main/
│   │   └── presentation/
│   │       └── main_screen.dart        # Shell navigasi utama (Bottom Navigation Bar)
│   │
│   ├── onboarding/
│   │   └── presentation/screens/
│   │       └── onboarding_screen.dart  # Layar onboarding untuk pengguna baru
│   │
│   ├── progress/
│   │   └── presentation/
│   │       └── progress_screen.dart   # Halaman statistik & riwayat sesi fokus
│   │
│   ├── settings/
│   │   └── presentation/
│   │       └── settings_screen.dart   # Pengaturan: tema, notifikasi, profil
│   │
│   ├── splash/
│   │   └── presentation/
│   │       └── splash_screen.dart     # Layar splash (loading awal app)
│   │
│   └── task/
│       ├── domain/entities/
│       │   └── task.dart              # Model data tugas (Task entity + enums)
│       └── presentation/
│           ├── providers/
│           │   └── task_provider.dart # State management CRUD tugas + notifikasi
│           └── screens/
│               ├── add_task_screen.dart    # Form tambah/edit tugas
│               └── task_detail_screen.dart # Detail lengkap sebuah tugas
│
└── shared/
    └── widgets/
        └── task_card.dart             # Widget kartu tugas (digunakan di berbagai screen)
```

---

## Arsitektur & State Management (Riverpod)

Kelarin menggunakan **Flutter Riverpod** sebagai solusi state management. Berikut pola yang digunakan:

### Tipe Provider yang Digunakan

| Tipe Provider | Digunakan Untuk | Contoh |
|---|---|---|
| `Provider` | Instance service/objek stateless | `authServiceProvider`, `firestoreServiceProvider` |
| `StreamProvider` | Data real-time dari Firestore | `taskListProvider`, `focusSessionsProvider` |
| `StateNotifierProvider` | State kompleks dengan aksi/mutasi | `focusTimerProvider` |

### Alur State Tugas

```
Firestore (Cloud DB)
        │
        │  real-time stream
        ▼
taskListProvider (StreamProvider)
        │
        │  dibaca oleh
        ▼
  HomeScreen / TaskDetailScreen
        │
        │  aksi user (tambah, edit, hapus, toggle)
        ▼
taskActionProvider (TaskNotifier)
        │
        ├──► firestoreService.updateTask()  → update DB
        └──► notificationService.manage...() → update alarm lokal
```

### Alur State Timer Fokus

```
FocusTimerNotifier (StateNotifier)
        │
        ├── start()  → Timer.periodic setiap 1 detik
        ├── pause()  → Timer dibatalkan, state.isRunning = false
        ├── reset()  → Timer dibatalkan, remainingSeconds reset
        └── _completeTimer()
                ├── Simpan sesi ke Firestore (saveFocusSession)
                ├── Auto-complete tugas jika autoCompleteTask = true
                └── Kirim notifikasi lokal (showTimerCompleteNotification)
```

---

## Alur Data: Firebase & Firestore

### Autentikasi (`auth_service.dart`)

Aplikasi mendukung dua metode login:
1. **Email & Password** via `FirebaseAuth`
2. **Google Sign-In** via `google_sign_in` package

Status login dipantau secara real-time menggunakan `_auth.userChanges()` (bukan `authStateChanges`) — ini penting karena `userChanges()` juga merespons perubahan profil seperti `displayName`.

```
User buka app
    │
    ▼
authStateProvider (StreamProvider<User?>)
    │
    ├── User == null  →  AuthScreen (login/register)
    └── User != null  →  MainScreen (aplikasi utama)
```

### Struktur Data Firestore

**Koleksi `tasks`:**
```
tasks/{taskId}
├── id: String
├── userId: String          # ID pemilik tugas (untuk keamanan query)
├── title: String
├── description: String
├── priority: String        # 'low' | 'medium' | 'high'
├── category: String
├── isCompleted: bool
├── taskProgress: double    # 0.0 s/d 1.0
├── dueDate: String?        # ISO 8601 format
├── isDailyReminderEnabled: bool
├── recurrence: String      # 'none' | 'daily' | 'weekly' | 'monthly'
└── lastCompletedAt: String? # ISO 8601 format
```

**Koleksi `focus_sessions`:**
```
focus_sessions/{sessionId}
├── id: String
├── userId: String
├── durationSeconds: int
├── linkedTaskId: String?
├── linkedTaskTitle: String?
└── completedAt: String     # ISO 8601 format
```

> **Catatan Keamanan**: Setiap query ke Firestore selalu difilter dengan `where('userId', isEqualTo: userId)` sehingga pengguna hanya bisa mengakses data miliknya sendiri.

---

## Sistem Notifikasi Lokal

Kelarin menggunakan `flutter_local_notifications` untuk mengirim notifikasi tanpa server. Ada **4 tipe notifikasi** dengan channel masing-masing:

### Channel Notifikasi Android

| Channel ID | Nama | Kepentingan | Digunakan Untuk |
|---|---|---|---|
| `focus_timer_channel` | Focus Timer Notifications | Max | Notifikasi saat timer fokus selesai |
| `daily_reminder_channel` | Daily Reminder | High | Pengingat harian jam 07.00 pagi |
| `task_reminder_channel` | Task Reminders | Max | Pengingat spesifik deadline 1 tugas |
| `daily_task_channel` | Daily Task Reminders | Max | Countdown harian per tugas (hingga 30 hari ke depan) |

### Kenapa Pakai SharedPreferences untuk Status Reminder?

```dart
// BENAR: Simpan status di SharedPreferences
final prefs = await SharedPreferences.getInstance();
await prefs.setBool('pref_daily_reminder_enabled', true);

// SALAH: Jangan cek via pendingNotificationRequests()
// Inexact alarms TIDAK muncul di pending requests!
```

`inexactAllowWhileIdle` digunakan untuk penghematan baterai, tapi konsekuensinya alarm tidak terdaftar di `pendingNotificationRequests()`. Karena itu status ON/OFF selalu disimpan secara manual ke SharedPreferences.

### Strategi ID Notifikasi

Untuk menghindari konflik ID antar notifikasi:

| Tipe | ID | Keterangan |
|---|---|---|
| Timer selesai | `0` | Selalu ID tetap |
| Daily app reminder | `1` | Selalu ID tetap |
| Task reminder | `taskId.hashCode` | Hash dari string ID tugas |
| Daily task countdown | `10000 + (taskId.hashCode.abs() % 100000) * 100 + i` | Base unik per tugas + offset hari |

### Fallback Exact → Inexact Alarm

```dart
try {
  // Coba exact alarm (butuh izin SCHEDULE_EXACT_ALARM di Android 12+)
  await plugin.zonedSchedule(..., androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);
} catch (e) {
  // Fallback ke inexact jika izin tidak diberikan user
  await plugin.zonedSchedule(..., androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle);
}
```

---

## Alur Navigasi & Screens

```
App Start
    └── SplashScreen
            │
            └── AuthWrapper
                    │
                    ├── [Belum login] ──► OnboardingScreen ──► AuthScreen
                    │
                    └── [Sudah login] ──► MainScreen
                                              │
                                    ┌─────────┼──────────┐
                                    ▼         ▼          ▼
                               HomeScreen  FocusScreen  ProgressScreen
                                    │         │
                                    │     FocusTimerScreen
                               TaskDetailScreen
                                    │
                               AddTaskScreen (edit)
```

---

## Konvensi Kode

### Penamaan File
- Semua nama file menggunakan `snake_case`: `task_provider.dart`, `focus_screen.dart`
- Entity model diletakkan di `features/{feature}/domain/entities/`
- Provider diletakkan di `features/{feature}/presentation/providers/`
- Screen diletakkan di `features/{feature}/presentation/screens/`

### Penamaan Provider
- Service → `{name}Provider` (contoh: `authServiceProvider`)
- State stream → `{name}Provider` (contoh: `taskListProvider`, `focusSessionsProvider`)
- Aksi/mutasi → `{name}ActionProvider` (contoh: `taskActionProvider`)
- State notifier → `{name}Provider` yang mengembalikan `StateNotifierProvider` (contoh: `focusTimerProvider`)

### Dokumentasi Kode (Dart Docs)
Gunakan `///` untuk mendokumentasikan class, method, dan property publik.

```dart
/// Menjadwalkan pengingat harian untuk sebuah tugas spesifik.
/// 
/// Membuat hingga [daysToSchedule] notifikasi (maksimal 30) yang
/// dijadwalkan setiap hari jam 07.00 pagi hingga deadline tugas.
/// 
/// [taskId] digunakan untuk menghasilkan base ID notifikasi yang unik.
/// [isEnabled] dan [isCompleted] menentukan apakah alarm perlu dibuat atau dibersihkan.
Future<void> manageTaskDailyReminder({...}) async { ... }
```

---

## Cara Menambah Fitur Baru

Ikuti pola yang sudah ada dengan langkah berikut:

### 1. Buat Folder Fitur
```
lib/features/{nama_fitur}/
├── domain/
│   └── entities/
│       └── {nama_model}.dart    ← Model data (immutable, punya toMap/fromFirestore)
└── presentation/
    ├── providers/
    │   └── {nama}_provider.dart ← State management
    └── screens/
        └── {nama}_screen.dart   ← UI
```

### 2. Buat Entity/Model
```dart
class MyModel {
  final String id;
  final String userId; // Selalu sertakan userId!

  const MyModel({required this.id, required this.userId});

  Map<String, dynamic> toMap() => {'id': id, 'userId': userId};

  factory MyModel.fromFirestore(Map<String, dynamic> map) {
    return MyModel(id: map['id'], userId: map['userId']);
  }
}
```

### 3. Tambah CRUD ke `FirestoreService`
```dart
// Di dalam class FirestoreService:
CollectionReference get _myRef => _db.collection('my_collection');

Future<void> addMyModel(MyModel model) async {
  await _myRef.doc(model.id).set(model.toMap());
}

Stream<List<MyModel>> getMyModelsStream(String userId) {
  return _myRef
    .where('userId', isEqualTo: userId)
    .snapshots()
    .map((snap) => snap.docs
      .map((doc) => MyModel.fromFirestore(doc.data() as Map<String, dynamic>))
      .toList());
}
```

### 4. Buat Provider
```dart
// Provider data real-time
final myModelListProvider = StreamProvider<List<MyModel>>((ref) {
  final user = ref.watch(userProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getMyModelsStream(user.id);
});
```

### 5. Tambah ke Navigasi
Daftarkan screen baru ke `main_screen.dart` jika perlu muncul di bottom navigation.

---

## Dependency Utama

| Package | Versi | Fungsi |
|---|---|---|
| `flutter_riverpod` | ^2.x | State management |
| `firebase_core` | - | Inisialisasi Firebase |
| `firebase_auth` | - | Autentikasi pengguna |
| `cloud_firestore` | - | Database real-time |
| `google_sign_in` | - | Login via Google |
| `flutter_local_notifications` | ^18.x | Notifikasi lokal |
| `timezone` | - | Timezone-aware scheduling |
| `flutter_timezone` | - | Deteksi timezone perangkat |
| `shared_preferences` | - | Penyimpanan key-value lokal |

---

> Dibuat dengan ❤️ untuk memudahkan pengembangan Kelarin.
