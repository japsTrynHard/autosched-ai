import '../utils/date_time_utils.dart';

enum CloudSyncStage {
  idle,
  pendingChanges,
  preparing,
  uploadingImages,
  writingFirestore,
  schedulingNotifications,
  completed,
  error,
}

extension CloudSyncStageX on CloudSyncStage {
  String get label {
    switch (this) {
      case CloudSyncStage.idle:
        return 'Ready';
      case CloudSyncStage.pendingChanges:
        return 'Pending Backup';
      case CloudSyncStage.preparing:
        return 'Preparing';
      case CloudSyncStage.uploadingImages:
        return 'Image Check';
      case CloudSyncStage.writingFirestore:
        return 'Saving Data';
      case CloudSyncStage.schedulingNotifications:
        return 'Reminder Queue';
      case CloudSyncStage.completed:
        return 'Backed Up';
      case CloudSyncStage.error:
        return 'Needs Attention';
    }
  }
}

class CloudSyncStatus {
  const CloudSyncStatus({
    required this.stage,
    required this.progress,
    required this.message,
    this.lastSyncedAt,
  });

  factory CloudSyncStatus.idle() {
    return const CloudSyncStatus(
      stage: CloudSyncStage.idle,
      progress: 0,
      message: 'Backup center is ready. Your data will save after setup.',
    );
  }

  factory CloudSyncStatus.pending(String reason) {
    return CloudSyncStatus(
      stage: CloudSyncStage.pendingChanges,
      progress: 0,
      message: reason,
    );
  }

  final CloudSyncStage stage;
  final double progress;
  final String message;
  final DateTime? lastSyncedAt;

  bool get isRunning {
    return stage == CloudSyncStage.preparing ||
        stage == CloudSyncStage.uploadingImages ||
        stage == CloudSyncStage.writingFirestore ||
        stage == CloudSyncStage.schedulingNotifications;
  }

  bool get isSynced => stage == CloudSyncStage.completed;

  String get progressLabel => '${(progress * 100).round()}%';

  String get lastSyncedLabel {
    final value = lastSyncedAt;
    if (value == null) return 'Not backed up yet';
    return '${AutoDate.formatDate(value)} • ${AutoDate.formatMinute(value.hour * 60 + value.minute)}';
  }

  CloudSyncStatus copyWith({
    CloudSyncStage? stage,
    double? progress,
    String? message,
    DateTime? lastSyncedAt,
  }) {
    return CloudSyncStatus(
      stage: stage ?? this.stage,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}
