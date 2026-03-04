import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../../core/widgets/neumorphic_button.dart';

class TicketQuoteInputDialog extends StatefulWidget {
  const TicketQuoteInputDialog({super.key});

  @override
  State<TicketQuoteInputDialog> createState() => _TicketQuoteInputDialogState();
}

class _TicketQuoteInputDialogState extends State<TicketQuoteInputDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      Navigator.of(context).pop(text);
    } else {
      Navigator.of(context).pop('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.ivory,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '티켓 메모 작성',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: AppColors.burgundy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '이 책에서 가장 인상 깊었던\n하나의 문장을 적어주세요.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.charcoal,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            NeumorphicContainer(
              depth: -3,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              borderRadius: 12,
              child: TextField(
                controller: _controller,
                maxLines: 4,
                maxLength: 150,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '여기에 문장을 입력하세요...',
                  hintStyle: TextStyle(color: AppColors.greyLight),
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(height: 24),
            NeumorphicButton(
              onPressed: _submit,
              color: AppColors.burgundy,
              padding: const EdgeInsets.symmetric(vertical: 16),
              borderRadius: 12,
              child: const Text(
                '티켓 발급하기',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소', style: TextStyle(color: AppColors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}
