class FocusSession {
  final String id;
  final String userId;
  final int durationSeconds; // durasi total sesi fokus
  final String? linkedTaskId;
  final String? linkedTaskTitle;
  final DateTime completedAt;

  const FocusSession({
    required this.id,
    required this.userId,
    required this.durationSeconds,
    this.linkedTaskId,
    this.linkedTaskTitle,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'durationSeconds': durationSeconds,
      'linkedTaskId': linkedTaskId,
      'linkedTaskTitle': linkedTaskTitle,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory FocusSession.fromFirestore(Map<String, dynamic> map) {
    return FocusSession(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      durationSeconds: map['durationSeconds'] ?? 0,
      linkedTaskId: map['linkedTaskId'],
      linkedTaskTitle: map['linkedTaskTitle'],
      completedAt: DateTime.parse(map['completedAt']),
    );
  }
}
