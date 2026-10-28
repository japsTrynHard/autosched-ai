import '../app/app_controller.dart';
import '../utils/date_time_utils.dart';

class AiAssistantMock {
  String reply(String message, AppController app) {
    final lower = message.toLowerCase().trim();

    if (lower.contains('study first') || lower.contains('priority') || lower.contains('what should')) {
      final task = app.topPriorityTask();
      if (task == null) return 'You have no pending task right now. Keep your free time protected or do a light review.';
      final subject = app.subjectById(task.subjectId);
      return 'Study ${subject?.code ?? 'your top subject'} first: "${task.title}". It is the best first task because it has the highest priority after checking deadline, difficulty, workload, and missed-task history.';
    }

    if (lower.contains('lighter') || lower.contains('light') || lower.contains('burnout') || lower.contains('tired')) {
      final protectedMinutes = app.protectedFreeMinutesForDate(app.selectedDate);
      return '${app.burnoutStatusForDate(app.selectedDate)} I recommend keeping at least ${protectedMinutes ~/ 60}h ${protectedMinutes % 60}m of free time today. Complete low-effort tasks first and avoid adding another hard subject tonight.';
    }

    if (lower.contains('deadline') || lower.contains('due')) {
      final pending = app.pendingTasks.take(4).toList();
      if (pending.isEmpty) return 'No upcoming deadline found. Your planner looks clear for now.';
      return pending
          .map((task) => '• ${task.title}: due ${AutoDate.formatDate(task.deadline)} · priority ${task.priorityScore}')
          .join('\n');
    }

    if (lower.contains('term') || lower.contains('school year') || lower.contains('year level')) {
      return 'You are currently set to ${app.profile.academicLabel}. If a new school year starts, go to Profile > Edit Profile and update the year level, school year, and term. AutoSched AI will keep old subjects as history and use only the current term for planning.';
    }

    if (lower.contains('cor') || lower.contains('scan') || lower.contains('schedule import')) {
      return 'For your COR, scan or upload a clear image, review every detected class, then import it. Imported classes become fixed blocks, so study sessions will not overlap with class time.';
    }

    if (lower.contains('secure') || lower.contains('password') || lower.contains('email')) {
      return 'Open Profile > Security. You can send a verification link, change your password by email link, or request an email-change confirmation link.';
    }

    if (lower.contains('why') || lower.contains('explain')) {
      final block = app.nextStudyBlockForDate(app.selectedDate);
      if (block == null) return 'There is no generated study block for the selected day. Your free time is currently protected.';
      return 'The next study block starts at ${AutoDate.formatMinute(block.startMinute)}. It was placed there because it avoids fixed classes, respects sleep time, checks the task priority, and leaves recovery time when possible.';
    }

    if (lower.contains('replan') || lower.contains('regenerate') || lower.contains('refresh plan')) {
      app.regenerateSchedule();
      return 'Done. I recalculated priorities, scanned free time, avoided class conflicts, protected breaks, and regenerated the weekly plan.';
    }

    return 'I can help with your planner using the data already inside the app. Try: "What should I study first?", "Explain my schedule", "Make it lighter", "Show deadlines", "How do I start a new term?", or "How do I secure my account?"';
  }
}
