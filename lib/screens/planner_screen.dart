import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_scope.dart';
import '../theme/app_theme.dart';
import '../utils/date_time_utils.dart';
import '../widgets/auto_card.dart';
import '../widgets/info_chip.dart';
import '../widgets/section_header.dart';
import '../widgets/timeline_tile.dart';
import '../widgets/auto_top_bar.dart';
import 'month_calendar_screen.dart';

class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final selectedDate = app.selectedDate;
    final classes = app.classesForDate(selectedDate);
    final blocks = app.blocksForDate(selectedDate);

    return Scaffold(
      appBar: AutoTopBar(
        title: 'Smart Planner',
        subtitle: 'Class-aware daily timeline',
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MonthCalendarScreen()),
            ),
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Month overview',
          ),
          IconButton(
            onPressed: () => app.regenerateSchedule(),
            icon: const Icon(Icons.auto_fix_high_rounded),
            tooltip: 'Generate plan',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => app.regenerateSchedule(),
        child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
        children: [
          _DateSelector(selectedDate: selectedDate),
          const SizedBox(height: 18),
          AutoCard(
            child: Row(
              children: [
                Expanded(
                  child: _PlannerMetric(
                    title: 'Study Load',
                    value: '${app.studyMinutesForDate(selectedDate)} min',
                    icon: Icons.psychology_alt_rounded,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PlannerMetric(
                    title: 'Free/Rest',
                    value: '${app.protectedFreeMinutesForDate(selectedDate)} min',
                    icon: Icons.self_improvement_rounded,
                    color: AppTheme.warning,
                  ),
                ),
              ],
            ),
          ),
          SectionHeader(
            title: 'Daily Timeline',
            subtitle: 'Classes are fixed. Study blocks are generated around them.',
          ),
          if (classes.isEmpty && blocks.isEmpty)
            AutoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.event_available_rounded, color: AppTheme.success, size: 32),
                  const SizedBox(height: 10),
                  Text(
                    'No fixed class or generated block for this day.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'This means your free time is protected unless urgent tasks need to be scheduled.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ..._combinedTimeline(context),
          SectionHeader(
            title: 'Smart Logic Used',
            subtitle: 'COR schedules can be imported, conflicts are prevented, and the generated plan can be saved to your account.',
          ),
          AutoCard(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                InfoChip(label: 'Conflict-free', icon: Icons.block_rounded, color: AppTheme.primary),
                InfoChip(label: 'Priority scoring', icon: Icons.local_fire_department_rounded, color: AppTheme.danger),
                InfoChip(label: 'Break buffer', icon: Icons.timer_rounded, color: AppTheme.warning),
                InfoChip(label: 'Free time protected', icon: Icons.favorite_rounded, color: AppTheme.success),
              ],
            ),
          ),
          // ── Export button ────────────────────────────────────────────
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy schedule to clipboard'),
              onPressed: () {
                final app = AppScope.of(context);
                final date = app.selectedDate;
                final buf = StringBuffer();
                buf.writeln('AutoSched AI — Schedule for ${AutoDate.formatDate(date)}');
                buf.writeln('');
                final classes = app.classesForDate(date);
                if (classes.isNotEmpty) {
                  buf.writeln('Classes:');
                  for (final c in classes) {
                    final subj = app.subjectById(c.subjectId);
                    buf.writeln('  ${AutoDate.formatTimeRange(c.startMinute, c.endMinute)}  ${subj?.displayName ?? 'Class'} — ${c.room}');
                  }
                  buf.writeln('');
                }
                final blocks = app.blocksForDate(date);
                if (blocks.isNotEmpty) {
                  buf.writeln('Study blocks:');
                  for (final b in blocks) {
                    final task = app.taskById(b.taskId);
                    buf.writeln('  ${AutoDate.formatTimeRange(b.startMinute, b.endMinute)}  ${task?.title ?? b.blockType} — ${b.reason}');
                  }
                }
                Clipboard.setData(ClipboardData(text: buf.toString()));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Schedule copied to clipboard!'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
            ),
          ),
        ],
        ),
      ),
    );
  }

  List<Widget> _combinedTimeline(BuildContext context) {
    final app = AppScope.of(context);
    final selectedDate = app.selectedDate;
    final items = <_TimelineEntry>[];

    for (final item in app.classesForDate(selectedDate)) {
      final subject = app.subjectById(item.subjectId);
      items.add(_TimelineEntry(
        startMinute: item.startMinute,
        endMinute: item.endMinute,
        widget: TimelineTile(
          time: AutoDate.formatTimeRange(item.startMinute, item.endMinute),
          title: subject?.displayName ?? 'Class Schedule',
          subtitle: '${item.room} • fixed class block',
          icon: Icons.school_rounded,
          color: AppTheme.primary,
        ),
      ));
    }

    for (final block in app.blocksForDate(selectedDate)) {
      final task = app.taskById(block.taskId);
      final subject = app.subjectById(block.subjectId);
      items.add(_TimelineEntry(
        startMinute: block.startMinute,
        endMinute: block.endMinute,
        widget: TimelineTile(
          time: AutoDate.formatTimeRange(block.startMinute, block.endMinute),
          title: task?.title ?? block.blockType,
          subtitle: '${subject?.code ?? 'Subject'} • ${block.blockType} • ${block.reason}',
          icon: Icons.menu_book_rounded,
          color: AppTheme.success,
        ),
      ));
    }

    items.sort((a, b) => a.startMinute.compareTo(b.startMinute));
    return items.map((entry) => entry.widget).toList();
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({required this.selectedDate});

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final start = AutoDate.dateOnly(DateTime.now());
    final dates = List.generate(7, (index) => start.add(Duration(days: index)));

    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = AutoDate.isSameDay(date, selectedDate);
          final hasBlocks = app.blocksForDate(date).isNotEmpty ||
              app.classesForDate(date).isNotEmpty;
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              app.selectDate(date);
              app.regenerateSchedule();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 84,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? AppTheme.primary : Theme.of(context).colorScheme.outlineVariant.withOpacity(0.65)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        AutoDate.weekdayShort(date.weekday),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Flexible(
                    flex: 2,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${date.day}',
                        maxLines: 1,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Activity dot indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasBlocks
                          ? (isSelected
                              ? Colors.white
                              : AppTheme.success)
                          : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlannerMetric extends StatelessWidget {
  const _PlannerMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineEntry {
  _TimelineEntry({required this.startMinute, required this.endMinute, required this.widget});

  final int startMinute;
  final int endMinute;
  final Widget widget;
}
