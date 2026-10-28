import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../models/task_model.dart';
import '../models/subject_model.dart';
import '../theme/app_theme.dart';
import '../utils/date_time_utils.dart';
import '../widgets/auto_card.dart';
import '../widgets/info_chip.dart';
import '../widgets/section_header.dart';
import '../widgets/auto_top_bar.dart';
import 'add_task_screen.dart';

enum _TaskFilter { all, assignment, exam, project, quiz, overdue }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  _TaskFilter _filter = _TaskFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AcademicTask> _applyFilters(List<AcademicTask> source) {
    var result = source;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((t) => t.title.toLowerCase().contains(q) || t.taskType.label.toLowerCase().contains(q)).toList();
    }
    switch (_filter) {
      case _TaskFilter.assignment:
        result = result.where((t) => t.taskType == TaskType.assignment).toList(); break;
      case _TaskFilter.exam:
        result = result.where((t) => t.taskType == TaskType.exam).toList(); break;
      case _TaskFilter.project:
        result = result.where((t) => t.taskType == TaskType.project).toList(); break;
      case _TaskFilter.quiz:
        result = result.where((t) => t.taskType == TaskType.quiz).toList(); break;
      case _TaskFilter.overdue:
        final now = DateTime.now();
        result = result.where((t) => t.deadline.isBefore(now) && t.status != TaskStatus.completed).toList(); break;
      case _TaskFilter.all: break;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final allTasks = app.tasks;
    final pending = allTasks.where((t) => t.status != TaskStatus.completed).toList();
    final completed = allTasks.where((t) => t.status == TaskStatus.completed).toList();
    final filteredPending = _applyFilters(pending);
    final filteredCompleted = _applyFilters(completed);
    final overdueCount = app.overdueTaskCount;

    return Scaffold(
      appBar: AutoTopBar(
        title: 'Tasks & Priority',
        subtitle: 'Rank deadlines by urgency and workload',
        actions: [
          IconButton(
            onPressed: () => app.regenerateSchedule(),
            tooltip: 'Recalculate priorities',
            icon: const Icon(Icons.calculate_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 96),
        children: [
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search tasks…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.close_rounded), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); })
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _FilterChip(label: 'All', selected: _filter == _TaskFilter.all, onTap: () => setState(() => _filter = _TaskFilter.all)),
              _FilterChip(label: 'Assignment', selected: _filter == _TaskFilter.assignment, onTap: () => setState(() => _filter = _TaskFilter.assignment)),
              _FilterChip(label: 'Exam', selected: _filter == _TaskFilter.exam, onTap: () => setState(() => _filter = _TaskFilter.exam)),
              _FilterChip(label: 'Project', selected: _filter == _TaskFilter.project, onTap: () => setState(() => _filter = _TaskFilter.project)),
              _FilterChip(label: 'Quiz', selected: _filter == _TaskFilter.quiz, onTap: () => setState(() => _filter = _TaskFilter.quiz)),
              if (overdueCount > 0)
                _FilterChip(label: 'Overdue ($overdueCount)', selected: _filter == _TaskFilter.overdue, onTap: () => setState(() => _filter = _TaskFilter.overdue), color: AppTheme.danger),
            ]),
          ),
          const SizedBox(height: 6),
          SectionHeader(
            title: 'Smart Priority Queue',
            subtitle: 'Deadline, type, importance, difficulty, workload, and missed penalty combined.',
          ),
          if (filteredPending.isEmpty && _searchQuery.isEmpty && _filter == _TaskFilter.all)
            AutoCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.10), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.task_alt_rounded, color: AppTheme.success, size: 28),
                ),
                const SizedBox(height: 14),
                Text('All caught up!', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text('No pending tasks right now. Tap "Add Task" below to start tracking a deadline.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.35)),
                const SizedBox(height: 14),
                SizedBox(width: double.infinity, child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddTaskScreen())),
                  icon: const Icon(Icons.add_rounded), label: const Text('Add Task'),
                )),
              ]),
            ),
          if (filteredPending.isEmpty && (_searchQuery.isNotEmpty || _filter != _TaskFilter.all))
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 16),
              child: Center(child: Text('No tasks match your search or filter.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))),
            ),
          ...filteredPending.map((task) {
            final subject = app.subjectById(task.subjectId);
            return _DismissibleTaskCard(
              key: ValueKey(task.id), task: task, subject: subject,
              onDelete: () {
                app.deleteTask(task.id);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('"${task.title}" deleted.'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ));
              },
            );
          }),
          if (filteredCompleted.isNotEmpty) ...[
            const SizedBox(height: 4),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: Container(padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 18)),
                title: Text('Completed (${filteredCompleted.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                initiallyExpanded: false,
                children: filteredCompleted.map((task) {
                  final subject = app.subjectById(task.subjectId);
                  return _DismissibleTaskCard(
                    key: ValueKey('done_${task.id}'), task: task, subject: subject,
                    onDelete: () {
                      app.deleteTask(task.id);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('"${task.title}" deleted.'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ));
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap, this.color});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppTheme.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label), selected: selected, onSelected: (_) => onTap(),
        selectedColor: activeColor.withOpacity(0.18), checkmarkColor: activeColor,
        labelStyle: TextStyle(color: selected ? activeColor : null, fontWeight: selected ? FontWeight.w700 : null),
      ),
    );
  }
}

class _DismissibleTaskCard extends StatelessWidget {
  const _DismissibleTaskCard({super.key, required this.task, required this.subject, required this.onDelete});
  final AcademicTask task;
  final SubjectModel? subject;
  final VoidCallback onDelete;

  bool get _isOverdue => task.status != TaskStatus.completed && task.deadline.isBefore(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Dismissible(
      key: ValueKey('dismissible_${task.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete_rounded, color: AppTheme.danger),
      ),
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete task?'),
          content: Text('Remove "${task.title}" permanently? This cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            FilledButton(style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
                onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
          ],
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onLongPress: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddTaskScreen(taskToEdit: task))),
        child: AutoCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Checkbox(value: task.status == TaskStatus.completed, onChanged: (_) => app.toggleTaskCompleted(task.id)),
              const SizedBox(width: 4),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(task.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: task.status == TaskStatus.completed ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.onSurface,
                    decoration: task.status == TaskStatus.completed ? TextDecoration.lineThrough : null,
                  )),
                const SizedBox(height: 5),
                Text('${subject?.displayName ?? 'No subject'} • ${task.estimatedMinutes} min workload',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ])),
              _PriorityBadge(score: task.priorityScore),
            ]),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (_isOverdue) const InfoChip(label: 'OVERDUE', icon: Icons.warning_rounded, color: AppTheme.danger),
              InfoChip(label: task.taskType.label, icon: Icons.category_rounded, color: AppTheme.primary),
              InfoChip(label: task.importance.label, icon: Icons.flag_rounded, color: _importanceColor(task.importance)),
              InfoChip(label: task.difficulty.label, icon: Icons.trending_up_rounded, color: AppTheme.purple),
              InfoChip(label: 'Due ${AutoDate.formatDate(task.deadline)}', icon: Icons.event_rounded, color: _isOverdue ? AppTheme.danger : AppTheme.warning),
            ]),
            if (task.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(task.notes, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 10),
            Row(children: [
              TextButton.icon(
                onPressed: task.status == TaskStatus.completed ? null : () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Mark as missed?'),
                      content: Text('This increments the missed count for "${task.title}" and raises its priority penalty.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                        FilledButton(style: FilledButton.styleFrom(backgroundColor: AppTheme.warning),
                            onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Mark missed')),
                      ],
                    ),
                  );
                  if (confirm == true) app.markTaskMissed(task.id);
                },
                icon: const Icon(Icons.history_toggle_off_rounded),
                label: const Text('Mark missed'),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Edit task',
                icon: const Icon(Icons.edit_rounded, size: 20),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddTaskScreen(taskToEdit: task))),
              ),
              const SizedBox(width: 4),
              Text(task.status.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: task.status == TaskStatus.completed ? AppTheme.success : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800)),
            ]),
          ]),
        ),
      ),
    );
  }

  Color _importanceColor(ImportanceLevel level) {
    switch (level) {
      case ImportanceLevel.critical: return AppTheme.danger;
      case ImportanceLevel.high: return AppTheme.warning;
      case ImportanceLevel.medium: return AppTheme.primary;
      case ImportanceLevel.low: return AppTheme.success;
    }
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 28 ? AppTheme.danger : (score >= 22 ? AppTheme.warning : AppTheme.primary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Text('$score', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
        Text('score', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
      ]),
    );
  }
}
