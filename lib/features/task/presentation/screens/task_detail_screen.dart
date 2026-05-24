import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/task.dart';
import '../providers/task_provider.dart';
import 'add_task_screen.dart';
import 'package:kelarin/core/services/notification_service.dart';

class TaskDetailScreen extends ConsumerWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high: return const Color(0xFFEF4444);
      case TaskPriority.medium: return const Color(0xFFF59E0B);
      case TaskPriority.low: return const Color(0xFF22C55E);
    }
  }

  IconData _priorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high: return Icons.keyboard_double_arrow_up_rounded;
      case TaskPriority.medium: return Icons.drag_handle_rounded;
      case TaskPriority.low: return Icons.keyboard_double_arrow_down_rounded;
    }
  }

  int _daysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.difference(today).inDays;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskListAsync = ref.watch(taskListProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return taskListAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (tasks) {
        final taskIndex = tasks.indexWhere((t) => t.id == taskId);

        if (taskIndex == -1) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Task not found or deleted')),
          );
        }

        final task = tasks[taskIndex];
        final pColor = _priorityColor(task.priority);
        final daysLeft = task.dueDate != null ? _daysUntil(task.dueDate!) : null;

        return Scaffold(
          backgroundColor: cs.surface,
          appBar: AppBar(
            backgroundColor: cs.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                tooltip: 'Edit',
                icon: Icon(Icons.edit_outlined, color: cs.primary),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddTaskScreen(taskToEdit: task)),
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      title: const Text('Delete Task', style: TextStyle(fontWeight: FontWeight.bold)),
                      content: const Text('This action cannot be undone.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                          onPressed: () {
                            ref.read(taskActionProvider).deleteTask(task.id);
                            Navigator.pop(ctx);
                            Navigator.pop(context);
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Status badge ─────────────────────────────────
                Row(
                  children: [
                    _StatusBadge(
                      label: task.isCompleted ? 'Completed' : 'In Progress',
                      color: task.isCompleted ? const Color(0xFF22C55E) : cs.primary,
                      icon: task.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(
                      label: task.priority.name[0].toUpperCase() + task.priority.name.substring(1),
                      color: pColor,
                      icon: _priorityIcon(task.priority),
                    ),
                    if (task.category.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _StatusBadge(
                        label: task.category,
                        color: cs.primary,
                        icon: Icons.folder_rounded,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 20),

                // ── Title ────────────────────────────────────────
                Text(
                  task.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted ? cs.onSurface.withOpacity(0.45) : cs.onSurface,
                  ),
                ),

                const SizedBox(height: 24),

                // ── Info cards row ───────────────────────────────
                if (task.dueDate != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.calendar_today_rounded,
                          iconColor: const Color(0xFF3B82F6),
                          label: 'Due Date',
                          value: _formatDate(task.dueDate!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InfoCard(
                          icon: daysLeft != null && daysLeft < 0
                              ? Icons.warning_amber_rounded
                              : Icons.timelapse_rounded,
                          iconColor: daysLeft == null
                              ? cs.primary
                              : daysLeft < 0
                                  ? const Color(0xFFEF4444)
                                  : daysLeft <= 3
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF22C55E),
                          label: daysLeft != null && daysLeft < 0 ? 'Overdue' : 'Days Left',
                          value: daysLeft == null
                              ? '—'
                              : daysLeft == 0
                                  ? 'Today'
                                  : daysLeft < 0
                                      ? '${daysLeft.abs()}d ago'
                                      : '${daysLeft}d',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],

                if (task.recurrence != TaskRecurrence.none)
                  _InfoCard(
                    icon: Icons.repeat_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    label: 'Repeats',
                    value: task.recurrence.name[0].toUpperCase() + task.recurrence.name.substring(1),
                  ),

                if (task.recurrence != TaskRecurrence.none) const SizedBox(height: 10),

                // ── Description ──────────────────────────────────
                _DetailSection(
                  title: 'Notes',
                  child: task.description.isEmpty
                      ? Text(
                          'No notes added.',
                          style: TextStyle(color: cs.onSurface.withOpacity(0.4), fontStyle: FontStyle.italic, fontSize: 15),
                        )
                      : Text(
                          task.description,
                          style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.8), height: 1.65),
                        ),
                ),

                const SizedBox(height: 16),

                // ── Progress ─────────────────────────────────────
                _DetailSection(
                  title: 'Progress',
                  trailing: Text(
                    '${(task.taskProgress * 100).toInt()}%',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: cs.primary),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: task.taskProgress,
                          minHeight: 10,
                          backgroundColor: cs.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4,
                          activeTrackColor: cs.primary.withOpacity(0.5),
                          inactiveTrackColor: cs.surfaceContainerHighest,
                          thumbColor: cs.primary,
                          overlayColor: cs.primary.withOpacity(0.15),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12, elevation: 2),
                        ),
                        child: Slider(
                          value: task.taskProgress,
                          onChanged: (v) => ref.read(taskActionProvider).updateTaskProgress(task, v),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Daily Reminder ────────────────────────────────
                if (task.dueDate != null) ...[
                  const SizedBox(height: 16),
                  _DetailSection(
                    title: 'Alerts',
                    child: SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.notifications_active_rounded, color: Colors.orange, size: 18),
                      ),
                      title: const Text('Daily Countdown', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      subtitle: const Text('Notify me daily about days left', style: TextStyle(fontSize: 12)),
                      value: task.isDailyReminderEnabled,
                      activeColor: cs.primary,
                      onChanged: (value) async {
                        final updatedTask = task.copyWith(isDailyReminderEnabled: value);
                        await ref.read(taskActionProvider).editTask(updatedTask);
                        await ref.read(notificationServiceProvider).manageTaskDailyReminder(
                          taskId: updatedTask.id,
                          taskName: updatedTask.title,
                          deadline: updatedTask.dueDate,
                          isEnabled: updatedTask.isDailyReminderEnabled,
                          isCompleted: updatedTask.isCompleted,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(value ? 'Daily countdown enabled!' : 'Daily countdown disabled.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 58,
              child: FilledButton.icon(
                onPressed: () async {
                  ref.read(taskActionProvider).toggleTask(task);
                  final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
                  await ref.read(notificationServiceProvider).manageTaskDailyReminder(
                    taskId: updatedTask.id,
                    taskName: updatedTask.title,
                    deadline: updatedTask.dueDate,
                    isEnabled: updatedTask.isDailyReminderEnabled,
                    isCompleted: updatedTask.isCompleted,
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: task.isCompleted ? const Color(0xFFF59E0B) : const Color(0xFF22C55E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                icon: Icon(
                  task.isCompleted ? Icons.replay_rounded : Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                label: Text(
                  task.isCompleted ? 'Reopen Task' : 'Mark as Complete',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusBadge({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoCard({required this.icon, required this.iconColor, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.25),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.5), fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _DetailSection({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: cs.onSurface.withOpacity(0.45),
                ),
              ),
              if (trailing != null) ...[
                const Spacer(),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}