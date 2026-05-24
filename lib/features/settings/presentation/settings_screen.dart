import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/providers/user_provider.dart';
import '../../task/presentation/providers/task_provider.dart';
import '../../focus/presentation/providers/focus_timer_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/notification_service.dart';

final dailyReminderProvider = AsyncNotifierProvider<DailyReminderNotifier, bool>(() {
  return DailyReminderNotifier();
});

class DailyReminderNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    return await ref.read(notificationServiceProvider).isDailyReminderEnabled();
  }

  Future<void> toggle(bool value) async {
    final service = ref.read(notificationServiceProvider);
    if (value) {
      await service.scheduleDailyReminder();
    } else {
      await service.cancelDailyReminder();
    }
    state = AsyncData(await service.isDailyReminderEnabled());
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showEditNameDialog(BuildContext context, WidgetRef ref, String currentName) {
    final controller = TextEditingController(text: currentName);
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            final preview = controller.text.trim();
            final initial = preview.isNotEmpty ? preview.substring(0, 1).toUpperCase() : '?';

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(dialogContext).viewInsets.bottom),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                        color: cs.onSurface.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [cs.primary, cs.primary.withBlue(220)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: cs.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: Center(
                        child: Text(initial, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      preview.isEmpty ? 'Your Name' : preview,
                      style: TextStyle(color: cs.onSurface.withOpacity(0.4), fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'DISPLAY NAME',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: cs.onSurface.withOpacity(0.4)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'e.g. Alex Johnson',
                        hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.3), fontWeight: FontWeight.w500),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: cs.outline.withOpacity(0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: cs.outline.withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: cs.primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        suffixIcon: controller.text.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.close_rounded), onPressed: () { controller.clear(); setState(() {}); })
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              side: BorderSide(color: cs.outline.withOpacity(0.3)),
                            ),
                            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final newName = controller.text.trim();
                                    if (newName.isEmpty) return;
                                    setState(() => isSaving = true);
                                    try {
                                      await ref.read(authServiceProvider).updateDisplayName(newName);
                                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Row(children: [
                                              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                              SizedBox(width: 8),
                                              Text('Name updated!'),
                                            ]),
                                            backgroundColor: const Color(0xFF22C55E),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setState(() => isSaving = false);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: ${e.toString()}'),
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: isSaving
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final themeMode = ref.watch(themeModeProvider);
    final tasksAsync = ref.watch(taskListProvider);
    final sessionsAsync = ref.watch(focusSessionsProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDailyReminderAsync = ref.watch(dailyReminderProvider);
    final isDailyReminderEnabled = isDailyReminderAsync.value ?? false;

    final isDarkMode = themeMode == ThemeMode.dark || (themeMode == ThemeMode.system && isDark);

    final tasks = tasksAsync.value ?? [];
    final sessions = sessionsAsync.value ?? [];
    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final totalFocusSeconds = sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);

    final displayName = (user?.name.isNotEmpty == true)
        ? user!.name
        : (user?.email.isNotEmpty == true ? user!.email : 'Guest');
    final initial = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : '?';

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.3)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Profile Card ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.25),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cs.outline.withOpacity(0.12)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showEditNameDialog(context, ref, user?.name ?? ''),
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [cs.primary, cs.primary.withBlue(220)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: cs.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: Center(
                            child: Text(initial, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (user?.email.isNotEmpty == true && user?.name.isNotEmpty == true) ...[
                              const SizedBox(height: 2),
                              Text(
                                user!.email,
                                style: TextStyle(color: cs.onSurface.withOpacity(0.45), fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _showEditNameDialog(context, ref, user?.name ?? ''),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: cs.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: cs.primary.withOpacity(0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit_outlined, size: 11, color: cs.primary),
                                    const SizedBox(width: 4),
                                    Text('Edit name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.primary)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Divider(color: cs.outline.withOpacity(0.15)),
                  const SizedBox(height: 16),

                  // Stats Row
                  Row(
                    children: [
                      _StatBadge(label: 'Completed', value: '$completedTasks', icon: Icons.check_circle_rounded, color: const Color(0xFF22C55E)),
                      _VertDivider(),
                      _StatBadge(label: 'Total Tasks', value: '${tasks.length}', icon: Icons.task_alt_rounded, color: cs.primary),
                      _VertDivider(),
                      _StatBadge(
                        label: 'Focus Time',
                        value: totalFocusSeconds > 0 ? _formatDuration(totalFocusSeconds) : '0m',
                        icon: Icons.timer_rounded,
                        color: const Color(0xFF8B5CF6),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            _SectionLabel('Preferences'),
            const SizedBox(height: 10),

            // ── Preferences Group ─────────────────────────────────
            _SettingsGroup(
              children: [
                _SettingsTile(
                  icon: Icons.dark_mode_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'Dark Mode',
                  subtitle: isDarkMode ? 'On' : 'Off',
                  trailing: Switch.adaptive(
                    value: isDarkMode,
                    onChanged: (value) {
                      ref.read(themeModeProvider.notifier).state = value ? ThemeMode.dark : ThemeMode.light;
                    },
                    activeTrackColor: cs.primary,
                  ),
                ),
                _Separator(),
                _SettingsTile(
                  icon: Icons.notifications_active_rounded,
                  iconColor: const Color(0xFF22C55E),
                  title: 'Daily Reminder',
                  subtitle: isDailyReminderEnabled ? 'Every day at 7:00 AM' : 'Off',
                  trailing: Switch.adaptive(
                    value: isDailyReminderEnabled,
                    onChanged: (value) {
                      ref.read(dailyReminderProvider.notifier).toggle(value);
                    },
                    activeTrackColor: cs.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            _SectionLabel('About'),
            const SizedBox(height: 10),

            _SettingsGroup(
              children: [
                _SettingsTile(
                  icon: Icons.info_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'App Version',
                  subtitle: 'Kelarin v1.0.0',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Latest', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFF59E0B))),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            _SectionLabel('Account'),
            const SizedBox(height: 10),

            _SettingsGroup(
              children: [
                _SettingsTile(
                  icon: Icons.logout_rounded,
                  iconColor: const Color(0xFFEF4444),
                  title: 'Logout',
                  titleColor: const Color(0xFFEF4444),
                  trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurface.withOpacity(0.3)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                        content: const Text('Are you sure you want to log out?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await ref.read(authServiceProvider).signOut();
                            },
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withOpacity(0.12)),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: titleColor ?? cs.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.45)),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 56),
      child: Divider(height: 1, color: Theme.of(context).colorScheme.outline.withOpacity(0.12)),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatBadge({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45), fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: Theme.of(context).colorScheme.outline.withOpacity(0.15));
  }
}
