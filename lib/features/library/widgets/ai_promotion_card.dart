import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/florence_loader.dart';
import '../../../../data/models/book_model.dart';
import '../providers/ai_promotion_provider.dart';

class AIPromotionCard extends ConsumerWidget {
  final Book book;

  const AIPromotionCard({super.key, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Record(params) 대신 Book 객체 원본을 그대로 넘겨 Riverpod 해싱 에러 해결
    final promotionAsyncValues = ref.watch(aiPromotionFutureProvider(book));

    Widget buildCardContent(Widget child) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.ivory,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.burgundy.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );
    }

    return promotionAsyncValues.when(
      data: (promotion) {
        if (promotion == null) return const SizedBox.shrink();

        return buildCardContent(
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Badge
                Row(
                  children: [
                    const FlorenceLoader(
                      width: 18,
                      height: 18,
                      color: AppColors.burgundy,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '피렌체 도슨트의 노트',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.burgundy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Hook Title
                Text(
                  promotion.hookTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.charcoal,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),

                // Historical Background
                Text(
                  promotion.historicalBackground,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.charcoal.withValues(alpha: 0.9),
                    height: 1.8,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Closing Question (Styled as a quote block)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.burgundy.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                      left: BorderSide(color: AppColors.burgundy, width: 4),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.format_quote,
                        color: AppColors.burgundy,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          promotion.closingQuestion,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.charcoal,
                                fontWeight: FontWeight.w600,
                                height: 1.6,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => buildCardContent(
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              const FlorenceLoader(
                width: 48,
                height: 48,
                color: AppColors.burgundy,
              ),
              const SizedBox(height: 16),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '도슨트가 당신에게 알맞은 이야기를 고르고 있습니다...',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.charcoal),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '약 10초 정도 소요됩니다.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      error: (error, stack) {
        debugPrint('AIPromotion UI Error: $error');
        return buildCardContent(
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'AI 프로모션을 불러올 수 없습니다.\nError: $error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        );
      },
    );
  }
}
