import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _dailyReminderPrefKey = 'pref_daily_reminder_enabled';

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    try {
      final dynamic tzInfo = await FlutterTimezone.getLocalTimezone();
      // Di versi 5.x+, propertinya adalah 'identifier', bukan 'name'
      final String name = tzInfo is String ? tzInfo : (tzInfo.identifier ?? tzInfo.toString());
      
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
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
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }

    _isInitialized = true;

    // Buat semua notification channels secara eksplisit
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

  Future<void> showTimerCompleteNotification({
    required String taskName,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'focus_timer_channel', // id
      'Focus Timer Notifications', // name
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
      id: 0, // Notification ID
      title: 'Focus Session Complete',
      body: 'Great job on "$taskName"! Take a break.',
      notificationDetails: notificationDetails,
      payload: 'focus_complete',
    );
  }

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

    // Jadwalkan setiap jam 07:00 pagi
    final now = tz.TZDateTime.now(tz.local);
    // Jadwalkan jam 7 pagi setiap hari
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

    // Persist preference — jangan andalkan pendingNotificationRequests()
    // karena inexact alarms tidak muncul di sana
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailyReminderPrefKey, true);
  }

  // Hapus fungsi showImmediateTestNotification yang tadi


  Future<void> cancelDailyReminder() async {
    await _flutterLocalNotificationsPlugin.cancel(id: 1);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailyReminderPrefKey, false);
  }

  /// Membaca preferensi dari SharedPreferences.
  /// JANGAN gunakan pendingNotificationRequests() karena inexact alarms
  /// tidak ter-include di dalamnya, menyebabkan status selalu terlihat OFF.
  Future<bool> isDailyReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dailyReminderPrefKey) ?? false;
  }

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
    
    // Hash string ID to integer
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
      // Fallback to inexact if exact permission is missing
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

  Future<void> manageTaskDailyReminder({
    required String taskId,
    required String taskName,
    required DateTime? deadline,
    required bool isEnabled,
    required bool isCompleted,
  }) async {
    // Generate a unique base ID for this task's daily reminders
    final baseId = 10000 + ((taskId.hashCode.abs() % 100000) * 100);
    
    // Clear any existing reminders for this task (up to 30 days)
    for (int i = 0; i <= 30; i++) {
      await _flutterLocalNotificationsPlugin.cancel(id: baseId + i);
    }

    if (!isEnabled || deadline == null || isCompleted) return;

    final now = tz.TZDateTime.now(tz.local);
    final deadlineLocal = tz.TZDateTime.from(deadline, tz.local);
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime(deadlineLocal.year, deadlineLocal.month, deadlineLocal.day);
    int daysToSchedule = deadlineDate.difference(today).inDays + 1;
    
    if (daysToSchedule <= 0) return; 
    if (daysToSchedule > 30) daysToSchedule = 30; // Limit to 30 days ahead

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
      var scheduledTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, 7, 0).add(Duration(days: i));
      
      if (i == 0 && scheduledTime.isBefore(now)) {
        continue;
      }
      
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
