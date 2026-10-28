import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/ai_config.dart';
import '../models/cor_extraction_model.dart';
import 'cor_text_parser.dart';

class CorAiExtractorService {
  const CorAiExtractorService();

  bool get isConfigured => AiConfig.hasGroqKey;

  Future<List<ExtractedClassEntry>> extractFromText(String rawText) async {
    if (!isConfigured) return const [];
    final content = await _chatCompletion(
      model: AiConfig.groqModel,
      messages: [
        {'role': 'system', 'content': _systemPrompt},
        {
          'role': 'user',
          'content': 'Extract the class schedule from this COR text. Return JSON only.\n\n$rawText',
        },
      ],
    );
    return CorTextParser.parseAiJson(content);
  }

  Future<List<ExtractedClassEntry>> extractFromImagePath(
    String imagePath, {
    String recognizedText = '',
  }) async {
    if (!isConfigured) return const [];

    final file = File(imagePath);
    if (!await file.exists()) return const [];

    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);
    final mimeType = _mimeTypeForPath(imagePath);

    final prompt = StringBuffer()
      ..writeln('Read this Certificate of Registration image and extract only the class schedule table.')
      ..writeln('Return JSON only with this exact schema:')
      ..writeln('{"classes":[{"subjectCode":"CTAINASL","subjectName":"ADVANCED INFORMATION ASSURANCE AND SECURITY","day":"TH","startTime":"05:00PM","endTime":"09:00PM","room":"304","units":3}]}')
      ..writeln('Rules:')
      ..writeln('- Create one class object for every day/time/room meeting.')
      ..writeln('- If a row has MTH, create one object for M and one for TH.')
      ..writeln('- Ignore tuition, fees, installment, notes, and student profile fields.')
      ..writeln('- Do not guess if a field is unreadable. Use TBA only for unreadable room.')
      ..writeln('- JSON only. No markdown.');

    if (recognizedText.trim().isNotEmpty) {
      prompt
        ..writeln('\nThe app also detected this OCR text. Use it as supporting context, but verify against the image:')
        ..writeln(recognizedText.trim());
    }

    final content = await _chatCompletion(
      model: AiConfig.groqVisionModel,
      messages: [
        {'role': 'system', 'content': _systemPrompt},
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': prompt.toString()},
            {
              'type': 'image_url',
              'image_url': {'url': 'data:$mimeType;base64,$base64Image'},
            },
          ],
        },
      ],
    );

    return CorTextParser.parseAiJson(content);
  }

  Future<String> _chatCompletion({
    required String model,
    required List<Map<String, dynamic>> messages,
  }) async {
    final response = await http
        .post(
          Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${AiConfig.groqApiKey}',
          },
          body: jsonEncode({
            'model': model,
            'temperature': 0.1,
            'max_completion_tokens': 1800,
            'messages': messages,
          }),
        )
        .timeout(const Duration(seconds: 28));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CorAiExtractorException('Groq extraction failed (${response.statusCode}).');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map<String, dynamic>) {
        final message = first['message'];
        if (message is Map<String, dynamic>) {
          final content = message['content'];
          if (content is String && content.trim().isNotEmpty) {
            return content.trim();
          }
        }
      }
    }

    throw const CorAiExtractorException('Groq returned an empty extraction.');
  }

  String _mimeTypeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}

class CorAiExtractorException implements Exception {
  const CorAiExtractorException(this.message);
  final String message;

  @override
  String toString() => message;
}

const _systemPrompt = '''
You are AutoSched AI's COR extraction engine. Extract class schedule data with high precision.
Return valid JSON only. Never include explanations, markdown, or fields outside the requested schema.
Do not include fees, payment schedules, notes, registrar text, or student profile rows.
''';
