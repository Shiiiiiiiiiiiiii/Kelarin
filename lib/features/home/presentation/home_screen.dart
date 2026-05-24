import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/task_card.dart';
import 'providers/greeting_provider.dart';
import '../../task/presentation/providers/task_provider.dart';
import '../../task/domain/entities/task.dart';
import '../../task/presentation/screens/add_task_screen.dart';
import '../../task/presentation/screens/task_detail_screen.dart';
import '../../focus/presentation/providers/focus_timer_provider.dart';
import '../../focus/presentation/screens/focus_screen.dart';
import '../../auth/presentation/providers/user_provider.dart';

enum TaskSortOption { recent, priority, deadline }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  TaskSortOption _sortOption = TaskSortOption.recent;
  final TextEditingController _searchController = TextEditingController();
  late Timer _timer;
  late DateTime _currentDate;

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      if (now.day != _currentDate.day) {
        setState(() {
          _currentDate = now;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _timer.cancel();
    super.dispose();
  }

  String _getFormattedDate() {
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${weekdays[_currentDate.weekday - 1]}, ${_currentDate.day} ${months[_currentDate.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final greeting = ref.watch(greetingProvider);
    final user = ref.watch(userProvider);
    final userName = (user?.name.isNotEmpty == true)
        ? user!.name
        : (user?.email.isNotEmpty == true ? user!.email : 'Guest');
    final userInitial = userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : '?';
    final taskListAsync = ref.watch(taskListProvider);

    return taskListAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (allTasks) {
        final categories = ['All', ...allTasks.map((e) => e.category).toSet()];
        if (!categories.contains(_selectedCategory) && _selectedCategory != 'All') {
          _selectedCategory = 'All'; 
        }

        var filteredTasks = _selectedCategory == 'All' 
            ? allTasks 
            : allTasks.where((t) => t.category == _selectedCategory).toList();
            
        if (_searchQuery.isNotEmpty) {
          filteredTasks = filteredTasks
              .where((t) => t.title.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
        }

        if (_sortOption == TaskSortOption.priority) {
          filteredTasks.sort((a, b) => b.priority.index.compareTo(a.priority.index));
        } else if (_sortOption == TaskSortOption.deadline) {
          filteredTasks.sort((a, b) {
            if (a.dueDate == null && b.dueDate == null) return 0;
            if (a.dueDate == null) return 1;
            if (b.dueDate == null) return -1;
            return a.dueDate!.compareTo(b.dueDate!);
          });
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            title: Image.asset(
              isDark 
                  ? 'assets/images/text_logo_dark.png' 
                  : 'assets/images/text_logo_light.png', 
              height: 24,
            ),
            centerTitle: false,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    userInitial,
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              )
            ],
          ),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getFormattedDate().toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hello, $userName.',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const _HomeFocusTimerBanner(),
                        const SizedBox(height: 12),
                        _buildMiniDashboard(context, allTasks),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Your Tasks",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.search),
                                  color: Colors.grey.shade600,
                                  onPressed: () {},
                                ),
                                PopupMenuButton<TaskSortOption>(
                                  icon: Icon(Icons.sort, color: Colors.grey.shade600),
                                  tooltip: "Sort Tasks",
                                  onSelected: (option) => setState(() => _sortOption = option),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: TaskSortOption.recent, child: Text("Sort by Recent")),
                                    const PopupMenuItem(value: TaskSortOption.priority, child: Text("Sort by Priority")),
                                    const PopupMenuItem(value: TaskSortOption.deadline, child: Text("Sort by Deadline")),
                                  ],
                                ),
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Search tasks...',
                            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                            prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey.shade500),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                      FocusScope.of(context).unfocus();
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 48,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final cat = categories[index];
                              final isSelected = _selectedCategory == cat;
                              return ChoiceChip(
                                label: Text(
                                  cat, 
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                    fontSize: 13,
                                  )
                                ),
                                selected: isSelected,
                                selectedColor: Theme.of(context).colorScheme.primary,
                                backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
                                showCheckmark: false,
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _selectedCategory = cat);
                                  }
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                if (filteredTasks.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 80,
                            color: Colors.grey.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedCategory == 'All' 
                               ? "You have no tasks at the moment.\nTap + to create one!"
                               : "No tasks in '$_selectedCategory' category.",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final task = filteredTasks[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TaskDetailScreen(taskId: task.id),
                                   ),
                                );
                              },
                              child: TaskCard(
                                title: task.title,
                                subtitle: task.description,
                                category: task.category,
                                isCompleted: task.isCompleted,
                                progress: task.taskProgress,
                                priorityColor: _priorityColor(task.priority),
                                priorityLabel: task.priority.name.toUpperCase(),
                                dueDate: task.dueDate,
                                onToggle: () {
                                  ref.read(taskActionProvider).toggleTask(task);
                                },
                              ),
                            ),
                          );
                        },
                        childCount: filteredTasks.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddTaskScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text("New Task", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high: return Colors.red;
      case TaskPriority.medium: return Colors.orange;
      case TaskPriority.low: return Colors.green;
    }
  }

  Widget _buildMiniDashboard(BuildContext context, List<Task> tasks) {
    final pendingTasks = tasks.where((t) => !t.isCompleted).toList()
      ..sort((a, b) => b.priority.index.compareTo(a.priority.index));
    final topTask = pendingTasks.isNotEmpty ? pendingTasks.first : null;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(16),
            height: 115,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(Icons.push_pin, size: 14, color: primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      "UP NEXT",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (topTask != null) ...[
                  Text(
                    topTask.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    topTask.category,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                ] else
                  const Text(
                    "All clear! 🎉",
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 14),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(16),
            height: 115,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📋', style: TextStyle(fontSize: 20)),
                const SizedBox(height: 4),
                Text(
                  "${tasks.where((t) => t.isCompleted).length}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Done",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeFocusTimerBanner extends ConsumerWidget {
  const _HomeFocusTimerBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(focusTimerProvider);
    final isRunning = timerState.isRunning;
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    final minutes = (timerState.remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (timerState.remainingSeconds % 60).toString().padLeft(2, '0');

    return Container(
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, animation, _) => const FocusScreen(),
                transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isRunning ? Icons.bolt : Icons.timer_outlined, 
                    color: Colors.white, 
                    size: 20
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRunning ? "Focus Active" : "Focus Mode",
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 16, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isRunning ? "Keep going!" : "Start Focus session",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8), 
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$minutes:$seconds',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
