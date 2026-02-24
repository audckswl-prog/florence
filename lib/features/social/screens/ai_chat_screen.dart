import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../../data/models/project_model.dart';
import '../../library/providers/book_providers.dart';
import '../providers/social_providers.dart';
// Note: Assuming a gemini_service or direct api call here for real implementation.
// For now, mocking the response.

class AiChatScreen extends ConsumerStatefulWidget {
  final Project project;

  const AiChatScreen({super.key, required this.project});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<Map<String, String>> _messages = [
    {
      'role': 'ai',
      'text': '안녕하세요! ${'이 책'}에 대해 어떤 점이 궁금하신가요? 발제문이 필요하시다면 말씀해주세요.',
    }
  ];
  
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _msgController.clear();
    _scrollToBottom();

    try {
      // 1. Send to Gemini (Mocked for now)
      await Future.delayed(const Duration(seconds: 2));
      final aiResponse = "좋은 질문이네요! 그 부분에 대해서는 이렇게 생각해 볼 수 있습니다... (AI 답변 시뮬레이션)";

      // 2. Save QnA Log to Supabase using Provider
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await ref.read(supabaseRepositoryProvider).saveAiQnaLog(
          widget.project.id, 
          userId, 
          text, 
          aiResponse
        );
        // Refresh project members to update the question count UI
        ref.invalidate(projectMembersProvider(widget.project.id));
      }

      setState(() {
        _messages.add({'role': 'ai', 'text': aiResponse});
        _isLoading = false;
      });
      _scrollToBottom();
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({'role': 'ai', 'text': '죄송합니다. 오류가 발생했습니다: $e'});
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.burgundy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI 도슨트',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              widget.project.name,
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return _buildChatBubble(msg['text']!, isUser);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('AI가 답변을 작성하고 있습니다...', style: TextStyle(color: AppColors.greyLight, fontSize: 12)),
              ),
            ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.burgundy : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [
            if (!isUser)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
          ]
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : AppColors.black,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ]
      ),
      child: Row(
        children: [
          Expanded(
            child: NeumorphicContainer(
              depth: -2.0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              borderRadius: 24,
              child: TextField(
                controller: _msgController,
                decoration: const InputDecoration(
                  hintText: '질문을 입력하세요...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.greyLight),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isLoading ? null : _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isLoading ? AppColors.greyLight : AppColors.burgundy,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
