import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/task.dart';
import '../providers/task_provider.dart';
import '../../../auth/presentation/providers/user_provider.dart';

class AddTaskScreen extends ConsumerStatefulWidget {
  final Task? taskToEdit;

  const AddTaskScreen({super.key, this.taskToEdit});

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late TaskPriority _priority;
  late TaskRecurrence _recurrence;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.taskToEdit?.title ?? '');
    _descriptionController = TextEditingController(text: widget.taskToEdit?.description ?? '');
    _categoryController = TextEditingController(text: widget.taskToEdit?.category ?? '');
    _priority = widget.taskToEdit?.priority ?? TaskPriority.medium;
    _recurrence = widget.taskToEdit?.recurrence ?? TaskRecurrence.none;
    _dueDate = widget.taskToEdit?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dueDate) {
      setState(() => _dueDate = picked);
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _saveTask() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final user = ref.read(userProvider);
    if (user == null) return;

    final cat = _categoryController.text.trim().isEmpty ? 'Personal' : _categoryController.text.trim();

    if (widget.taskToEdit != null) {
      final updatedTask = widget.taskToEdit!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text,
        priority: _priority,
        category: cat,
        dueDate: _dueDate,
        recurrence: _recurrence,
      );
      ref.read(taskActionProvider).editTask(updatedTask);
    } else {
      final newTask = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text,
        priority: _priority,
        category: cat,
        dueDate: _dueDate,
        recurrence: _recurrence,
      );
      ref.read(taskActionProvider).addTask(newTask);
    }
    Navigator.pop(context);
  }

  Color get _priorityColor {
    switch (_priority) {
      case TaskPriority.high: return const Color(0xFFEF4444);
      case TaskPriority.medium: return const Color(0xFFF59E0B);
      case TaskPriority.low: return const Color(0xFF22C55E);
    }
  }

  IconData get _priorityIcon {
    switch (_priority) {
      case TaskPriority.high: return Icons.keyboard_double_arrow_up_rounded;
      case TaskPriority.medium: return Icons.drag_handle_rounded;
      case TaskPriority.low: return Icons.keyboard_double_arrow_down_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isEdit = widget.taskToEdit != null;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Edit Task' : 'New Task',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton(
              onPressed: _saveTask,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                isEdit ? 'Save' : 'Create',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title input ──────────────────────────────────────
            _SectionCard(
              child: TextField(
                controller: _titleController,
                autofocus: !isEdit,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'Task title…',
                  hintStyle: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withOpacity(0.3),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Description ──────────────────────────────────────
            _SectionCard(
              child: TextField(
                controller: _descriptionController,
                maxLines: null,
                minLines: 3,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                decoration: InputDecoration(
                  hintText: 'Add notes or details…',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withOpacity(0.35),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            const SizedBox(height: 20),
            _SectionLabel('Details'),
            const SizedBox(height: 10),

            // ── Priority ─────────────────────────────────────────
            _SectionCard(
              child: Column(
                children: [
                  _RowHeader(icon: Icons.flag_rounded, iconColor: _priorityColor, label: 'Priority'),
                  const SizedBox(height: 12),
                  Row(
                    children: TaskPriority.values.map((p) {
                      final selected = _priority == p;
                      final col = p == TaskPriority.high
                          ? const Color(0xFFEF4444)
                          : p == TaskPriority.medium
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF22C55E);
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: _PriorityChip(
                            label: p.name[0].toUpperCase() + p.name.substring(1),
                            color: col,
                            selected: selected,
                            onTap: () => setState(() => _priority = p),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Category ─────────────────────────────────────────
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RowHeader(
                    icon: Icons.folder_rounded,
                    iconColor: cs.primary,
                    label: 'Category',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Daily', 'School', 'Work', 'Personal'].map((cat) {
                      final selected = _categoryController.text.trim() == cat;
                      return _QuickChip(
                        label: cat,
                        selected: selected,
                        primaryColor: cs.primary,
                        onTap: () => setState(() => _categoryController.text = selected ? '' : cat),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _categoryController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Custom category…',
                      hintStyle: TextStyle(fontSize: 14, color: cs.onSurface.withOpacity(0.4)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cs.outline.withOpacity(0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cs.outline.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cs.primary, width: 1.5),
                      ),
                      filled: true,
                      fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Due Date ─────────────────────────────────────────
            _SectionCard(
              onTap: () => _selectDate(context),
              child: _RowHeader(
                icon: Icons.calendar_today_rounded,
                iconColor: const Color(0xFF3B82F6),
                label: 'Due Date',
                trailing: Row(
                  children: [
                    Text(
                      _dueDate == null ? 'Not set' : _formatDate(_dueDate!),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _dueDate != null ? const Color(0xFF3B82F6) : cs.onSurface.withOpacity(0.45),
                      ),
                    ),
                    if (_dueDate != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        child: Icon(Icons.close_rounded, size: 16, color: cs.onSurface.withOpacity(0.5)),
                      ),
                    ],
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, color: cs.onSurface.withOpacity(0.3), size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ── Recurrence ───────────────────────────────────────
            _SectionCard(
              child: Column(
                children: [
                  _RowHeader(
                    icon: Icons.repeat_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    label: 'Repeat',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      (TaskRecurrence.none, 'None'),
                      (TaskRecurrence.daily, 'Daily'),
                      (TaskRecurrence.weekly, 'Weekly'),
                      (TaskRecurrence.monthly, 'Monthly'),
                    ].map((entry) {
                      final (rec, label) = entry;
                      return _QuickChip(
                        label: label,
                        selected: _recurrence == rec,
                        primaryColor: const Color(0xFF8B5CF6),
                        onTap: () => setState(() => _recurrence = rec),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _SectionCard({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withOpacity(0.12)),
      ),
      child: child,
    );
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: card,
      );
    }
    return card;
  }
}

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

class _RowHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget? trailing;

  const _RowHeader({required this.icon, required this.iconColor, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        if (trailing != null) ...[
          const Spacer(),
          trailing!,
        ],
      ],
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _PriorityChip({required this.label, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : color.withOpacity(0.25), width: 1.5),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color primaryColor;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.selected, required this.primaryColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? primaryColor : primaryColor.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? primaryColor : primaryColor.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : primaryColor,
          ),
        ),
      ),
    );
  }
}