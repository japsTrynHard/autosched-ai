import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../app/app_scope.dart';
import '../config/ai_config.dart';
import '../services/ai_assistant_mock.dart';
import '../services/groq_ai_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auto_card.dart';
import '../widgets/auto_top_bar.dart';
import '../widgets/section_header.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _localAssistant = AiAssistantMock();
  final _groqAssistant = const GroqAiService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      isUser: false,
      text:
          'Hi. I can help you decide what to study first, explain your schedule, check deadlines, and guide you when a new term starts.',
    ),
  ];
  bool _isThinking = false;
  bool _useOnlineAi = AiConfig.hasGroqKey;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const AutoTopBar(
        title: 'AI Assistant',
        subtitle: 'Smart planner help for demo and defense',
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
            child: Column(
              children: [
                SectionHeader(
                  title: 'Smart Assistant',
                  subtitle: _useOnlineAi
                      ? 'Online AI is active. It uses your current planner context and falls back safely if needed.'
                      : 'Local demo assistant is active. Add a Groq key when you want real AI responses.',
                ),
                AutoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  (_useOnlineAi
                                          ? AppTheme.success
                                          : AppTheme.warning)
                                      .withAlpha((0.12 * 255).round()),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _useOnlineAi
                                  ? Icons.online_prediction_rounded
                                  : Icons.smart_toy_rounded,
                              color: _useOnlineAi
                                  ? AppTheme.success
                                  : AppTheme.warning,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _useOnlineAi
                                      ? 'Online AI Mode'
                                      : 'Local Smart Mode',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _useOnlineAi
                                      ? 'Uses an online AI assistant for more natural answers during presentation.'
                                      : 'Works offline using built-in schedule rules.',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _useOnlineAi,
                            onChanged: AiConfig.hasGroqKey && !_isThinking
                                ? (value) =>
                                      setState(() => _useOnlineAi = value)
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 46,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _PromptChip(
                                label: 'What should I study first?',
                                onTap: () => _sendPreset(
                                  'What should I study first?',
                                  app,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _PromptChip(
                                label: 'Explain my schedule',
                                onTap: () =>
                                    _sendPreset('Explain my schedule', app),
                              ),
                              const SizedBox(width: 8),
                              _PromptChip(
                                label: 'Make it lighter',
                                onTap: () =>
                                    _sendPreset('Make it lighter tonight', app),
                              ),
                              const SizedBox(width: 8),
                              _PromptChip(
                                label: 'Show deadlines',
                                onTap: () => _sendPreset('Show deadlines', app),
                              ),
                              const SizedBox(width: 8),
                              _PromptChip(
                                label: 'New term help',
                                onTap: () => _sendPreset(
                                  'How do I start a new term?',
                                  app,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _PromptChip(
                                label: 'Secure account',
                                onTap: () => _sendPreset(
                                  'How do I secure my account?',
                                  app,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
              itemCount: _messages.length + (_isThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isThinking && index == _messages.length) {
                  return const _ThinkingBubble();
                }
                final message = _messages[index];
                return Align(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.84,
                    ),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? AppTheme.primary
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: message.isUser
                            ? AppTheme.primary
                            : Theme.of(context).colorScheme.outlineVariant
                                  .withAlpha((0.65 * 255).round()),
                      ),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        height: 1.35,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        hintText: 'Ask AutoSched AI...',
                        prefixIcon: Icon(Icons.auto_awesome_rounded),
                      ),
                      onSubmitted: (_) => _send(app),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: _isThinking ? null : () => _send(app),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendPreset(String text, AppController app) {
    _controller.text = text;
    _send(app);
  }

  Future<void> _send(AppController app) async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isThinking) return;

    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: text));
      _controller.clear();
      _isThinking = true;
    });
    _scrollToBottom();

    var usedFallback = false;
    String reply;
    if (_useOnlineAi && AiConfig.hasGroqKey) {
      try {
        reply = await _groqAssistant.reply(text, app);
      } catch (_) {
        usedFallback = true;
        reply = _localAssistant.reply(text, app);
      }
    } else {
      reply = _localAssistant.reply(text, app);
    }

    if (!mounted) return;
    setState(() {
      _isThinking = false;
      _messages.add(
        _ChatMessage(
          isUser: false,
          text: usedFallback
              ? '$reply\n\nNote: Online AI was unavailable, so I used the built-in planner assistant.'
              : reply,
        ),
      );
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primary.withAlpha((0.08 * 255).round()),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 15,
              color: AppTheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withAlpha((0.65 * 255).round()),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Thinking...'),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.isUser, required this.text});

  final bool isUser;
  final String text;
}
