import 'subject_model.dart';

enum TaskType {
  assignment,
  quiz,
  exam,
  project,
  recitation,
  laboratory,
  groupMeeting,
  personal,
}

extension TaskTypeX on TaskType {
  String get label {
    switch (this) {
      case TaskType.assignment:
        return 'Assignment';
      case TaskType.quiz:
        return 'Quiz';
      case TaskType.exam:
        return 'Major Exam';
      case TaskType.project:
        return 'Project';
      case TaskType.recitation:
        return 'Recitation';
      case TaskType.laboratory:
        return 'Laboratory Activity';
      case TaskType.groupMeeting:
        return 'Group Meeting';
      case TaskType.personal:
        return 'Personal Activity';
    }
  }

  int get score {
    switch (this) {
      case TaskType.exam:
        return 10;
      case TaskType.project:
        return 8;
      case TaskType.quiz:
        return 6;
      case TaskType.assignment:
      case TaskType.laboratory:
        return 4;
      case TaskType.recitation:
      case TaskType.groupMeeting:
        return 3;
      case TaskType.personal:
        return 1;
    }
  }
}

enum ImportanceLevel { low, medium, high, critical }

extension ImportanceLevelX on ImportanceLevel {
  String get label {
    switch (this) {
      case ImportanceLevel.low:
        return 'Low';
      case ImportanceLevel.medium:
        return 'Medium';
      case ImportanceLevel.high:
        return 'High';
      case ImportanceLevel.critical:
        return 'Critical';
    }
  }

  int get score {
    switch (this) {
      case ImportanceLevel.low:
        return 1;
      case ImportanceLevel.medium:
        return 3;
      case ImportanceLevel.high:
        return 5;
      case ImportanceLevel.critical:
        return 8;
    }
  }
}

enum TaskStatus { pending, scheduled, completed, missed }

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.scheduled:
        return 'Scheduled';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.missed:
        return 'Missed';
    }
  }
}

class AcademicTask {
  const AcademicTask({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.taskType,
    required this.deadline,
    required this.estimatedMinutes,
    required this.importance,
    required this.difficulty,
    this.notes = '',
    this.status = TaskStatus.pending,
    this.missedCount = 0,
    this.priorityScore = 0,
  });

  factory AcademicTask.fromFirestore(String id, Map<String, dynamic> data) {
    return AcademicTask(
      id: id,
      subjectId: _readString(data, 'subjectId', ''),
      title: _readString(data, 'title', 'Untitled Task'),
      taskType: _taskTypeFromName(_readString(data, 'taskType', 'assignment')),
      deadline: _readDate(data, 'deadline', DateTime.now().add(const Duration(days: 1))),
      estimatedMinutes: _readInt(data, 'estimatedMinutes', 60),
      importance: _importanceFromName(_readString(data, 'importance', 'medium')),
      difficulty: _difficultyFromName(_readString(data, 'difficulty', 'moderate')),
      notes: _readString(data, 'notes', ''),
      status: _statusFromName(_readString(data, 'status', 'pending')),
      missedCount: _readInt(data, 'missedCount', 0),
      priorityScore: _readInt(data, 'priorityScore', 0),
    );
  }

  final String id;
  final String subjectId;
  final String title;
  final TaskType taskType;
  final DateTime deadline;
  final int estimatedMinutes;
  final ImportanceLevel importance;
  final SubjectDifficulty difficulty;
  final String notes;
  final TaskStatus status;
  final int missedCount;
  final int priorityScore;

  bool get isCompleted => status == TaskStatus.completed;
  bool get isMissed => status == TaskStatus.missed;

  Map<String, dynamic> toFirestore() {
    return {
      'taskId': id,
      'subjectId': subjectId,
      'title': title,
      'taskType': taskType.name,
      'taskTypeLabel': taskType.label,
      'deadline': deadline.toIso8601String(),
      'estimatedMinutes': estimatedMinutes,
      'importance': importance.name,
      'importanceLabel': importance.label,
      'difficulty': difficulty.name,
      'difficultyLabel': difficulty.label,
      'notes': notes,
      'status': status.name,
      'statusLabel': status.label,
      'missedCount': missedCount,
      'priorityScore': priorityScore,
    };
  }

  AcademicTask copyWith({
    String? id,
    String? subjectId,
    String? title,
    TaskType? taskType,
    DateTime? deadline,
    int? estimatedMinutes,
    ImportanceLevel? importance,
    SubjectDifficulty? difficulty,
    String? notes,
    TaskStatus? status,
    int? missedCount,
    int? priorityScore,
  }) {
    return AcademicTask(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      taskType: taskType ?? this.taskType,
      deadline: deadline ?? this.deadline,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      importance: importance ?? this.importance,
      difficulty: difficulty ?? this.difficulty,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      missedCount: missedCount ?? this.missedCount,
      priorityScore: priorityScore ?? this.priorityScore,
    );
  }
}

TaskType _taskTypeFromName(String value) {
  final normalized = value.trim().toLowerCase().replaceAll(' ', '');
  for (final item in TaskType.values) {
    if (item.name.toLowerCase() == normalized ||
        item.label.toLowerCase().replaceAll(' ', '') == normalized) {
      return item;
    }
  }
  return TaskType.assignment;
}

ImportanceLevel _importanceFromName(String value) {
  final normalized = value.trim().toLowerCase().replaceAll(' ', '');
  for (final item in ImportanceLevel.values) {
    if (item.name.toLowerCase() == normalized ||
        item.label.toLowerCase().replaceAll(' ', '') == normalized) {
      return item;
    }
  }
  return ImportanceLevel.medium;
}

TaskStatus _statusFromName(String value) {
  final normalized = value.trim().toLowerCase().replaceAll(' ', '');
  for (final item in TaskStatus.values) {
    if (item.name.toLowerCase() == normalized ||
        item.label.toLowerCase().replaceAll(' ', '') == normalized) {
      return item;
    }
  }
  return TaskStatus.pending;
}

SubjectDifficulty _difficultyFromName(String value) {
  final normalized = value.trim().toLowerCase().replaceAll(' ', '');
  for (final item in SubjectDifficulty.values) {
    if (item.name.toLowerCase() == normalized ||
        item.label.toLowerCase().replaceAll(' ', '') == normalized) {
      return item;
    }
  }
  return SubjectDifficulty.moderate;
}

String _readString(Map<String, dynamic> data, String key, String fallback) {
  final value = data[key];
  if (value is String) return value.trim();
  return fallback;
}

int _readInt(Map<String, dynamic> data, String key, int fallback) {
  final value = data[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

DateTime _readDate(Map<String, dynamic> data, String key, DateTime fallback) {
  final value = data[key];
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? fallback;
  final dynamic maybeTimestamp = value;
  try {
    final DateTime converted = maybeTimestamp.toDate() as DateTime;
    return converted;
  } catch (_) {
    return fallback;
  }
}
