import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../models/subject_model.dart';
import '../models/task_model.dart';
// ignore: unused_import
import '../theme/app_theme.dart';
import '../utils/date_time_utils.dart';
import '../widgets/auto_top_bar.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key, this.taskToEdit});

  /// When provided, the screen acts as an edit form instead of create.
  final AcademicTask? taskToEdit;

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  String? _subjectId;
  TaskType _taskType = TaskType.assignment;
  ImportanceLevel _importance = ImportanceLevel.medium;
  SubjectDifficulty _difficulty = SubjectDifficulty.moderate;
  DateTime _deadline = DateTime.now().add(const Duration(days: 2));
  TimeOfDay _deadlineTime = const TimeOfDay(hour: 23, minute: 59);
  double _duration = 60;

  @override
  void initState() {
    super.initState();
    final t = widget.taskToEdit;
    if (t != null) {
      _titleController.text = t.title;
      _notesController.text = t.notes ?? '';
      _subjectId = t.subjectId;
      _taskType = t.taskType;
      _importance = t.importance;
      _difficulty = t.difficulty;
      _deadline = t.deadline;
      _deadlineTime = TimeOfDay(hour: t.deadline.hour, minute: t.deadline.minute);
      _duration = t.estimatedMinutes.toDouble();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final subjects = app.activeSubjects.isNotEmpty ? app.activeSubjects : app.subjects;
    if (subjects.isNotEmpty) _subjectId ??= subjects.first.id;

    return Scaffold(
      appBar: AutoTopBar(
        title: widget.taskToEdit == null ? 'Add Academic Task' : 'Edit Task',
        subtitle: widget.taskToEdit == null
            ? 'Create a deadline and auto-place study blocks'
            : 'Update your task and regenerate study blocks',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            Text(
              'AutoSched AI will score this task and insert study blocks into free time.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task title',
                prefixIcon: Icon(Icons.title_rounded),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter task title'
                  : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _subjectId,
              decoration: const InputDecoration(
                labelText: 'Subject',
                prefixIcon: Icon(Icons.school_rounded),
              ),
              items: subjects
                  .map(
                    (subject) => DropdownMenuItem(
                      value: subject.id,
                      child: Text(subject.displayName),
                    ),
                  )
                  .toList(),
              validator: (value) => value == null ? 'Add or import a subject first' : null,
              onChanged: subjects.isEmpty ? null : (value) {
                setState(() {
                  _subjectId = value;
                  _difficulty =
                      app.subjectById(value ?? '')?.difficulty ?? _difficulty;
                });
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<TaskType>(
              initialValue: _taskType,
              decoration: const InputDecoration(
                labelText: 'Task type',
                prefixIcon: Icon(Icons.category_rounded),
              ),
              items: TaskType.values
                  .map(
                    (type) =>
                        DropdownMenuItem(value: type, child: Text(type.label)),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _taskType = value ?? _taskType),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ImportanceLevel>(
                    initialValue: _importance,
                    decoration: const InputDecoration(labelText: 'Importance'),
                    items: ImportanceLevel.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _importance = value ?? _importance),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<SubjectDifficulty>(
                    initialValue: _difficulty,
                    decoration: const InputDecoration(labelText: 'Difficulty'),
                    items: SubjectDifficulty.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _difficulty = value ?? _difficulty),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _pickDeadline,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Deadline date and time',
                  prefixIcon: Icon(Icons.event_rounded),
                ),
                child: Text(
                  '${AutoDate.formatDate(_deadline)} • ${_deadlineTime.format(context)}',
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withOpacity(0.65),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated duration: ${_duration.round()} minutes',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Slider(
                    value: _duration,
                    min: 30,
                    max: 240,
                    divisions: 7,
                    label: '${_duration.round()} min',
                    onChanged: (value) => setState(() => _duration = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Notes optional',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _saveTask,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Save and Generate Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _deadlineTime,
    );
    if (time == null) return;

    setState(() {
      _deadline = date;
      _deadlineTime = time;
    });
  }

  void _saveTask() {
    if (!_formKey.currentState!.validate()) return;
    final app = AppScope.of(context);
    final deadline = DateTime(
      _deadline.year,
      _deadline.month,
      _deadline.day,
      _deadlineTime.hour,
      _deadlineTime.minute,
    );

    final task = AcademicTask(
      id: 'task_${DateTime.now().millisecondsSinceEpoch}',
      subjectId: _subjectId!,
      title: _titleController.text.trim(),
      taskType: _taskType,
      deadline: deadline,
      estimatedMinutes: _duration.round(),
      importance: _importance,
      difficulty: _difficulty,
      notes: _notesController.text.trim(),
    );

    if (widget.taskToEdit != null) {
      app.updateTask(task.copyWith(id: widget.taskToEdit!.id));
    } else {
      app.addTask(task);
    }
    Navigator.of(context).pop();
  }
}
