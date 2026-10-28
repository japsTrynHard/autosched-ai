import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../theme/app_theme.dart';
import '../utils/date_time_utils.dart';
import '../widgets/auto_top_bar.dart';

/// Pure-Flutter monthly calendar overview.
/// Shows dots for days that have classes or study blocks.
class MonthCalendarScreen extends StatefulWidget {
  const MonthCalendarScreen({super.key});

  @override
  State<MonthCalendarScreen> createState() => _MonthCalendarScreenState();
}

class _MonthCalendarScreenState extends State<MonthCalendarScreen> {
  late DateTime _monthStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _monthStart = DateTime(now.year, now.month, 1);
  }

  void _prevMonth() => setState(() {
        _monthStart = DateTime(_monthStart.year, _monthStart.month - 1, 1);
      });

  void _nextMonth() => setState(() {
        _monthStart = DateTime(_monthStart.year, _monthStart.month + 1, 1);
      });

  List<DateTime?> _buildCalendarDays() {
    final firstWeekday = _monthStart.weekday % 7; // Sunday = 0
    final daysInMonth =
        DateTime(_monthStart.year, _monthStart.month + 1, 0).day;
    final cells = <DateTime?>[];
    for (var i = 0; i < firstWeekday; i++) {
      cells.add(null);
    }
    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(_monthStart.year, _monthStart.month, d));
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final today = AutoDate.dateOnly(DateTime.now());
    final cells = _buildCalendarDays();
    final monthLabel =
        '${AutoDate.monthShort(_monthStart.month)} ${_monthStart.year}';

    return Scaffold(
      appBar: const AutoTopBar(
        title: 'Month Overview',
        subtitle: 'See your study plan at a glance',
      ),
      body: Column(
        children: [
          // Month navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  onPressed: _prevMonth,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(
                    monthLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
          // Day-of-week header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Calendar grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: GridView.builder(
                itemCount: cells.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 4,
                ),
                itemBuilder: (context, index) {
                  final date = cells[index];
                  if (date == null) return const SizedBox.shrink();
                  final isToday = AutoDate.isSameDay(date, today);
                  final isSelected =
                      AutoDate.isSameDay(date, app.selectedDate);
                  final hasBlocks = app.blocksForDate(date).isNotEmpty;
                  final hasClasses =
                      app.classesForDate(date).isNotEmpty;
                  return GestureDetector(
                    onTap: () {
                      app.selectDate(date);
                      Navigator.of(context).pop();
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppTheme.primary
                                : isToday
                                    ? AppTheme.primary.withOpacity(0.15)
                                    : Colors.transparent,
                          ),
                          child: Center(
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : isToday
                                        ? AppTheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (hasClasses)
                              _Dot(color: isSelected
                                  ? Colors.white
                                  : AppTheme.primary),
                            if (hasBlocks)
                              _Dot(color: isSelected
                                  ? Colors.white70
                                  : AppTheme.success),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          // Legend
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
            child: Row(
              children: [
                _Dot(color: AppTheme.primary),
                const SizedBox(width: 6),
                Text('Classes',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 14),
                _Dot(color: AppTheme.success),
                const SizedBox(width: 6),
                Text('Study blocks',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      margin: const EdgeInsets.only(right: 2),
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
