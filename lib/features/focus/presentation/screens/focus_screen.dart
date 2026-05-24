import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/focus_timer_provider.dart';
import '../providers/audio_provider.dart';
import '../../../task/presentation/providers/task_provider.dart';
import 'dart:ui';

class FocusScreen extends ConsumerWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(focusTimerProvider);
    final timerNotifier = ref.read(focusTimerProvider.notifier);
    final audioState = ref.watch(audioProvider);
    final audioNotifier = ref.read(audioProvider.notifier);

    final String titleText = timerState.selectedTask?.title ?? "General Focus";
    
    final minutes = (timerState.remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (timerState.remainingSeconds % 60).toString().padLeft(2, '0');
    final progress = timerState.initialSeconds > 0 
                     ? timerState.remainingSeconds / timerState.initialSeconds 
                     : 0.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return PopScope(
      canPop: !(timerState.isRunning && timerState.isStrictMode),
      child: Scaffold(
        extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Dynamic Background Gradient
          AnimatedContainer(
            duration: const Duration(seconds: 1),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: timerState.isRunning 
                    ? [
                        isDark ? Colors.black : primaryColor.withOpacity(0.8),
                        isDark ? Colors.grey.shade900 : primaryColor.withOpacity(0.6),
                      ]
                    : [
                        Theme.of(context).colorScheme.surface,
                        Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      ],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      if (!(timerState.isRunning && timerState.isStrictMode))
                        IconButton(
                          icon: Icon(
                            Icons.expand_more, 
                            size: 32, 
                            color: timerState.isRunning || isDark ? Colors.white : Colors.black87
                          ),
                          onPressed: () => Navigator.pop(context),
                        )
                      else
                        const SizedBox(width: 48, height: 48),
                      const Spacer(),
                      IconButton(
                        icon: Icon(audioState.isEnabled ? Icons.music_note : Icons.music_off),
                        color: timerState.isRunning || isDark ? Colors.white : primaryColor,
                        onPressed: () => audioNotifier.toggleEnabled(timerState.isRunning),
                      ),
                      if (!timerState.isRunning)
                        TextButton.icon(
                          onPressed: () => _showDurationPicker(context, timerNotifier),
                          icon: const Icon(Icons.edit_note, size: 20),
                          label: const Text("Custom"),
                          style: TextButton.styleFrom(foregroundColor: primaryColor),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Minimal Task Selector Pill
                GestureDetector(
                  onTap: timerState.isRunning ? null : () => _showTaskSelector(context, ref, timerNotifier),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    decoration: BoxDecoration(
                      color: timerState.isRunning 
                          ? Colors.white.withOpacity(0.15) 
                          : primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          timerState.selectedTask != null ? Icons.task_alt : Icons.center_focus_strong, 
                          size: 18, 
                          color: timerState.isRunning || isDark ? Colors.white : primaryColor
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            titleText,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: timerState.isRunning || isDark ? Colors.white : primaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!timerState.isRunning) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down, size: 18, color: isDark ? Colors.white70 : primaryColor),
                        ]
                      ],
                    ),
                  ),
                ),

                if (!timerState.isRunning)
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (timerState.selectedTask != null) ...[
                          _ToggleChip(
                            icon: Icons.check_circle_outline,
                            label: "Auto-complete",
                            isActive: timerState.autoCompleteTask,
                            activeColor: primaryColor,
                            onTap: () => timerNotifier.toggleAutoComplete(!timerState.autoCompleteTask),
                          ),
                          const SizedBox(width: 12),
                        ],
                        _ToggleChip(
                          icon: Icons.local_fire_department,
                          label: "Strict Mode",
                          isActive: timerState.isStrictMode,
                          activeColor: Colors.orange,
                          onTap: () {
                            if (!timerState.isStrictMode) {
                              _showStrictModeWarning(context, timerNotifier);
                            } else {
                              timerNotifier.toggleStrictMode(false);
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                const Spacer(),

                // Timer Visualizer
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow/shadow
                    if (timerState.isRunning)
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.1),
                              blurRadius: 50,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    
                    // Main Progress Circle
                    SizedBox(
                      width: 230,
                      height: 230,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 12,
                        backgroundColor: timerState.isRunning 
                            ? Colors.white12 
                            : primaryColor.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          timerState.isRunning ? Colors.white : primaryColor
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),

                    // Time Text
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$minutes:$seconds',
                          style: TextStyle(
                            fontSize: 68,
                            fontWeight: FontWeight.w300,
                            color: timerState.isRunning || isDark ? Colors.white : Colors.black87,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        if (timerState.isRunning)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              timerState.selectedTask?.category ?? 'Focus',
                              style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                const Spacer(),

                // Selection / Controls Section
                if (!timerState.isRunning && timerState.remainingSeconds == timerState.initialSeconds)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [15, 25, 45, 60].map((mins) {
                          final isSelected = timerState.initialSeconds == mins * 60;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: InkWell(
                              onTap: () => timerNotifier.setDuration(mins * 60),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? primaryColor : primaryColor.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? primaryColor : primaryColor.withOpacity(0.1),
                                  ),
                                ),
                                child: Text(
                                  '${mins}m',
                                  style: TextStyle(
                                    color: isSelected || isDark ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                // Play / Stop Controls
                Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!timerState.isRunning && timerState.remainingSeconds < timerState.initialSeconds)
                        _ControlCircleButton(
                          icon: Icons.replay,
                          onPressed: () => timerNotifier.reset(),
                          isSecondary: true,
                        ),
                      if (!timerState.isRunning && timerState.remainingSeconds < timerState.initialSeconds)
                        const SizedBox(width: 32),
                      
                      if (!(timerState.isRunning && timerState.isStrictMode))
                        _ControlCircleButton(
                          icon: timerState.isRunning ? Icons.pause : Icons.play_arrow,
                          onPressed: () {
                            if (timerState.isRunning) {
                              timerNotifier.pause();
                            } else {
                              timerNotifier.start();
                            }
                          },
                          isLarge: true,
                        ),
                      
                      if (!(timerState.isRunning && timerState.isStrictMode))
                        const SizedBox(width: 32),
                      
                      if (timerState.isRunning && timerState.isStrictMode)
                        InkWell(
                          onLongPress: () {
                            timerNotifier.stopAndSave();
                            Navigator.pop(context);
                          },
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Hold to give up!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(32),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(color: Colors.red.shade400, width: 2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.red.shade400),
                                const SizedBox(width: 12),
                                Text(
                                  "HOLD TO GIVE UP", 
                                  style: TextStyle(
                                    color: Colors.red.shade400, 
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        _ControlCircleButton(
                          icon: Icons.stop,
                          onPressed: timerState.selectedTask != null || timerState.remainingSeconds < timerState.initialSeconds || timerState.isRunning 
                              ? () {
                                  timerNotifier.stopAndSave();
                                  Navigator.pop(context);
                                } 
                              : null,
                          isSecondary: true,
                          isRed: true,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  void _showStrictModeWarning(BuildContext context, FocusTimerNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              const Text("Strict Mode"),
            ],
          ),
          content: const Text(
            "In Strict Mode, you cannot pause or normally stop the timer. You can only exit by 'Giving Up', which may affect your stats. Are you ready for deep focus?",
            style: TextStyle(fontSize: 15, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () {
                notifier.toggleStrictMode(true);
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text("I'm Ready", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }
    );
  }

  void _showTaskSelector(BuildContext context, WidgetRef ref, FocusTimerNotifier notifier) {
    final tasksAsync = ref.watch(taskListProvider);
    final tasks = tasksAsync.value?.where((t) => !t.isCompleted).toList() ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('Work on a specific task?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                ),
                if (tasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40.0, left: 32, right: 32),
                    child: Text(
                      "No ongoing tasks available. Link a task to automatically complete it when the timer ends!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                if (tasks.isNotEmpty)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: tasks.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final t = tasks[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          tileColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Icon(Icons.task_alt, size: 20, color: Theme.of(context).colorScheme.primary),
                          ),
                          title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(t.category, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          onTap: () {
                            notifier.setTask(t);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }
    );
  }

  void _showDurationPicker(BuildContext context, FocusTimerNotifier notifier) {
    final TextEditingController controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              left: 32,
              right: 32,
              top: 32,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Custom Duration', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
                const SizedBox(height: 8),
                Text('How many minutes do you want to stay focused?', style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: '25',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          suffixText: 'min',
                          suffixStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      height: 64,
                      width: 64,
                      child: IconButton.filled(
                        onPressed: () {
                          final mins = int.tryParse(controller.text) ?? 0;
                          if (mins > 0) {
                            notifier.setDuration(mins * 60);
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.check, size: 28),
                        style: IconButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}

class _ControlCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLarge;
  final bool isSecondary;
  final bool isRed;

  const _ControlCircleButton({
    required this.icon,
    this.onPressed,
    this.isLarge = false,
    this.isSecondary = false,
    this.isRed = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = isLarge ? 80.0 : 56.0;
    final iconSize = isLarge ? 40.0 : 28.0;

    final disabledBgColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final disabledIconColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    
    final secondaryBgColor = isDark ? Colors.grey.shade800 : Colors.white;
    final secondaryIconColor = isRed ? Colors.red : (isDark ? Colors.white : Colors.black87);
    final secondaryBorderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade200;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(size / 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: onPressed == null 
              ? disabledBgColor 
              : (isSecondary ? secondaryBgColor : (isRed ? Colors.red.shade400 : primaryColor)),
          shape: BoxShape.circle,
          boxShadow: onPressed != null ? [
            BoxShadow(
              color: (isRed ? Colors.red : primaryColor).withOpacity(isDark ? 0.4 : 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : null,
          border: isSecondary ? Border.all(color: secondaryBorderColor) : null,
        ),
        child: Icon(
          icon, 
          size: iconSize, 
          color: onPressed == null ? disabledIconColor : (isSecondary ? secondaryIconColor : Colors.white)
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;

  const _ToggleChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive 
              ? activeColor.withOpacity(0.15) 
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive 
                ? activeColor.withOpacity(0.5) 
                : (isDark ? Colors.white24 : Colors.black12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              size: 18, 
              color: isActive ? activeColor : (isDark ? Colors.white60 : Colors.black54)
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? activeColor : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}