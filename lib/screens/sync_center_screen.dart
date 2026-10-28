import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../models/cloud_sync_model.dart';
import '../theme/app_theme.dart';
import '../widgets/auto_card.dart';
import '../widgets/auto_top_bar.dart';
import '../widgets/info_chip.dart';
import '../widgets/section_header.dart';

class SyncCenterScreen extends StatelessWidget {
  const SyncCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final status = app.syncStatus;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const AutoTopBar(
        title: 'Backup Center',
        subtitle: 'Save and restore your planner data',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 110),
        children: [
          AutoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: _statusColor(status.stage).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        _statusIcon(status.stage),
                        color: _statusColor(status.stage),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status.stage.label,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            status.message,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  height: 1.25,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: status.progress,
                    minHeight: 10,
                    backgroundColor: colors.surfaceContainerHighest.withOpacity(
                      0.55,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    InfoChip(
                      label: status.progressLabel,
                      icon: Icons.percent_rounded,
                      color: _statusColor(status.stage),
                    ),
                    InfoChip(
                      label: status.lastSyncedLabel,
                      icon: Icons.history_rounded,
                      color: AppTheme.primary,
                    ),
                    const InfoChip(
                      label: 'Cloud-ready',
                      icon: Icons.verified_user_rounded,
                      color: AppTheme.success,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: status.isRunning
                            ? null
                            : () => app.runCloudSync(),
                        icon: status.isRunning
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.cloud_sync_rounded),
                        label: Text(
                          status.isRunning ? 'Syncing...' : 'Back Up Now',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.outlined(
                      tooltip: 'Reset sync status',
                      onPressed: status.isRunning
                          ? null
                          : () => app.resetCloudSyncStatus(),
                      icon: const Icon(Icons.restart_alt_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SectionHeader(
            title: 'Saved Records',
            subtitle:
                'These are the records prepared for your saved account copy.',
          ),
          AutoCard(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                InfoChip(
                  label: 'users: 1',
                  icon: Icons.person_rounded,
                  color: AppTheme.primary,
                ),
                InfoChip(
                  label: 'subjects: ${app.subjects.length}',
                  icon: Icons.book_rounded,
                  color: AppTheme.purple,
                ),
                InfoChip(
                  label: 'classSchedules: ${app.classSchedules.length}',
                  icon: Icons.school_rounded,
                  color: AppTheme.primary,
                ),
                InfoChip(
                  label: 'tasks: ${app.tasks.length}',
                  icon: Icons.task_alt_rounded,
                  color: AppTheme.warning,
                ),
                InfoChip(
                  label: 'studyBlocks: ${app.studyBlocks.length}',
                  icon: Icons.calendar_month_rounded,
                  color: AppTheme.success,
                ),
              ],
            ),
          ),
          SectionHeader(
            title: 'Image Storage Plan',
            subtitle:
                'Images stay separate from schedule records to keep the planner fast and clean.',
          ),
          AutoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PlanRow(
                  icon: Icons.image_rounded,
                  title: 'Profile image',
                  subtitle:
                      'Stored as an optional profile image when cloud image storage is enabled.',
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 12),
                _PlanRow(
                  icon: Icons.document_scanner_rounded,
                  title: 'COR image',
                  subtitle:
                      'Uploaded only when needed. Extracted schedule is still the main saved data.',
                  color: AppTheme.purple,
                ),
                const SizedBox(height: 12),
                _PlanRow(
                  icon: Icons.privacy_tip_rounded,
                  title: 'Privacy rule',
                  subtitle:
                      'After review, the raw COR image can be deleted or archived depending on defense requirement.',
                  color: AppTheme.success,
                ),
              ],
            ),
          ),
          SectionHeader(
            title: 'Saved Data Preview',
            subtitle:
                'Use this to explain what the app saves during demo.',
            trailing: TextButton.icon(
              onPressed: () => app.refreshCloudExportPreview(),
              icon: const Icon(Icons.data_object_rounded),
              label: const Text('Generate'),
            ),
          ),
          AutoCard(
            child: SelectableText(
              app.cloudExportPreview.isEmpty
                  ? 'Tap Generate or Back Up Now to preview the saved data snapshot.'
                  : app.cloudExportPreview,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                height: 1.35,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          SectionHeader(
            title: 'Cloud Setup Notes',
            subtitle:
                'This build saves verified account data and reviewed COR schedule imports after cloud setup is completed.',
          ),
        ],
      ),
    );
  }

  Color _statusColor(CloudSyncStage stage) {
    switch (stage) {
      case CloudSyncStage.completed:
        return AppTheme.success;
      case CloudSyncStage.pendingChanges:
      case CloudSyncStage.preparing:
      case CloudSyncStage.uploadingImages:
      case CloudSyncStage.writingFirestore:
      case CloudSyncStage.schedulingNotifications:
        return AppTheme.primary;
      case CloudSyncStage.error:
        return AppTheme.danger;
      case CloudSyncStage.idle:
        return AppTheme.purple;
    }
  }

  IconData _statusIcon(CloudSyncStage stage) {
    switch (stage) {
      case CloudSyncStage.completed:
        return Icons.cloud_done_rounded;
      case CloudSyncStage.pendingChanges:
        return Icons.cloud_queue_rounded;
      case CloudSyncStage.preparing:
        return Icons.tune_rounded;
      case CloudSyncStage.uploadingImages:
        return Icons.cloud_upload_rounded;
      case CloudSyncStage.writingFirestore:
        return Icons.storage_rounded;
      case CloudSyncStage.schedulingNotifications:
        return Icons.notifications_active_rounded;
      case CloudSyncStage.error:
        return Icons.error_rounded;
      case CloudSyncStage.idle:
        return Icons.cloud_outlined;
    }
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
