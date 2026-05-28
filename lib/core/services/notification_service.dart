import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

/// Provider untuk mengakses instance [NotificationService] yang sudah diinisialisasi.
///
/// Instance ini di-override di `main.dart` dengan instance yang telah dipanggil [init]-nya,
/// memastikan notifikasi siap digunakan di seluruh aplikasi.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Layanan yang mengelola seluruh notifikasi lokal aplikasi Kelarin.
///
/// Menggunakan `flutter_local_notifications` sebagai engine utama dan mendukung
/// Android serta iOS. Terdapat empat jenis notifikasi:
///
/// 1. **Timer Selesai** (`focus_timer_channel`): Dikirim saat sesi fokus berakhir.
/// 2. **Daily App Reminder** (`daily_reminder_channel`): Pengingat harian jam 07.00.
/// 3. **Task Deadline Reminder** (`task_reminder_channel`): Alarm sekali untuk deadline spesifik.
/// 4. **Daily Task Countdown** (`daily_task_channel`): Alarm harian countdown per tugas.
///
/// **Penting — Strategi ID Notifikasi:**
/// - Timer selesai: ID `0`
/// - Daily app reminder: ID `1`
/// - Task reminder: `taskId.hashCode`
/// - Daily task countdown: `10000 + (taskId.hashCode.abs() % 100000) * 100 + dayOffset`
class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Key SharedPreferences untuk menyimpan status daily reminder app.
  ///
  /// Kita tidak menggunakan `pendingNotificationRequests()` untuk mengecek status
  /// karena `inexactAllowWhileIdle` alarm tidak terdaftar di sana, sehingga
  /// statusnya akan selalu terlihat OFF meski sudah dijadwalkan.
  static const String _dailyReminderPrefKey = 'pref_daily_reminder_enabled';

  /// Flag untuk memastikan [init] hanya dijalankan sekali selama siklus hidup app.
  bool _isInitialized = false;

  /// Menginisialisasi plugin notifikasi, timezone lokal, izin, dan channel Android.
  ///
  /// Harus dipanggil sekali di `main()` sebelum `runApp()`.
  /// Operasi ini idempoten — pemanggilan kedua akan langsung dikembalikan.
  Future<void> init() async {
    if (_isInitialized) return;

    // Inisialisasi database timezone dan set ke timezone lokal perangkat
    tz.initializeTimeZones();
    try {
      final dynamic tzInfo = await FlutterTimezone.getLocalTimezone();
      // Di versi 5.x+, propertinya adalah 'identifier', bukan 'name'
      final String name = tzInfo is String ? tzInfo : (tzInfo.identifier ?? tzInfo.toString());
      
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Fallback ke UTC jika timezone perangkat tidak dapat dideteksi
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // Android Initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS Initialization
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
      },
    );

    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      // Minta izin notifikasi dan exact alarm (Android 12+)
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }

    _isInitialized = true;

    // Buat semua notification channels secara eksplisit.
    // Channel harus dibuat sebelum notifikasi pertama dikirim.
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'daily_reminder_channel',
          'Daily Reminder',
          description: 'Daily reminder to check your tasks',
          importance: Importance.high,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'daily_task_channel',
          'Daily Task Reminders',
          description: 'Daily countdown for specific tasks',
          importance: Importance.max,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'task_reminder_channel',
          'Task Reminders',
          description: 'Reminders for specific tasks',
          importance: Importance.max,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'focus_timer_channel',
          'Focus Timer Notifications',
          description: 'Notification fired when a focus timer completes',
          importance: Importance.max,
        ),
      );
    }
  }

  // ─── Focus Timer ─────────────────────────────────────────────────────────

  /// Menampilkan notifikasi langsung (immediate) saat sesi fokus selesai.
  ///
  /// Dipanggil oleh [FocusTimerNotifier._completeTimer] saat countdown mencapai nol.
  /// Menggunakan ID `0` sebagai ID notifikasi yang tetap (tidak dijadwalkan).
  Future<void> showTimerCompleteNotification({
    required String taskName,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'focus_timer_channel',
      'Focus Timer Notifications',
      channelDescription: 'Notification fired when a focus timer completes',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id: 0,
      title: 'Focus Session Complete',
      body: 'Great job on "$taskName"! Take a break.',
      notificationDetails: notificationDetails,
      payload: 'focus_complete',
    );
  }

  // ─── Daily App Reminder ───────────────────────────────────────────────────

  /// Menjadwalkan pengingat harian aplikasi setiap jam 07.00 pagi.
  ///
  /// Menggunakan `matchDateTimeComponents: DateTimeComponents.time` agar notifikasi
  /// berulang setiap hari di jam yang sama (bukan hanya sekali).
  ///
  /// Status dijadwalkan disimpan ke SharedPreferences dengan key [_dailyReminderPrefKey].
  /// **Jangan** gunakan `pendingNotificationRequests()` untuk mengecek status ini
  /// karena `inexactAllowWhileIdle` tidak akan muncul di daftar tersebut.
  Future<void> scheduleDailyReminder() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminder',
      channelDescription: 'Daily reminder to check your tasks',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Hitung waktu jadwal berikutnya: jam 07.00 hari ini, atau besok jika sudah lewat
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      7,
      00,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: 1,
      title: 'Stay Productive!',
      body: 'Check Kelarin and finish your tasks for today!',
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // Simpan status ke SharedPreferences — jangan andalkan pendingNotificationRequests()
    // karena inexact alarms tidak muncul di sana
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailyReminderPrefKey, true);
  }

  /// Membatalkan pengingat harian aplikasi dan memperbarui status di SharedPreferences.
  Future<void> cancelDailyReminder() async {
    await _flutterLocalNotificationsPlugin.cancel(id: 1);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailyReminderPrefKey, false);
  }

  /// Membaca status pengingat harian dari SharedPreferences.
  ///
  /// **Selalu** gunakan metode ini (bukan `pendingNotificationRequests()`) untuk
  /// mengecek apakah reminder aktif, karena inexact alarms tidak terdaftar
  /// di pending requests sehingga status akan selalu terlihat OFF jika tidak
  /// menggunakan SharedPreferences.
  Future<bool> isDailyReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dailyReminderPrefKey) ?? false;
  }

  // ─── Task-Specific Reminders ──────────────────────────────────────────────

  /// Menjadwalkan satu notifikasi pengingat untuk deadline sebuah tugas.
  ///
  /// Notifikasi akan dikirim pada [scheduledTime] dengan pesan yang menyebutkan
  /// berapa hari tersisa hingga [deadline].
  ///
  /// ID notifikasi dihasilkan dari `taskId.hashCode` untuk memastikan
  /// setiap tugas memiliki ID unik yang konsisten.
  ///
  /// Pertama mencoba menggunakan `exactAllowWhileIdle` (membutuhkan izin
  /// SCHEDULE_EXACT_ALARM di Android 12+). Jika gagal karena izin tidak diberikan,
  /// otomatis fallback ke `inexactAllowWhileIdle`.
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String taskName,
    required DateTime deadline,
    required DateTime scheduledTime,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_reminder_channel',
      'Task Reminders',
      channelDescription: 'Reminders for specific tasks',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final daysLeft = deadline.difference(scheduledTime).inDays;
    final String timeMessage = daysLeft <= 0 
        ? 'Deadline is today!' 
        : 'You have ${daysLeft == 1 ? '1 day' : '$daysLeft days'} left.';
    
    // Gunakan hash dari string ID tugas sebagai integer ID notifikasi
    final notificationId = taskId.hashCode;

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: notificationId,
        title: 'Reminder: $taskName',
        body: timeMessage,
        scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      // Fallback ke inexact jika izin exact alarm tidak diberikan pengguna
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: notificationId,
        title: 'Reminder: $taskName',
        body: timeMessage,
        scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  /// Mengelola jadwal notifikasi harian countdown untuk sebuah tugas spesifik.
  ///
  /// Fungsi ini bersifat **idempoten**: selalu membersihkan semua alarm lama
  /// untuk tugas ini terlebih dahulu, lalu membuat ulang jika diperlukan.
  ///
  /// Notifikasi **tidak** akan dibuat jika salah satu kondisi berikut terpenuhi:
  /// - [isEnabled] bernilai `false`
  /// - [deadline] bernilai `null`
  /// - [isCompleted] bernilai `true`
  /// - Deadline sudah terlewat
  ///
  /// **Strategi ID**: Base ID = `10000 + (taskId.hashCode.abs() % 100000) * 100`.
  /// Setiap hari ke-i mendapat ID `baseId + i`. Rumus ini memastikan tidak ada
  /// konflik ID antar tugas yang berbeda, dan menyediakan slot hingga 100 hari per tugas.
  ///
  /// **Batas maksimal**: Hanya menjadwalkan hingga 30 hari ke depan untuk menghindari
  /// terlalu banyak alarm terdaftar di sistem.
  Future<void> manageTaskDailyReminder({
    required String taskId,
    required String taskName,
    required DateTime? deadline,
    required bool isEnabled,
    required bool isCompleted,
  }) async {
    // Hitung base ID unik untuk tugas ini
    final baseId = 10000 + ((taskId.hashCode.abs() % 100000) * 100);
    
    // Selalu bersihkan alarm lama terlebih dahulu (hingga 30 hari ke depan)
    for (int i = 0; i <= 30; i++) {
      await _flutterLocalNotificationsPlugin.cancel(id: baseId + i);
    }

    // Tidak perlu buat alarm baru jika reminder dimatikan, deadline kosong, atau tugas selesai
    if (!isEnabled || deadline == null || isCompleted) return;

    final now = tz.TZDateTime.now(tz.local);
    final deadlineLocal = tz.TZDateTime.from(deadline, tz.local);
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime(deadlineLocal.year, deadlineLocal.month, deadlineLocal.day);
    int daysToSchedule = deadlineDate.difference(today).inDays + 1;
    
    if (daysToSchedule <= 0) return;
    if (daysToSchedule > 30) daysToSchedule = 30; // Batasi maksimal 30 hari ke depan

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_task_channel',
      'Daily Task Reminders',
      channelDescription: 'Daily countdown for specific tasks',
      importance: Importance.max,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    for (int i = 0; i < daysToSchedule; i++) {
      // Jadwalkan jam 07.00 pagi untuk setiap hari
      var scheduledTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, 7, 0).add(Duration(days: i));
      
      // Lewati hari ini jika jam 07.00-nya sudah terlewat
      if (i == 0 && scheduledTime.isBefore(now)) {
        continue;
      }
      
      // Hitung sisa hari dari jadwal notifikasi ini ke deadline
      final daysLeft = DateTime(deadline.year, deadline.month, deadline.day)
          .difference(DateTime(scheduledTime.year, scheduledTime.month, scheduledTime.day))
          .inDays;
          
      final String timeMessage = daysLeft <= 0 
          ? 'Deadline is today! Time to finish it up.' 
          : 'You have ${daysLeft == 1 ? '1 day' : '$daysLeft days'} left.';
      
      try {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id: baseId + i,
          title: 'Reminder: $taskName',
          body: timeMessage,
          scheduledDate: scheduledTime,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (e) {
        // Fallback ke inexact jika izin exact alarm tidak diberikan
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id: baseId + i,
          title: 'Reminder: $taskName',
          body: timeMessage,
          scheduledDate: scheduledTime,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    }
  }
}
