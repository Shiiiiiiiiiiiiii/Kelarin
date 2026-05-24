import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/presentation/home_screen.dart';
import '../../progress/presentation/progress_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../task/presentation/providers/task_provider.dart';
import '../../../core/services/notification_service.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ProgressScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncAlarms();
    });
  }

  Future<void> _syncAlarms() async {
    final notificationService = ref.read(notificationServiceProvider);
    
    // 1. Sync global daily reminder
    // Preference dibaca dari SharedPreferences, bukan pending notification
    // (inexact alarms tidak muncul di pendingNotificationRequests)
    final isDailyEnabled = await notificationService.isDailyReminderEnabled();
    if (isDailyEnabled) {
      // Selalu reschedule untuk memastikan alarm aktif (after reboot, update, etc.)
      await notificationService.scheduleDailyReminder();
    }

    // 2. Sync task daily reminders
    try {
      final tasks = await ref.read(taskListProvider.future);
      for (final task in tasks) {
        if (task.isDailyReminderEnabled && !task.isCompleted) {
          await notificationService.manageTaskDailyReminder(
            taskId: task.id,
            taskName: task.title,
            deadline: task.dueDate,
            isEnabled: true,
            isCompleted: false,
          );
        }
      }
    } catch (e) {
      debugPrint('Error syncing alarms: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
