import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../models/subject_model.dart';
import '../theme/app_theme.dart';
import '../widgets/auto_card.dart';
import '../widgets/auto_top_bar.dart';
import '../widgets/section_header.dart';

class SubjectManagerScreen extends StatelessWidget {
  const SubjectManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final active = app.activeSubjects;
    final archived = app.subjects
        .where((s) =>
            s.isArchived &&
            s.academicYear == app.profile.academicYear &&
            s.term == app.profile.term)
        .toList();

    return Scaffold(
      appBar: AutoTopBar(
        title: 'Subject Manager',
        subtitle: 'Add, edit, or archive your subjects',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add subject',
            onPressed: () => _showSubjectDialog(context, app, null),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 30),
        children: [
          SectionHeader(
            title: 'Active Subjects',
            subtitle:
                '${app.profile.academicYear} • ${app.profile.term}',
            trailing: FilledButton.tonalIcon(
              onPressed: () => _showSubjectDialog(context, app, null),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
            ),
          ),
          if (active.isEmpty)
            AutoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.book_outlined,
                      color: AppTheme.primary, size: 28),
                  const SizedBox(height: 10),
                  Text('No subjects yet',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(
                    'Tap "Add" to add a subject or scan your COR to import them automatically.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                          height: 1.35,
                        ),
                  ),
                ],
              ),
            ),
          ...active.map((s) => _SubjectCard(
                subject: s,
                onEdit: () => _showSubjectDialog(context, app, s),
                onArchive: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Archive subject?'),
                      content: Text(
                          'Archive "${s.displayName}"? It will no longer appear in scheduling. You can view it in archived subjects.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel')),
                        FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Archive')),
                      ],
                    ),
                  );
                  if (confirm == true) app.archiveSubject(s.id);
                },
              )),
          if (archived.isNotEmpty) ...[
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text('Archived (${archived.length})',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                initiallyExpanded: false,
                children: archived
                    .map((s) => _SubjectCard(
                          subject: s,
                          isArchived: true,
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSubjectDialog(
      BuildContext context, dynamic app, SubjectModel? existing) {
    showDialog(
      context: context,
      builder: (ctx) => _SubjectDialog(existing: existing),
    );
  }
}

// ── Subject card ──────────────────────────────────────────────────────────────

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.subject,
    this.onEdit,
    this.onArchive,
    this.isArchived = false,
  });

  final SubjectModel subject;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;
  final bool isArchived;

  @override
  Widget build(BuildContext context) {
    return AutoCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              subject.code.length > 4
                  ? subject.code.substring(0, 4)
                  : subject.code,
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                  fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  '${subject.code} • ${subject.units} units • ${subject.difficulty.label}${subject.instructor != null ? ' • ${subject.instructor}' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          if (!isArchived) ...[
            IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_rounded, size: 20),
                onPressed: onEdit),
            IconButton(
                tooltip: 'Archive',
                icon: const Icon(Icons.archive_rounded, size: 20),
                onPressed: onArchive),
          ],
        ],
      ),
    );
  }
}

// ── Subject add/edit dialog ───────────────────────────────────────────────────

class _SubjectDialog extends StatefulWidget {
  const _SubjectDialog({this.existing});
  final SubjectModel? existing;

  @override
  State<_SubjectDialog> createState() => _SubjectDialogState();
}

class _SubjectDialogState extends State<_SubjectDialog> {
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _instructor;
  late int _units;
  late SubjectDifficulty _difficulty;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _code = TextEditingController(text: s?.code ?? '');
    _name = TextEditingController(text: s?.name ?? '');
    _instructor = TextEditingController(text: s?.instructor ?? '');
    _units = s?.units ?? 3;
    _difficulty = s?.difficulty ?? SubjectDifficulty.moderate;
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _instructor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Subject' : 'Add Subject'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _code,
              decoration: const InputDecoration(labelText: 'Subject code (e.g. BSIT 301)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Subject name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _instructor,
              decoration: const InputDecoration(labelText: 'Instructor (optional)'),
            ),
            const SizedBox(height: 10),
            Row(children: [
              const Text('Units: '),
              const Spacer(),
              DropdownButton<int>(
                value: _units,
                items: [1, 2, 3, 4, 5, 6]
                    .map((u) => DropdownMenuItem(value: u, child: Text('$u')))
                    .toList(),
                onChanged: (v) => setState(() => _units = v ?? _units),
              ),
            ]),
            const SizedBox(height: 10),
            DropdownButtonFormField<SubjectDifficulty>(
              value: _difficulty,
              decoration: const InputDecoration(labelText: 'Difficulty'),
              items: SubjectDifficulty.values
                  .map((d) => DropdownMenuItem(value: d, child: Text(d.label)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _difficulty = v ?? _difficulty),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_code.text.trim().isEmpty || _name.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code and name are required.')),
              );
              return;
            }
            final profile = app.profile;
            if (isEdit) {
              final updated = widget.existing!.copyWith(
                code: _code.text.trim(),
                name: _name.text.trim(),
                units: _units,
                difficulty: _difficulty,
                instructor: _instructor.text.trim().isEmpty
                    ? null
                    : _instructor.text.trim(),
              );
              app.updateSubject(updated);
            } else {
              final subject = SubjectModel(
                id: 'sub_${_code.text.trim().toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
                code: _code.text.trim(),
                name: _name.text.trim(),
                units: _units,
                difficulty: _difficulty,
                instructor: _instructor.text.trim().isEmpty
                    ? null
                    : _instructor.text.trim(),
                academicYear: profile.academicYear,
                term: profile.term,
              );
              app.addSubject(subject);
            }
            Navigator.of(context).pop();
          },
          child: Text(isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
