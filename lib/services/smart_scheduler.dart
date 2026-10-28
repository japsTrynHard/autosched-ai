import '../models/class_schedule_model.dart';
import '../models/study_block_model.dart';
import '../models/subject_model.dart';
import '../models/task_model.dart';
import '../models/time_range.dart';
import '../models/user_profile_model.dart';
import '../utils/date_time_utils.dart';

class SmartScheduler {
  List<StudyBlockModel> generateWeekPlan({
    required UserProfileModel profile,
    required List<SubjectModel> subjects,
    required List<ClassScheduleModel> classSchedules,
    required List<AcademicTask> tasks,
    required DateTime startDate,
    int horizonDays = 7,
  }) {
    final normalizedStart = AutoDate.dateOnly(startDate);
    final activeSubjectIds = subjects.map((subject) => subject.id).toSet();
    final activeTasks = tasks
        .where(
          (task) =>
              task.status != TaskStatus.completed &&
              (activeSubjectIds.isEmpty || activeSubjectIds.contains(task.subjectId)),
        )
        .map((task) => task.copyWith(
              priorityScore: calculatePriorityScore(task, normalizedStart),
            ))
        .toList()
      ..sort((a, b) => b.priorityScore.compareTo(a.priorityScore));

    final scheduledBlocks = <StudyBlockModel>[];
    final usedMinutesByDay = <String, int>{};

    for (final task in activeTasks) {
      var remainingMinutes = task.estimatedMinutes;
      var safetyCounter = 0;

      while (remainingMinutes > 0 && safetyCounter < 28) {
        safetyCounter++;
        final candidate = _findBestSlot(
          profile: profile,
          classSchedules: classSchedules,
          scheduledBlocks: scheduledBlocks,
          usedMinutesByDay: usedMinutesByDay,
          task: task,
          startDate: normalizedStart,
          horizonDays: horizonDays,
          remainingMinutes: remainingMinutes,
        );

        if (candidate == null) break;

        final blockType = _blockTypeForTask(task);
        final subject = _subjectById(subjects, task.subjectId);
        final block = StudyBlockModel(
          id: 'block_${task.id}_${_dateKey(candidate.date)}_${candidate.startMinute}',
          taskId: task.id,
          subjectId: task.subjectId,
          date: candidate.date,
          startMinute: candidate.startMinute,
          endMinute: candidate.endMinute,
          blockType: blockType,
          reason: _reasonForBlock(task, subject, candidate.date),
        );

        scheduledBlocks.add(block);
        remainingMinutes -= block.durationMinutes;
        usedMinutesByDay[_dateKey(candidate.date)] =
            (usedMinutesByDay[_dateKey(candidate.date)] ?? 0) + block.durationMinutes;
      }
    }

    scheduledBlocks.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;
      return a.startMinute.compareTo(b.startMinute);
    });

    return scheduledBlocks;
  }

  int calculatePriorityScore(AcademicTask task, DateTime today) {
    final daysUntilDeadline = AutoDate.daysBetween(today, task.deadline);
    final deadlineUrgency = _deadlineUrgencyScore(daysUntilDeadline);
    final workload = _workloadScore(task.estimatedMinutes);
    final missedPenalty = task.missedCount >= 2 ? 8 : (task.missedCount == 1 ? 5 : 0);

    return deadlineUrgency +
        task.taskType.score +
        task.importance.score +
        task.difficulty.score +
        workload +
        missedPenalty;
  }

  List<TimeRange> freeSlotsForDate({
    required UserProfileModel profile,
    required List<ClassScheduleModel> classSchedules,
    required List<StudyBlockModel> scheduledBlocks,
    required DateTime date,
  }) {
    final dayStart = profile.wakeMinute;
    final dayEnd = profile.sleepStartMinute;
    final blocked = <TimeRange>[];

    for (final schedule in classSchedules.where((item) => item.weekday == date.weekday)) {
      blocked.add(TimeRange(schedule.startMinute - 10, schedule.endMinute + 10));
    }

    for (final block in scheduledBlocks.where((item) => AutoDate.isSameDay(item.date, date))) {
      blocked.add(TimeRange(block.startMinute, block.endMinute + profile.breakMinutes));
    }

    if (blocked.isEmpty) return [TimeRange(dayStart, dayEnd)];

    blocked.sort((a, b) => a.startMinute.compareTo(b.startMinute));
    final merged = <TimeRange>[];

    for (final range in blocked) {
      final clamped = range.clampToDay(dayStart, dayEnd);
      if (clamped.durationMinutes <= 0) continue;

      if (merged.isEmpty || clamped.startMinute > merged.last.endMinute) {
        merged.add(clamped);
      } else {
        final last = merged.removeLast();
        merged.add(TimeRange(
          last.startMinute,
          clamped.endMinute > last.endMinute ? clamped.endMinute : last.endMinute,
        ));
      }
    }

    final free = <TimeRange>[];
    var cursor = dayStart;
    for (final busy in merged) {
      if (busy.startMinute - cursor >= 25) {
        free.add(TimeRange(cursor, busy.startMinute));
      }
      cursor = busy.endMinute > cursor ? busy.endMinute : cursor;
    }

    if (dayEnd - cursor >= 25) {
      free.add(TimeRange(cursor, dayEnd));
    }

    return free;
  }

  _CandidateSlot? _findBestSlot({
    required UserProfileModel profile,
    required List<ClassScheduleModel> classSchedules,
    required List<StudyBlockModel> scheduledBlocks,
    required Map<String, int> usedMinutesByDay,
    required AcademicTask task,
    required DateTime startDate,
    required int horizonDays,
    required int remainingMinutes,
  }) {
    _CandidateSlot? best;
    final blockLength = _preferredBlockLength(task, remainingMinutes);
    final lastAllowedDate = _lastAllowedDate(task.deadline, startDate, horizonDays);

    for (var offset = 0; offset < horizonDays; offset++) {
      final date = AutoDate.dateOnly(startDate.add(Duration(days: offset)));
      if (date.isAfter(lastAllowedDate)) break;

      final dayKey = _dateKey(date);
      final usedToday = usedMinutesByDay[dayKey] ?? 0;
      final dailyRemaining = profile.maxStudyMinutesPerDay - usedToday;
      if (dailyRemaining < 25) continue;

      final freeSlots = freeSlotsForDate(
        profile: profile,
        classSchedules: classSchedules,
        scheduledBlocks: scheduledBlocks,
        date: date,
      );

      for (final slot in freeSlots) {
        final duration = _min3(blockLength, remainingMinutes, dailyRemaining);
        if (slot.durationMinutes < 25 || duration < 25) continue;

        final adjusted = _adjustStartForPreference(slot, duration, profile.preferredStudyTime);
        if (adjusted + duration > slot.endMinute) continue;

        final score = _slotScore(
          task: task,
          date: date,
          startMinute: adjusted,
          endMinute: adjusted + duration,
          profile: profile,
          usedToday: usedToday,
          blockLength: duration,
        );

        final candidate = _CandidateSlot(
          date: date,
          startMinute: adjusted,
          endMinute: adjusted + duration,
          score: score,
        );

        if (best == null || candidate.score > best.score) {
          best = candidate;
        }
      }
    }

    return best;
  }

  SubjectModel? _subjectById(List<SubjectModel> subjects, String subjectId) {
    for (final subject in subjects) {
      if (subject.id == subjectId) return subject;
    }
    return null;
  }

  int _deadlineUrgencyScore(int daysUntilDeadline) {
    if (daysUntilDeadline <= 0) return 10;
    if (daysUntilDeadline == 1) return 8;
    if (daysUntilDeadline <= 3) return 6;
    if (daysUntilDeadline <= 7) return 4;
    if (daysUntilDeadline <= 14) return 2;
    return 1;
  }

  int _workloadScore(int estimatedMinutes) {
    if (estimatedMinutes >= 180) return 5;
    if (estimatedMinutes >= 120) return 4;
    if (estimatedMinutes >= 60) return 3;
    if (estimatedMinutes >= 30) return 2;
    return 1;
  }

  int _preferredBlockLength(AcademicTask task, int remainingMinutes) {
    var target = 45;
    if (task.difficulty == SubjectDifficulty.hard || task.difficulty == SubjectDifficulty.veryHard) {
      target = 60;
    }
    if (task.taskType == TaskType.exam || task.taskType == TaskType.project) {
      target = 75;
    }
    return remainingMinutes < target ? remainingMinutes : target;
  }

  int _adjustStartForPreference(TimeRange slot, int duration, String preference) {
    final preferred = _preferredWindow(preference);
    if (preferred == null) return slot.startMinute;

    if (slot.startMinute <= preferred.startMinute && preferred.startMinute + duration <= slot.endMinute) {
      return preferred.startMinute;
    }

    if (slot.overlaps(preferred)) {
      final candidate = slot.startMinute < preferred.startMinute ? preferred.startMinute : slot.startMinute;
      if (candidate + duration <= slot.endMinute) return candidate;
    }

    return slot.startMinute;
  }

  double _slotScore({
    required AcademicTask task,
    required DateTime date,
    required int startMinute,
    required int endMinute,
    required UserProfileModel profile,
    required int usedToday,
    required int blockLength,
  }) {
    final daysToDeadline = AutoDate.daysBetween(date, task.deadline);
    final preference = _preferenceScore(startMinute, endMinute, profile.preferredStudyTime);
    final deadlineBoost = daysToDeadline <= 0 ? 8 : (8 / (daysToDeadline + 1));
    final enoughDuration = blockLength >= _preferredBlockLength(task, blockLength) ? 4 : 2;
    final fatigueRisk = usedToday + blockLength > (profile.maxStudyMinutesPerDay * 0.8) ? 3 : 0;
    final lateRisk = endMinute > profile.sleepStartMinute - 30 ? 2 : 0;
    final hardSubjectBoost = task.difficulty.index >= SubjectDifficulty.hard.index && preference >= 6 ? 3 : 0;

    return (task.priorityScore * 0.45) +
        preference +
        deadlineBoost +
        enoughDuration +
        hardSubjectBoost -
        fatigueRisk -
        lateRisk;
  }

  double _preferenceScore(int startMinute, int endMinute, String preference) {
    final window = _preferredWindow(preference);
    if (window == null) return 3;
    final slot = TimeRange(startMinute, endMinute);
    if (slot.overlaps(window)) return 8;
    if ((startMinute - window.endMinute).abs() <= 120 || (window.startMinute - endMinute).abs() <= 120) {
      return 4;
    }
    return 1;
  }

  TimeRange? _preferredWindow(String preference) {
    final normalized = preference.toLowerCase();
    if (normalized.contains('morning')) return const TimeRange(7 * 60, 11 * 60);
    if (normalized.contains('afternoon')) return const TimeRange(13 * 60, 17 * 60);
    if (normalized.contains('evening')) return const TimeRange(18 * 60, 21 * 60);
    return null;
  }

  DateTime _lastAllowedDate(DateTime deadline, DateTime startDate, int horizonDays) {
    final horizonEnd = AutoDate.dateOnly(startDate.add(Duration(days: horizonDays - 1)));
    final deadlineDate = AutoDate.dateOnly(deadline);
    if (deadlineDate.isBefore(startDate)) return startDate;
    return deadlineDate.isBefore(horizonEnd) ? deadlineDate : horizonEnd;
  }

  int _min3(int a, int b, int c) {
    var value = a < b ? a : b;
    value = value < c ? value : c;
    return value;
  }

  String _blockTypeForTask(AcademicTask task) {
    switch (task.taskType) {
      case TaskType.exam:
        return 'Exam Preparation Block';
      case TaskType.project:
        return 'Project Work Block';
      case TaskType.quiz:
        return 'Review Block';
      case TaskType.assignment:
      case TaskType.laboratory:
        return 'Assignment Block';
      case TaskType.recitation:
        return 'Quick Review';
      case TaskType.groupMeeting:
        return 'Group Study Block';
      case TaskType.personal:
        return 'Personal Block';
    }
  }

  String _reasonForBlock(AcademicTask task, SubjectModel? subject, DateTime date) {
    final subjectName = subject?.code ?? 'this subject';
    final days = AutoDate.daysBetween(date, task.deadline);
    final dueText = days <= 0 ? 'due today' : 'due in $days day${days == 1 ? '' : 's'}';
    return '$subjectName is ${task.difficulty.label}, priority score is ${task.priorityScore}, and the task is $dueText.';
  }

  String _dateKey(DateTime date) => '${date.year}-${date.month}-${date.day}';
}

class _CandidateSlot {
  const _CandidateSlot({
    required this.date,
    required this.startMinute,
    required this.endMinute,
    required this.score,
  });

  final DateTime date;
  final int startMinute;
  final int endMinute;
  final double score;
}
