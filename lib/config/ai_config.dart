/// Demo AI configuration.
///
/// Preferred setup:
/// flutter run --dart-define=GROQ_API_KEY=your_real_key_here
///
/// This keeps the key out of the source files. For a public release, move the
/// Groq call to a backend so the key is never inside the app build.
class AiConfig {
  static const String _envGroqApiKey = String.fromEnvironment('GROQ_API_KEY');
  static const String groqModel = String.fromEnvironment(
    'GROQ_MODEL',
    defaultValue: 'llama-3.1-8b-instant',
  );

  static const String groqVisionModel = String.fromEnvironment(
    'GROQ_VISION_MODEL',
    defaultValue: 'meta-llama/llama-4-scout-17b-16e-instruct',
  );

  static String get groqApiKey {
    final key = _envGroqApiKey.trim();
    if (key.isEmpty) return '';
    final lower = key.toLowerCase();
    if (lower.startsWith('your_') ||
        lower.contains('replace_me') ||
        lower.contains('example') ||
        lower == 'null' ||
        lower == 'undefined') {
      return '';
    }
    return key;
  }

  static bool get hasGroqKey => groqApiKey.trim().isNotEmpty;
}
