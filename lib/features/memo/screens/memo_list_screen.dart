import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../../core/widgets/florence_loader.dart';
import '../../../data/models/book_model.dart';
import '../../../core/utils/rich_text_utils.dart';
import '../providers/memo_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class MemoListScreen extends ConsumerWidget {
  final String isbn;
  final Book? book; // Passed via extra or fetched? For now let's pass it.

  const MemoListScreen({super.key, required this.isbn, this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memosAsync = ref.watch(memosProvider(isbn));

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          book?.title ?? '메모',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/memo/write/$isbn', extra: book);
        },
        backgroundColor: AppColors.burgundy,
        label: const Text('메모 작성'),
        icon: const Icon(Icons.edit),
      ),
      body: memosAsync.when(
        data: (memos) {
          if (memos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.note_alt_outlined,
                    size: 64,
                    color: AppColors.greyLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '작성된 메모가 없습니다.\n첫 번째 메모를 남겨보세요!',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: memos.length,
            itemBuilder: (context, index) {
              final memo = memos[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: NeumorphicContainer(
                  padding: const EdgeInsets.all(16),
                  depth: 2.0,
                  borderRadius: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (memo.imageUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: memo.imageUrl!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 200,
                              color: AppColors.ivory,
                              child: const Center(child: Icon(Icons.image, color: AppColors.greyLight)),
                            ),
                            errorWidget: (context, url, err) => Container(
                              height: 200,
                              color: AppColors.ivory,
                              child: const Center(child: Icon(Icons.broken_image, color: AppColors.grey)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        RichTextUtils.extractPlainText(memo.content),
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (memo.pageNumber != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.burgundy.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'p.${memo.pageNumber}',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppColors.burgundy,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            )
                          else
                            const SizedBox(),
                          Text(
                            DateFormat(
                              'yyyy.MM.dd HH:mm',
                            ).format(memo.createdAt),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppColors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: FlorenceLoader()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
