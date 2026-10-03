import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/ai_bloc.dart';
import '../widgets/ai_widgets.dart';
import '../../domain/entities/ai_entities.dart';

part '../widgets/ai_assistant/quick_symptoms.dart';
part '../widgets/ai_assistant/input_bar.dart';

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _inputCtrl.addListener(() {
      setState(() => _canSend = _inputCtrl.text.trim().isNotEmpty);
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    setState(() => _canSend = false);
    context.read<AiBloc>().add(AiMessageSent(text));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.medical_information_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Health Assistant', style: AppTextStyles.titleMedium),
                Text(
                  'Preliminary guidance only',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Clear chat',
            onPressed: () => _confirmClear(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Disclaimer banner ──────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.warningSurface,
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_outlined,
                  color: AppColors.warning,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'For guidance only. Not a substitute for professional medical advice.',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Messages ──────────────────────────
          Expanded(
            child: BlocConsumer<AiBloc, AiState>(
              listener: (context, state) {
                if (state is AiError) {
                  // 💡 السطر ده هيظهرلك الإيرور اللي بيحصل ورا الكواليس
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
                if (state is AiLoaded || state is AiError) {
                  _scrollToBottom();
                }
              },
              builder: (context, state) {
                final messages = state is AiLoaded
                    ? state.messages
                    : state is AiError
                    ? state.messages
                    : <ChatMessage>[];
                final isTyping = state is AiLoaded ? state.isTyping : false;

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  itemCount: messages.length + (isTyping ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == messages.length && isTyping) {
                      return const AiTypingIndicator();
                    }
                    return ChatBubble(message: messages[i]);
                  },
                );
              },
            ),
          ),

          // ── Quick symptom chips ────────────────
          BlocBuilder<AiBloc, AiState>(
            builder: (context, state) {
              final isTyping = state is AiLoaded && state.isTyping;
              if (isTyping) return const SizedBox.shrink();
              return _QuickSymptoms(
                onSelect: (s) {
                  _inputCtrl.text = s;
                  setState(() => _canSend = true);
                },
              );
            },
          ),

          // ── Input bar ─────────────────────────
          _InputBar(
            controller: _inputCtrl,
            canSend: _canSend,
            onSend: _send,
            isLoading:
                context.watch<AiBloc>().state is AiLoaded &&
                (context.watch<AiBloc>().state as AiLoaded).isTyping,
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Start a new conversation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AiBloc>().add(AiChatCleared());
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Quick Symptoms
// ─────────────────────────────────────────────
