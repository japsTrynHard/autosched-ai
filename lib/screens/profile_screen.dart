import 'dart:convert';

import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../models/cloud_sync_model.dart';
import '../models/subject_model.dart';
import '../theme/app_theme.dart';
import '../utils/date_time_utils.dart';
import '../widgets/auto_card.dart';
import '../widgets/auto_top_bar.dart';
import '../widgets/info_chip.dart';
import '../widgets/section_header.dart';
import 'account_security_screen.dart';
import 'profile_editor_screen.dart';
import 'subscription_screen.dart';
import 'subject_manager_screen.dart';
import 'sync_center_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final profile = app.profile;
    final colors = Theme.of(context).colorScheme;
    final activeSubjects = app.activeSubjects;
    final activeClasses = app.activeClassSchedules;

    return Scaffold(
      appBar: const AutoTopBar(
        title: 'Profile & Setup',
        subtitle: 'Account, current term, preferences, and class history',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
        children: [
          AutoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ProfileAvatar(
                      path: profile.profileImagePath,
                      name: profile.fullName,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.fullName,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile.academicLabel,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile.course,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProfileEditorScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Edit Profile'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AccountSecurityScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.shield_rounded),
                        label: const Text('Security'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SectionHeader(
            title: 'Account Status',
            subtitle: app.userEmail == null
                ? 'Signed in securely.'
                : 'Signed in as ${app.userEmail}.',
          ),
          AutoCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.cloud_done_rounded,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.isFirebaseEnabled
                            ? 'Cloud backup ready'
                            : 'Local demo mode',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        app.isFirebaseEnabled
                            ? 'Your subjects, tasks, class schedules, and generated study blocks can be restored after login.'
                            : 'This build is running without online backup.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.outlined(
                  tooltip: 'Logout',
                  onPressed: () => app.signOut(),
                  icon: const Icon(Icons.logout_rounded),
                ),
              ],
            ),
          ),
          const SectionHeader(
            title: 'Subjects',
            subtitle: 'Manage your subjects for the current term.',
          ),
          AutoCard(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.book_rounded, color: Color(0xFF2563EB)),
              ),
              title: const Text('Subject Manager',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('Add, edit, or archive subjects'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SubjectManagerScreen()),
              ),
            ),
          ),
          const SectionHeader(
            title: 'Subscription',
            subtitle: 'Your current plan and upgrade options.',
          ),
          AutoCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.purple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppTheme.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Free Plan',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Upgrade to Pro for \u20B190/month and unlock AI, COR Scanner, cloud sync, and more.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.purple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionScreen(),
                    ),
                  ),
                  child: const Text(
                    'Upgrade',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader(
            title: 'Current School Term',
            subtitle:
                'The planner only uses subjects and classes that match your selected school year and term.',
          ),
          AutoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    InfoChip(
                      label: profile.yearLevel,
                      icon: Icons.layers_rounded,
                      color: AppTheme.primary,
                    ),
                    InfoChip(
                      label: profile.academicYear,
                      icon: Icons.calendar_month_rounded,
                      color: AppTheme.success,
                    ),
                    InfoChip(
                      label: profile.term,
                      icon: Icons.event_note_rounded,
                      color: AppTheme.purple,
                    ),
                    InfoChip(
                      label: '${activeSubjects.length} active subjects',
                      icon: Icons.menu_book_rounded,
                      color: AppTheme.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'When a new school year starts, update your year level and term in Edit Profile. Old subjects stay saved as history, while the planner focuses on the current term.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader(
            title: 'Appearance',
            subtitle: 'Choose Light, Dark, or follow your device setting.',
          ),
          AutoCard(
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_rounded),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_rounded),
                  label: Text('Dark'),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.settings_suggest_rounded),
                  label: Text('System'),
                ),
              ],
              selected: {app.themeMode},
              onSelectionChanged: (selected) =>
                  app.setThemeMode(selected.first),
            ),
          ),
          const SectionHeader(
            title: 'Backup Center',
            subtitle:
                'Save the latest schedule copy and preview what will be stored.',
          ),
          AutoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.cloud_sync_rounded,
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
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            app.syncStatus.message,
                            style: Theme.of(context).textTheme.bodySmall
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
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SyncCenterScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Open Backup Center'),
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader(
            title: 'Study Preferences',
            subtitle:
                'These settings control when AutoSched AI places study blocks.',
          ),
          AutoCard(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                InfoChip(
                  label: 'Preferred: ${profile.preferredStudyTime}',
                  icon: Icons.schedule_rounded,
                  color: AppTheme.primary,
                ),
                InfoChip(
                  label: 'Wake ${AutoDate.formatMinute(profile.wakeMinute)}',
                  icon: Icons.wb_sunny_rounded,
                  color: AppTheme.warning,
                ),
                InfoChip(
                  label:
                      'Sleep ${AutoDate.formatMinute(profile.sleepStartMinute)}',
                  icon: Icons.nightlight_round,
                  color: AppTheme.purple,
                ),
                InfoChip(
                  label: 'Max ${profile.maxStudyHoursPerDay}h study/day',
                  icon: Icons.timer_rounded,
                  color: AppTheme.success,
                ),
                InfoChip(
                  label: '${profile.breakMinutes}m break buffer',
                  icon: Icons.coffee_rounded,
                  color: AppTheme.warning,
                ),
              ],
            ),
          ),
          SectionHeader(
            title: 'Active Subjects',
            subtitle: activeSubjects.isEmpty
                ? 'No subjects for this term yet. Scan or paste your COR to import classes.'
                : 'Subjects currently used by the planner.',
          ),
          if (activeSubjects.isEmpty)
            const AutoCard(
              child: Text(
                'Scan your COR or update your current term to show active subjects here.',
              ),
            )
          else
            ...activeSubjects.map((subject) => _SubjectCard(subject: subject)),
          const SectionHeader(
            title: 'Current Class Schedule',
            subtitle: 'Fixed blocks that the planner cannot overlap.',
          ),
          if (activeClasses.isEmpty)
            const AutoCard(
              child: Text(
                'No active class schedule yet. Import your COR first.',
              ),
            )
          else
            ...activeClasses.map((schedule) {
              final subject = app.subjectById(schedule.subjectId);
              return AutoCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AutoDate.weekdayLong(schedule.weekday)} • ${AutoDate.formatTimeRange(schedule.startMinute, schedule.endMinute)}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${subject?.displayName ?? 'Subject'} • ${schedule.room}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const InfoChip(
                      label: 'Fixed',
                      icon: Icons.lock_rounded,
                      color: AppTheme.primary,
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => app.regenerateSchedule(),
            icon: const Icon(Icons.auto_fix_high_rounded),
            label: const Text('Regenerate Smart Plan'),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.path, required this.name});

  final String? path;
  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget child;
    if (path != null && path!.startsWith('http')) {
      child = ClipOval(
        child: Image.network(
          path!,
          width: 66,
          height: 66,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _InitialAvatar(name: name),
        ),
      );
    } else if (path != null && path!.startsWith('data:image')) {
      final bytes = base64Decode(path!.split(',').last);
      child = ClipOval(
        child: Image.memory(bytes, width: 66, height: 66, fit: BoxFit.cover),
      );
    } else {
      child = _InitialAvatar(name: name);
    }
    return CircleAvatar(
      radius: 34,
      backgroundColor: colors.primary.withOpacity(0.12),
      child: child,
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Text(
      name.trim().isEmpty ? 'A' : name.trim().substring(0, 1).toUpperCase(),
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        color: colors.primary,
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject});

  final SubjectModel subject;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AutoCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.book_rounded, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${subject.units} units • ${subject.instructor ?? 'No instructor'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          InfoChip(label: subject.difficulty.label, color: AppTheme.purple),
        ],
      ),
    );
  }
}
