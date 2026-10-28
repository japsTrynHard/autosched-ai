import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../models/task_model.dart';
import '../models/cloud_sync_model.dart';
import '../theme/app_theme.dart';
import '../utils/date_time_utils.dart';
import '../widgets/auto_card.dart';
import '../widgets/info_chip.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_card.dart';
import '../widgets/timeline_tile.dart';
import '../widgets/auto_top_bar.dart';
import '../widgets/brand_logo.dart';
import 'sync_center_screen.dart';
import 'add_task_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final selectedDate = app.selectedDate;
    final nextClass = app.nextClassForDate(selectedDate);
    final nextBlock = app.nextStudyBlockForDate(selectedDate);
    final topTask = app.topPriorityTask();
    final protectedHours = (app.protectedFreeMinutesForDate(selectedDate) / 60)
        .toStringAsFixed(1);

    return Scaffold(
      appBar: AutoTopBar(
        title: 'AutoSched AI',
        subtitle: 'Smart academic planner',
        actions: [
          IconButton(
            tooltip: 'Regenerate smart plan',
            onPressed: () => app.regenerateSchedule(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => app.regenerateSchedule(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
          children: [
            AutoCard(
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 112,
                      height: 72,
                      color: const Color(0xFF0A0D12),
                      alignment: Alignment.center,
                      child: const AutoSchedFullLogo(height: 58),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AutoSched AI is ready',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Scan your COR, review classes, then let the smart planner protect your time.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                height: 1.25,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AutoCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.cloud_queue_rounded,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.syncStatus.stage.label,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          app.syncStatus.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                height: 1.25,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Open cloud sync center',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SyncCenterScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Good day, ${app.profile.fullName.split(' ').first}.',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Here is your smart academic plan for ${AutoDate.formatDate(selectedDate)}.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.96,
              children: [
                StatCard(
                  title: 'Today Classes',
                  value: '${app.classesForDate(selectedDate).length}',
                  subtitle: 'fixed blocks',
                  icon: Icons.school_rounded,
                  color: AppTheme.primary,
                ),
                StatCard(
                  title: 'Pending Tasks',
                  value: '${app.pendingTaskCount}',
                  subtitle: '${app.completedTaskCount} completed',
                  icon: Icons.assignment_turned_in_rounded,
                  color: AppTheme.purple,
                ),
                StatCard(
                  title: 'Study Blocks',
                  value: '${app.blocksForDate(selectedDate).length}',
                  subtitle:
                      '${app.studyMinutesForDate(selectedDate)} min planned',
                  icon: Icons.psychology_alt_rounded,
                  color: AppTheme.success,
                ),
                StatCard(
                  title: 'Protected Time',
                  value: '${protectedHours}h',
                  subtitle: 'rest/free time',
                  icon: Icons.self_improvement_rounded,
                  color: AppTheme.warning,
                ),
              ],
            ),
            const SizedBox(height: 18),
            // ── Getting Started banner (shown when no tasks added yet) ─
            if (app.tasks.isEmpty)
              AutoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.purple.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.rocket_launch_rounded,
                            color: AppTheme.purple),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('Getting Started',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900)),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    Text(
                      '1. Scan your COR to import class schedule\n'
                      '2. Add your first academic task\n'
                      '3. AutoSched AI will build your study plan',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddTaskScreen()),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add First Task'),
                    ),
                  ],
                ),
              ),
            // ── Weekly progress card ──────────────────────────────────
            AutoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.bar_chart_rounded, color: AppTheme.purple),
                    const SizedBox(width: 8),
                    Text('This Week\'s Progress',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: _WeekStat(
                        label: 'Completed',
                        value: '${app.weeklyCompletedTaskCount}',
                        unit: 'tasks',
                        color: AppTheme.success,
                        icon: Icons.check_circle_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _WeekStat(
                        label: 'Study Time',
                        value: '${(app.weeklyStudyMinutes / 60).toStringAsFixed(1)}',
                        unit: 'hours',
                        color: AppTheme.primary,
                        icon: Icons.timer_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _WeekStat(
                        label: 'Overdue',
                        value: '${app.overdueTaskCount}',
                        unit: 'tasks',
                        color: app.overdueTaskCount > 0
                            ? AppTheme.danger
                            : AppTheme.success,
                        icon: app.overdueTaskCount > 0
                            ? Icons.warning_rounded
                            : Icons.verified_rounded,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            AutoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Smart Recommendation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    app.dashboardSuggestion(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.35,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      InfoChip(
                        label: app.burnoutStatusForDate(selectedDate),
                        icon: Icons.favorite_rounded,
                        color: AppTheme.success,
                      ),
                      InfoChip(
                        label: 'Max ${app.profile.maxStudyHoursPerDay}h/day',
                        icon: Icons.timer_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SectionHeader(
              title: 'Next Items',
              subtitle:
                  'Generated from class schedules, priorities, and free time.',
              trailing: TextButton.icon(
                onPressed: () => app.regenerateSchedule(),
                icon: const Icon(Icons.bolt_rounded),
                label: const Text('Replan'),
              ),
            ),
            if (nextClass != null)
              TimelineTile(
                time: AutoDate.formatTimeRange(
                  nextClass.startMinute,
                  nextClass.endMinute,
                ),
                title:
                    app.subjectById(nextClass.subjectId)?.displayName ??
                    'Class Schedule',
                subtitle: '${nextClass.room} • ${nextClass.source}',
                icon: Icons.class_rounded,
                color: AppTheme.primary,
              ),
            if (nextBlock != null)
              TimelineTile(
                time: AutoDate.formatTimeRange(
                  nextBlock.startMinute,
                  nextBlock.endMinute,
                ),
                title:
                    app.taskById(nextBlock.taskId)?.title ??
                    nextBlock.blockType,
                subtitle: nextBlock.reason,
                icon: Icons.menu_book_rounded,
                color: AppTheme.success,
              ),
            if (topTask != null)
              AutoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Priority Task',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      topTask.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        InfoChip(
                          label: topTask.taskType.label,
                          icon: Icons.category_rounded,
                          color: _taskColor(topTask),
                        ),
                        InfoChip(
                          label: 'Priority ${topTask.priorityScore}',
                          icon: Icons.local_fire_department_rounded,
                          color: AppTheme.danger,
                        ),
                        InfoChip(
                          label:
                              'Due ${AutoDate.formatMonthDay(topTask.deadline)}',
                          icon: Icons.event_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (nextClass == null && nextBlock == null && topTask == null)
              AutoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.event_available_rounded,
                          color: AppTheme.success, size: 26),
                    ),
                    const SizedBox(height: 12),
                    Text('Nothing scheduled for today',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text('No classes, study blocks, or pending tasks. '
                        'Enjoy your free time or add a task to plan ahead.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.35,
                          )),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _taskColor(AcademicTask task) {
    if (task.importance == ImportanceLevel.critical) return AppTheme.danger;
    if (task.importance == ImportanceLevel.high) return AppTheme.warning;
    return AppTheme.primary;
  }
}

// ── Weekly stat tile ──────────────────────────────────────────────────────────

class _WeekStat extends StatelessWidget {
  const _WeekStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w900, fontSize: 20)),
          Text(unit,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
