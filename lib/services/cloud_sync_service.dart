import 'dart:convert';

import '../models/class_schedule_model.dart';
import '../models/cloud_sync_model.dart';
import '../models/study_block_model.dart';
import '../models/subject_model.dart';
import '../models/task_model.dart';
import '../models/user_profile_model.dart';
import '../utils/date_time_utils.dart';

class CloudSyncService {
  Future<void> simulateSync({
    required UserProfileModel profile,
    required List<SubjectModel> subjects,
    required List<ClassScheduleModel> classSchedules,
    required List<AcademicTask> tasks,
    required List<StudyBlockModel> studyBlocks,
    required void Function(CloudSyncStatus status) onProgress,
  }) async {
    Future<void> step(CloudSyncStage stage, double progress, String message) async {
      onProgress(CloudSyncStatus(stage: stage, progress: progress, message: message));
      await Future<void>.delayed(const Duration(milliseconds: 420));
    }

    await step(
      CloudSyncStage.preparing,
      0.12,
      'Preparing user profile, subjects, fixed classes, tasks, and generated study blocks.',
    );
    await step(
      CloudSyncStage.uploadingImages,
      0.36,
      'Image queue checked. Cloud image upload can be added later if needed.',
    );
    await step(
      CloudSyncStage.writingFirestore,
      0.68,
      'Saved records prepared for ${subjects.length} subjects, ${classSchedules.length} class schedules, and ${tasks.length} tasks.',
    );
    await step(
      CloudSyncStage.schedulingNotifications,
      0.88,
      'Notification queue prepared from ${studyBlocks.length} generated study block/s.',
    );
    onProgress(
      CloudSyncStatus(
        stage: CloudSyncStage.completed,
        progress: 1,
        message: 'Backup completed. The app data is ready for saved account access.',
        lastSyncedAt: DateTime.now(),
      ),
    );
  }

  String buildFirestoreExportJson({
    required UserProfileModel profile,
    required List<SubjectModel> subjects,
    required List<ClassScheduleModel> classSchedules,
    required List<AcademicTask> tasks,
    required List<StudyBlockModel> studyBlocks,
  }) {
    final encoder = const JsonEncoder.withIndent('  ');
    return encoder.convert({
      'users': {
        profile.userId: _profileMap(profile),
      },
      'subjects': subjects.map(_subjectMap).toList(),
      'classSchedules': classSchedules.map(_classScheduleMap).toList(),
      'tasks': tasks.map(_taskMap).toList(),
      'studyBlocks': studyBlocks.map(_studyBlockMap).toList(),
      'imageBackup': {
        'profilePhotoUrl': profile.profileImagePath,
        'profilePhotoPublicId': profile.profileImagePublicId,
        'corImageRule': 'Raw COR images are used for OCR only. The saved account data is the reviewed schedule.',
      },
      'securityRulesNote': 'Each document should include userId and only be readable/writable by the authenticated owner.',
    });
  }

  Map<String, dynamic> _profileMap(UserProfileModel profile) {
    return {
      'userId': profile.userId,
      'fullName': profile.fullName,
      'school': profile.school,
      'course': profile.course,
      'yearLevel': profile.yearLevel,
      'preferredStudyTime': profile.preferredStudyTime,
      'sleepStart': AutoDate.formatMinute(profile.sleepStartMinute),
      'sleepEnd': AutoDate.formatMinute(profile.sleepEndMinute),
      'wakeTime': AutoDate.formatMinute(profile.wakeMinute),
      'maxStudyHoursPerDay': profile.maxStudyHoursPerDay,
      'breakMinutes': profile.breakMinutes,
      'isWorkingStudent': profile.isWorkingStudent,
      'profileImageUrl': profile.profileImagePath,
      'profileImagePublicId': profile.profileImagePublicId,
      'hasExtracurricular': profile.hasExtracurricular,
    };
  }

  Map<String, dynamic> _subjectMap(SubjectModel subject) {
    return {
      'subjectId': subject.id,
      'code': subject.code,
      'name': subject.name,
      'units': subject.units,
      'difficulty': subject.difficulty.label,
      'difficultyWeight': subject.difficulty.studyWeight,
      'instructor': subject.instructor,
    };
  }

  Map<String, dynamic> _classScheduleMap(ClassScheduleModel schedule) {
    return {
      'scheduleId': schedule.id,
      'subjectId': schedule.subjectId,
      'weekday': schedule.weekday,
      'dayLabel': AutoDate.weekdayLong(schedule.weekday),
      'startTime': AutoDate.formatMinute(schedule.startMinute),
      'endTime': AutoDate.formatMinute(schedule.endMinute),
      'room': schedule.room,
      'source': schedule.source,
      'isFixed': schedule.isFixed,
    };
  }

  Map<String, dynamic> _taskMap(AcademicTask task) {
    return {
      'taskId': task.id,
      'subjectId': task.subjectId,
      'title': task.title,
      'taskType': task.taskType.label,
      'deadline': task.deadline.toIso8601String(),
      'estimatedMinutes': task.estimatedMinutes,
      'importance': task.importance.label,
      'difficulty': task.difficulty.label,
      'notes': task.notes,
      'status': task.status.label,
      'missedCount': task.missedCount,
      'priorityScore': task.priorityScore,
    };
  }

  Map<String, dynamic> _studyBlockMap(StudyBlockModel block) {
    return {
      'blockId': block.id,
      'taskId': block.taskId,
      'subjectId': block.subjectId,
      'date': block.date.toIso8601String(),
      'startTime': AutoDate.formatMinute(block.startMinute),
      'endTime': AutoDate.formatMinute(block.endMinute),
      'blockType': block.blockType,
      'status': block.status,
      'generatedBy': block.generatedBy,
      'reason': block.reason,
    };
  }
}
