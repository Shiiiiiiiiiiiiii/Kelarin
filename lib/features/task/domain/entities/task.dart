enum TaskPriority { low, medium, high }
enum TaskRecurrence { none, daily, weekly, monthly }

class Task {
  final String id;
  final String userId;
  final String title;
  final String description;
  final TaskPriority priority;
  final String category;
  final bool isCompleted;
  final double taskProgress;
  final DateTime? dueDate;
  final bool isDailyReminderEnabled;
  final TaskRecurrence recurrence;
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

  bool get shouldReset {
    if (!isCompleted || lastCompletedAt == null || recurrence == TaskRecurrence.none) return false;
    
    final now = DateTime.now();
    final last = lastCompletedAt!;
    
    switch (recurrence) {
      case TaskRecurrence.daily:
        return now.day != last.day || now.month != last.month || now.year != last.year;
      case TaskRecurrence.weekly:
        final daysDiff = now.difference(last).inDays;
        if (daysDiff >= 7) return true;
        // Week starts on Monday (1) to Sunday (7) in Dart DateTime
        if (now.weekday < last.weekday && daysDiff > 0) return true;
        return false;
      case TaskRecurrence.monthly:
        return now.month != last.month || now.year != last.year;
      case TaskRecurrence.none:
        return false;
    }
  }
}