import 'package:flutter/material.dart';

import '../models/class_schedule_model.dart';
import '../models/cloud_sync_model.dart';
import '../models/cor_extraction_model.dart';
import '../models/study_block_model.dart';
import '../models/subject_model.dart';
import '../models/task_model.dart';
import '../models/user_profile_model.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../services/smart_scheduler.dart';
import '../utils/date_time_utils.dart';

class AppController extends ChangeNotifier {
  AppController({
    required this.profile,
    required this.subjects,
    required this.classSchedules,
    required this.tasks,
    this.studyBlocks = const [],
    this.themeMode = ThemeMode.system,
    this.firestoreService,
    this.authService,
    this.isFirebaseEnabled = false,
    this.userEmail,
  }) : selectedDate = AutoDate.dateOnly(DateTime.now()) {
    if (isFirebaseEnabled) {
      syncStatus = const CloudSyncStatus(
        stage: CloudSyncStage.completed,
        progress: 1,
        message: 'Cloud backup is active. Your schedules and tasks can be restored after login.',
      );
    }
  }

  factory AppController.demo() {
    final controller = AppController(
      profile: const UserProfileModel(
        userId: 'local_student',
        fullName: 'AutoSched Student',
        school: 'NU Baliwag',
        course: 'BSIT - Mobile and Web Application',
        yearLevel: '3rd Year',
        preferredStudyTime: 'Evening',
        sleepStartMinute: 22 * 60,
        sleepEndMinute: 6 * 60,
        wakeMinute: 6 * 60,
        maxStudyHoursPerDay: 3,
        breakMinutes: 10,
      ),
      subjects: const [],
      classSchedules: const [],
      tasks: const [],
    );
    controller.regenerateSchedule(notify: false);
    return controller;
  }

  factory AppController.firebase({
    required FirebaseUserBundle bundle,
    required FirestoreService firestoreService,
    required AuthService authService,
    required String? email,
  }) {
    final controller = AppController(
      profile: bundle.profile,
      subjects: bundle.subjects,
      classSchedules: bundle.classSchedules,
      tasks: bundle.tasks,
      studyBlocks: bundle.studyBlocks,
      firestoreService: firestoreService,
      authService: authService,
      isFirebaseEnabled: true,
      userEmail: email,
    );
    controller.regenerateSchedule(notify: false);
    return controller;
  }

  final SmartScheduler _scheduler = SmartScheduler();
  final CloudSyncService _cloudSyncService = CloudSyncService();

  final FirestoreService? firestoreService;
  final AuthService? authService;
  final bool isFirebaseEnabled;
  final String? userEmail;

  UserProfileModel profile;
  List<SubjectModel> subjects;
  List<ClassScheduleModel> classSchedules;
  List<AcademicTask> tasks;
  List<StudyBlockModel> studyBlocks;
  DateTime selectedDate;
  ThemeMode themeMode;
  CloudSyncStatus syncStatus = CloudSyncStatus.idle();
  String cloudExportPreview = '';
  bool _autoSaveQueued = false;

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    notifyListeners();
  }

  void selectDate(DateTime date) {
    selectedDate = AutoDate.dateOnly(date);
    notifyListeners();
  }

  void regenerateSchedule({bool notify = true}) {
    final today = AutoDate.dateOnly(DateTime.now());
    tasks =
        tasks
            .map(
              (task) => task.copyWith(
                priorityScore: _scheduler.calculatePriorityScore(task, today),
              ),
            )
            .toList()
          ..sort((a, b) => b.priorityScore.compareTo(a.priorityScore));

    studyBlocks = _scheduler.generateWeekPlan(
      profile: profile,
      subjects: activeSubjects,
      classSchedules: activeClassSchedules,
      tasks: tasks,
      startDate: selectedDate,
      horizonDays: 7,
    );

    if (notify) notifyListeners();
  }

  void addTask(AcademicTask task) {
    tasks = [...tasks, task];
    // Schedule a 24-hour-before deadline reminder notification
    final reminderTime = task.deadline.subtract(const Duration(hours: 24));
    NotificationService.scheduleDeadlineReminder(
      id: task.id.hashCode.abs(),
      title: 'Deadline tomorrow: ${task.title}',
      body: 'Due ${AutoDate.formatDate(task.deadline)} — make sure your study blocks are ready.',
      scheduledAt: reminderTime,
    );
    _markLocalChange(
      'New task added. AutoSched AI is saving your updated plan.',
    );
    regenerateSchedule();
  }

  void importExtractedSchedule(List<ExtractedClassEntry> entries) {
    final accepted = entries.where((entry) => entry.isReady).toList();
    final nextSubjects = [...subjects];
    final nextSchedules = [...classSchedules];

    for (final entry in accepted) {
      SubjectModel? subject;
      for (final item in nextSubjects) {
        if (item.code.toUpperCase() == entry.subjectCode.toUpperCase() &&
            item.academicYear == profile.academicYear &&
            item.term == profile.term &&
            !item.isArchived) {
          subject = item;
          break;
        }
      }

      final subjectId =
          subject?.id ??
          'sub_${entry.subjectCode.toLowerCase()}_${DateTime.now().microsecondsSinceEpoch}';
      if (subject == null) {
        nextSubjects.add(
          SubjectModel(
            id: subjectId,
            code: entry.subjectCode,
            name: entry.subjectName,
            units: entry.units,
            difficulty: SubjectDifficulty.moderate,
            academicYear: profile.academicYear,
            term: profile.term,
            instructor: entry.instructor.trim().isEmpty
                ? null
                : entry.instructor.trim(),
          ),
        );
      }

      final alreadyImported = nextSchedules.any(
        (schedule) =>
            schedule.subjectId == subjectId &&
            schedule.weekday == entry.weekday &&
            schedule.startMinute == entry.startMinute &&
            schedule.endMinute == entry.endMinute,
      );

      if (!alreadyImported) {
        nextSchedules.add(
          ClassScheduleModel(
            id: 'cor_${entry.id}_${DateTime.now().microsecondsSinceEpoch}',
            subjectId: subjectId,
            weekday: entry.weekday,
            startMinute: entry.startMinute,
            endMinute: entry.endMinute,
            room: entry.room.trim().isEmpty ? 'TBA' : entry.room.trim(),
            source: 'COR Scan',
            isFixed: true,
            academicYear: profile.academicYear,
            term: profile.term,
          ),
        );
      }
    }

    subjects = nextSubjects;
    classSchedules = nextSchedules;
    _markLocalChange(
      'COR schedule imported. Your subjects and class blocks are being saved.',
    );
    regenerateSchedule();
  }

  List<CorImportIssue> issuesForExtractedEntries(
    List<ExtractedClassEntry> entries,
  ) {
    final issues = <CorImportIssue>[];

    for (final entry in entries) {
      if (entry.subjectCode.trim().isEmpty) {
        issues.add(
          CorImportIssue(
            entryId: entry.id,
            message: 'Missing subject code',
            isBlocking: true,
          ),
        );
      }
      if (entry.subjectName.trim().isEmpty ||
          entry.subjectName.contains('Needs')) {
        issues.add(
          CorImportIssue(
            entryId: entry.id,
            message: 'Subject name needs review',
            isBlocking: true,
          ),
        );
      }
      if (!entry.hasValidDay) {
        issues.add(
          CorImportIssue(
            entryId: entry.id,
            message: 'Invalid class day',
            isBlocking: true,
          ),
        );
      }
      if (!entry.hasValidTime) {
        issues.add(
          CorImportIssue(
            entryId: entry.id,
            message: 'Invalid time range',
            isBlocking: true,
          ),
        );
      }

      final importedOverlap = activeClassSchedules.where((schedule) {
        if (schedule.weekday != entry.weekday) return false;
        return entry.startMinute < schedule.endMinute &&
            entry.endMinute > schedule.startMinute;
      }).toList();

      if (importedOverlap.isNotEmpty) {
        issues.add(
          CorImportIssue(
            entryId: entry.id,
            message: 'Overlaps with an existing class schedule',
            isBlocking: false,
          ),
        );
      }
    }

    for (var i = 0; i < entries.length; i++) {
      for (var j = i + 1; j < entries.length; j++) {
        final a = entries[i];
        final b = entries[j];
        if (a.weekday == b.weekday &&
            a.startMinute < b.endMinute &&
            a.endMinute > b.startMinute) {
          issues.add(
            CorImportIssue(
              entryId: a.id,
              message: 'Possible conflict with ${b.subjectCode}',
              isBlocking: false,
            ),
          );
          issues.add(
            CorImportIssue(
              entryId: b.id,
              message: 'Possible conflict with ${a.subjectCode}',
              isBlocking: false,
            ),
          );
        }
      }
    }

    return issues;
  }

  void toggleTaskCompleted(String taskId) {
    tasks = tasks.map((task) {
      if (task.id != taskId) return task;
      final nextStatus = task.status == TaskStatus.completed
          ? TaskStatus.pending
          : TaskStatus.completed;
      return task.copyWith(status: nextStatus);
    }).toList();
    _markLocalChange('Task status updated. Saving changes.');
    regenerateSchedule();
  }

  void markTaskMissed(String taskId) {
    tasks = tasks.map((task) {
      if (task.id != taskId) return task;
      return task.copyWith(
        status: TaskStatus.missed,
        missedCount: task.missedCount + 1,
      );
    }).toList();
    _markLocalChange('Missed task updated. AutoSched AI is recalculating your plan.');
    regenerateSchedule();
  }

  void deleteTask(String taskId) {
    tasks = tasks.where((task) => task.id != taskId).toList();
    studyBlocks = studyBlocks.where((block) => block.taskId != taskId).toList();
    _markLocalChange('Task deleted.');
    notifyListeners();
  }

  Future<void> runCloudSync() async {
    if (syncStatus.isRunning) return;
    cloudExportPreview = _cloudSyncService.buildFirestoreExportJson(
      profile: profile,
      subjects: activeSubjects,
      classSchedules: activeClassSchedules,
      tasks: tasks,
      studyBlocks: studyBlocks,
    );

    if (!isFirebaseEnabled || firestoreService == null) {
      await _cloudSyncService.simulateSync(
        profile: profile,
        subjects: subjects,
        classSchedules: classSchedules,
        tasks: tasks,
        studyBlocks: studyBlocks,
        onProgress: (status) {
          syncStatus = status;
          notifyListeners();
        },
      );
      return;
    }

    try {
      _setSyncStatus(
        const CloudSyncStatus(
          stage: CloudSyncStage.preparing,
          progress: 0.20,
          message: 'Preparing profile, subjects, fixed classes, tasks, and generated study blocks.',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 250));

      _setSyncStatus(
        const CloudSyncStatus(
          stage: CloudSyncStage.writingFirestore,
          progress: 0.70,
          message: 'Saving your current AutoSched AI data to your account.',
        ),
      );
      await firestoreService!.saveAll(
        profile: profile,
        subjects: subjects,
        classSchedules: classSchedules,
        tasks: tasks,
        studyBlocks: studyBlocks,
      );

      _setSyncStatus(
        CloudSyncStatus(
          stage: CloudSyncStage.completed,
          progress: 1,
          message: 'Saved to your account. Your data can reload after app restart or login.',
          lastSyncedAt: DateTime.now(),
        ),
      );
    } catch (error) {
      _setSyncStatus(
        CloudSyncStatus(
          stage: CloudSyncStage.error,
          progress: 0,
          message: 'Cloud backup failed: $error',
        ),
      );
    }
  }

  void refreshCloudExportPreview() {
    cloudExportPreview = _cloudSyncService.buildFirestoreExportJson(
      profile: profile,
      subjects: activeSubjects,
      classSchedules: activeClassSchedules,
      tasks: tasks,
      studyBlocks: studyBlocks,
    );
    notifyListeners();
  }

  void resetCloudSyncStatus() {
    syncStatus = isFirebaseEnabled
        ? const CloudSyncStatus(
            stage: CloudSyncStage.completed,
            progress: 1,
            message: 'Cloud backup is connected. Run backup to refresh your saved copy.',
          )
        : CloudSyncStatus.idle();
    cloudExportPreview = '';
    notifyListeners();
  }

  void updateProfile(UserProfileModel nextProfile) {
    profile = nextProfile;
    _markLocalChange('Profile updated. AutoSched AI is saving your preferences.');
    regenerateSchedule();
  }

  void updateProfileImagePath(String? path, {String? publicId}) {
    profile = profile.copyWith(
      profileImagePath: path,
      profileImagePublicId: publicId,
      clearProfileImagePath: path == null,
    );
    _markLocalChange('Profile photo updated. Saving your account details.');
    notifyListeners();
  }

  void startNewTerm({
    required String academicYear,
    required String term,
    required String yearLevel,
  }) {
    profile = profile.copyWith(
      academicYear: academicYear,
      term: term,
      yearLevel: yearLevel,
    );
    _markLocalChange(
      'New school term selected. Old subjects are kept in history while the planner uses the current term only.',
    );
    regenerateSchedule();
  }

  Future<void> signOut() async {
    await authService?.signOut();
  }

  void _markLocalChange(String message) {
    if (syncStatus.isRunning) return;
    syncStatus = CloudSyncStatus.pending(message);
    if (isFirebaseEnabled) _queueAutoSave();
  }

  void _queueAutoSave() {
    if (_autoSaveQueued) return;
    _autoSaveQueued = true;
    Future<void>.delayed(Duration.zero, () async {
      _autoSaveQueued = false;
      await _saveSnapshotToCloud();
    });
  }

  Future<void> _saveSnapshotToCloud() async {
    if (!isFirebaseEnabled || firestoreService == null || syncStatus.isRunning) {
      return;
    }

    try {
      await firestoreService!.saveAll(
        profile: profile,
        subjects: subjects,
        classSchedules: classSchedules,
        tasks: tasks,
        studyBlocks: studyBlocks,
      );
      syncStatus = CloudSyncStatus(
        stage: CloudSyncStage.completed,
        progress: 1,
        message: 'Auto-saved to your account.',
        lastSyncedAt: DateTime.now(),
      );
      notifyListeners();
    } catch (error) {
      syncStatus = CloudSyncStatus(
        stage: CloudSyncStage.error,
        progress: 0,
        message: 'Auto-save failed: $error',
      );
      notifyListeners();
    }
  }

  void _setSyncStatus(CloudSyncStatus status) {
    syncStatus = status;
    notifyListeners();
  }

  SubjectModel? subjectById(String subjectId) {
    for (final subject in subjects) {
      if (subject.id == subjectId) return subject;
    }
    return null;
  }

  AcademicTask? taskById(String taskId) {
    for (final task in tasks) {
      if (task.id == taskId) return task;
    }
    return null;
  }

  List<ClassScheduleModel> classesForDate(DateTime date) {
    final items =
        activeClassSchedules.where((item) => item.weekday == date.weekday).toList()
          ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
    return items;
  }

  List<StudyBlockModel> blocksForDate(DateTime date) {
    final items =
        studyBlocks
            .where((item) => AutoDate.isSameDay(item.date, date))
            .toList()
          ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
    return items;
  }

  List<SubjectModel> get activeSubjects {
    return subjects
        .where(
          (subject) =>
              !subject.isArchived &&
              subject.academicYear == profile.academicYear &&
              subject.term == profile.term,
        )
        .toList();
  }

  List<ClassScheduleModel> get activeClassSchedules {
    return classSchedules
        .where(
          (schedule) =>
              !schedule.isArchived &&
              schedule.academicYear == profile.academicYear &&
              schedule.term == profile.term,
        )
        .toList();
  }

  List<AcademicTask> get pendingTasks {
    return tasks.where((task) => task.status != TaskStatus.completed).toList()
      ..sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
  }

  int get completedTaskCount =>
      tasks.where((task) => task.status == TaskStatus.completed).length;
  int get pendingTaskCount =>
      tasks.where((task) => task.status != TaskStatus.completed).length;

  int studyMinutesForDate(DateTime date) {
    return blocksForDate(
      date,
    ).fold<int>(0, (total, block) => total + block.durationMinutes);
  }

  int protectedFreeMinutesForDate(DateTime date) {
    final availableWindow = profile.sleepStartMinute - profile.wakeMinute;
    final classMinutes = classesForDate(
      date,
    ).fold<int>(0, (total, item) => total + item.durationMinutes);
    final studyMinutes = studyMinutesForDate(date);
    final protected = availableWindow - classMinutes - studyMinutes;
    return protected < 0 ? 0 : protected;
  }

  AcademicTask? topPriorityTask() {
    final list = pendingTasks;
    if (list.isEmpty) return null;
    return list.first;
  }

  StudyBlockModel? nextStudyBlockForDate(DateTime date) {
    final now = DateTime.now();
    final today = AutoDate.dateOnly(now);
    final currentMinute = now.hour * 60 + now.minute;
    final blocks = blocksForDate(date);

    for (final block in blocks) {
      if (!AutoDate.isSameDay(date, today) ||
          block.startMinute >= currentMinute) {
        return block;
      }
    }
    return blocks.isNotEmpty ? blocks.first : null;
  }

  ClassScheduleModel? nextClassForDate(DateTime date) {
    final now = DateTime.now();
    final today = AutoDate.dateOnly(now);
    final currentMinute = now.hour * 60 + now.minute;
    final classes = classesForDate(date);

    for (final item in classes) {
      if (!AutoDate.isSameDay(date, today) ||
          item.startMinute >= currentMinute) {
        return item;
      }
    }
    return classes.isNotEmpty ? classes.first : null;
  }

  String dashboardSuggestion() {
    final topTask = topPriorityTask();
    final block = nextStudyBlockForDate(selectedDate);
    if (topTask == null) {
      return 'All tasks are completed. You can use the protected free time for rest or light review.';
    }

    final subject = subjectById(topTask.subjectId);
    if (block == null) {
      return 'No available study block was found today. AutoSched AI recommends moving a low-priority activity or checking the weekly planner.';
    }

    return 'Recommended: ${subject?.code ?? 'Subject'} at ${AutoDate.formatMinute(block.startMinute)} because ${topTask.taskType.label.toLowerCase()} has priority score ${topTask.priorityScore}.';
  }

  String burnoutStatusForDate(DateTime date) {
    final minutes = studyMinutesForDate(date);
    final max = profile.maxStudyMinutesPerDay;
    if (minutes >= max) {
      return 'Full load — avoid adding more study blocks today.';
    }
    if (minutes >= (max * 0.75)) {
      return 'Moderate load — breaks are important today.';
    }
    return 'Balanced — rest time is still protected.';
  }

  // ── Edit Task ──────────────────────────────────────────────────────────────

  void updateTask(AcademicTask task) {
    tasks = tasks.map((t) => t.id == task.id ? task : t).toList();
    _markLocalChange('Task updated. AutoSched AI is recalculating your plan.');
    regenerateSchedule();
  }

  // ── Subject Management ─────────────────────────────────────────────────────

  void addSubject(SubjectModel subject) {
    subjects = [...subjects, subject];
    _markLocalChange('Subject added.');
    regenerateSchedule();
  }

  void updateSubject(SubjectModel subject) {
    subjects = subjects.map((s) => s.id == subject.id ? subject : s).toList();
    _markLocalChange('Subject updated.');
    regenerateSchedule();
  }

  void archiveSubject(String subjectId) {
    subjects = subjects
        .map((s) => s.id == subjectId ? s.copyWith(isArchived: true) : s)
        .toList();
    _markLocalChange('Subject archived.');
    regenerateSchedule();
  }

  // ── Weekly Stats ───────────────────────────────────────────────────────────

  int get weeklyCompletedTaskCount {
    return tasks.where((t) => t.status == TaskStatus.completed).length;
  }

  int get weeklyStudyMinutes {
    final now = AutoDate.dateOnly(DateTime.now());
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    return studyBlocks
        .where((b) =>
            !b.date.isBefore(weekStart) && !b.date.isAfter(weekEnd))
        .fold<int>(0, (total, b) => total + b.durationMinutes);
  }

  int get overdueTaskCount {
    final now = DateTime.now();
    return tasks
        .where((t) =>
            t.status != TaskStatus.completed && t.deadline.isBefore(now))
        .length;
  }
}
