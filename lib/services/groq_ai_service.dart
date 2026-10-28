import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app/app_controller.dart';
import '../config/ai_config.dart';
import '../models/task_model.dart';
import '../utils/date_time_utils.dart';

class GroqAiService {
  const GroqAiService();

  bool get isConfigured => AiConfig.hasGroqKey;

  Future<String> reply(String message, AppController app) async {
    if (!isConfigured) {
      throw const GroqAiException('Groq key is not configured.');
    }

    final response = await http
        .post(
          Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${AiConfig.groqApiKey}',
          },
          body: jsonEncode({
            'model': AiConfig.groqModel,
            'temperature': 0.35,
            'max_completion_tokens': 420,
            'messages': [
              {'role': 'system', 'content': _systemPrompt},
              {
                'role': 'user',
                'content':
                    'Current planner context:\n${_plannerContext(app)}\n\nStudent message: $message',
              },
            ],
          }),
        )
        .timeout(const Duration(seconds: 18));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GroqAiException('AI request failed (${response.statusCode}).');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map<String, dynamic>) {
        final messageData = first['message'];
        if (messageData is Map<String, dynamic>) {
          final content = messageData['content'];
          if (content is String && content.trim().isNotEmpty) {
            return content.trim();
          }
        }
      }
    }

    throw const GroqAiException('AI returned an empty response.');
  }
}

class GroqAiException implements Exception {
  const GroqAiException(this.message);
  final String message;

  @override
  String toString() => message;
}

const _systemPrompt = '''
You are AutoSched AI, a friendly academic scheduling assistant for students.
Answer clearly, briefly, and practically. Avoid developer terms such as Firebase, Firestore, API, database schema, or backend unless the user directly asks about setup.
Use the student's current schedule context. Recommend what to study first, explain scheduling decisions, protect rest time, and guide COR import or new term setup.
Keep answers under 130 words unless the user asks for details.
''';

String _plannerContext(AppController app) {
  final buffer = StringBuffer();
  buffer.writeln('Student: ${app.profile.fullName}');
  buffer.writeln('Academic period: ${app.profile.academicLabel}');
  buffer.writeln('Preferred study time: ${app.profile.preferredStudyTime}');
  buffer.writeln(
    'Max study time per day: ${app.profile.maxStudyHoursPerDay} hours',
  );
  buffer.writeln(
    'Sleep starts: ${AutoDate.formatMinute(app.profile.sleepStartMinute)}',
  );
  buffer.writeln(
    'Active subjects: ${app.activeSubjects.map((s) => '${s.code} ${s.name}').join('; ')}',
  );
  buffer.writeln('Pending tasks:');
  for (final task in app.pendingTasks.take(6)) {
    final subject = app.subjectById(task.subjectId);
    buffer.writeln(
      '- ${task.title} (${subject?.code ?? 'No subject'}), due ${AutoDate.formatDate(task.deadline)}, priority ${task.priorityScore}, status ${task.status.label}',
    );
  }
  buffer.writeln('Selected day: ${AutoDate.formatDate(app.selectedDate)}');
  buffer.writeln('Classes that day:');
  for (final item in app.classesForDate(app.selectedDate)) {
    final subject = app.subjectById(item.subjectId);
    buffer.writeln(
      '- ${subject?.code ?? 'Class'} ${AutoDate.formatMinute(item.startMinute)}-${AutoDate.formatMinute(item.endMinute)} room ${item.room}',
    );
  }
  buffer.writeln('Study blocks that day:');
  for (final block in app.blocksForDate(app.selectedDate)) {
    final task = app.taskById(block.taskId);
    buffer.writeln(
      '- ${task?.title ?? block.blockType} ${AutoDate.formatMinute(block.startMinute)}-${AutoDate.formatMinute(block.endMinute)}',
    );
  }
  buffer.writeln(
    'Burnout status: ${app.burnoutStatusForDate(app.selectedDate)}',
  );
  return buffer.toString();
}
