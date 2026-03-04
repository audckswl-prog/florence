import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/neumorphic_button.dart';
import '../../../data/models/user_book_model.dart';
import 'ticket_quote_input_dialog.dart';

class ReadingCompletionDialog extends StatelessWidget {
  final UserBook userBook;
  final bool isSharedReading;

  const ReadingCompletionDialog({
    super.key,
    required this.userBook,
    this.isSharedReading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(28),
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
            const Icon(
              Icons.stars_rounded,
              color: AppColors.burgundy,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              '책 기록이 완료되었습니다.',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: AppColors.burgundy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '${userBook.book.title}\n다 읽으신 것을 축하합니다!',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.charcoal,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 32),
            NeumorphicButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                final quote = await showDialog<String>(
                  context: context,
                  builder: (context) => const TicketQuoteInputDialog(),
                );

                if (quote != null) {
                  // Pop this dialog and pass back the result to trigger ticket screen
                  nav.pop(quote);
                }
              },
              color: AppColors.ivory,
              padding: const EdgeInsets.symmetric(vertical: 16),
              borderRadius: 12,
              child: const Text(
                '독서 티켓 발급하기',
                style: TextStyle(
                  color: AppColors.burgundy,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (!isSharedReading) ...[
              const SizedBox(height: 12),
              NeumorphicButton(
                onPressed: () => Navigator.of(context).pop(),
                color: AppColors.burgundy,
                padding: const EdgeInsets.symmetric(vertical: 16),
                borderRadius: 12,
                child: const Text(
                  '닫기',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
