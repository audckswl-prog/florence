import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/user_book_model.dart'; // Fixed path
import '../../../core/constants/app_colors.dart'; // Fixed path
import '../../../core/utils/rich_text_utils.dart';
import '../providers/memo_providers.dart';
import '../../library/widgets/generic_book_cover.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MemoBookTile extends ConsumerWidget {
  final UserBook userBook;

  const MemoBookTile({super.key, required this.userBook});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memosAsync = ref.watch(memosProvider(userBook.isbn));

    return GestureDetector(
      onTap: () {
        context.push('/memo/list/${userBook.isbn}', extra: userBook.book);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(0),
        color: Colors.transparent, // Background for tap area
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Generic App-Style Book Cover
            GenericBookCover(
              book: userBook.book,
              width: 120, // Increased width
              height: 160, // Slight Increase height to match ratio
            ),
            const SizedBox(width: 20),

            // Right: Memo Preview
            Expanded(
              child: Container(
                height: 160, // Match cover height
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: memosAsync.when(
                  data: (memos) {
                    // ... (data prep)
                    // Sort descending by date (handling if not sorted)
                    // Assuming repo returns sorted.
                    final latestMemo = memos.isEmpty ? null : memos.first;
                    final hasImage = latestMemo?.imageUrl != null;
                    final memoCount = memos.length;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 1. Content Preview (Scrollable Cards)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: memos.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.edit_note,
                                          size: 28,
                                          color: AppColors.greyLight
                                              .withOpacity(0.5),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          '작성된 메모가 없습니다.\n당신의 생각을 남겨보세요.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: AppColors.grey,
                                            fontSize: 12,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: memos.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(
                                          width: 8,
                                        ), // Gap between cards
                                    itemBuilder: (context, index) {
                                      final memo = memos[index];
                                      final isImage = memo.imageUrl != null;

                                      return Container(
                                        width:
                                            100, // Fixed width for each memo card
                                        decoration: BoxDecoration(
                                          color: isImage
                                              ? Colors.grey[200]
                                              : AppColors
                                                    .ivory, // Slightly off-white for text cards
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.04,
                                              ), // Very soft shadow
                                              blurRadius: 4,
                                              offset: const Offset(2, 2),
                                            ),
                                          ],
                                          border: isImage
                                              ? null
                                              : Border.all(
                                                  color: Colors.black
                                                      .withOpacity(0.03),
                                                ),
                                        ),
                                        clipBehavior: Clip
                                            .antiAlias, // Clip image to rounded corners
                                        child: isImage
                                            ? CachedNetworkImage(
                                                imageUrl: memo.imageUrl!,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => Container(color: AppColors.ivory),
                                                errorWidget: (context, url, err) => const Center(
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        size: 20,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                              )
                                            : Stack(
                                                children: [
                                                  // Subtle quote icon background
                                                  Positioned(
                                                    top: -4,
                                                    left: -4,
                                                    child: Icon(
                                                      Icons
                                                          .format_quote_rounded,
                                                      size: 32,
                                                      color: AppColors.greyLight
                                                          .withOpacity(0.15),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          10.0,
                                                        ),
                                                    child: Text(
                                                      RichTextUtils.extractPlainText(
                                                        memo.content,
                                                      ),
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            AppColors.charcoal,
                                                        height: 1.5,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        fontFamily:
                                                            'Pretendard',
                                                      ),
                                                      maxLines:
                                                          5, // Allows slightly more text vertically
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      );
                                    },
                                  ),
                          ),
                        ),

                        // 2. Footer Actions (Write & Photo & View)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left Actions: Write & Photo
                            Row(
                              children: [
                                // Write Button
                                GestureDetector(
                                  onTap: () {
                                    context.push(
                                      '/memo/write/${userBook.isbn}',
                                      extra: userBook.book,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 4,
                                    ),
                                    color: Colors.transparent, // Hit test
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.edit_note,
                                          size: 16,
                                          color: AppColors.burgundy,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          '메모 쓰기',
                                          style: TextStyle(
                                            color: AppColors.burgundy,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Photo Button
                                GestureDetector(
                                  onTap: () {
                                    // Navigate to write screen (User can add photo there)
                                    context.push(
                                      '/memo/write/${userBook.isbn}',
                                      extra: userBook.book,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 4,
                                    ),
                                    color: Colors.transparent, // Hit test
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.camera_alt_outlined,
                                          size: 16,
                                          color: AppColors.burgundy,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          '사진 추가',
                                          style: TextStyle(
                                            color: AppColors.burgundy,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // View Detail
                            Row(
                              children: [
                                Text(
                                  '펼쳐보기',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: AppColors.grey,
                                        fontSize: 11,
                                      ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 14,
                                  color: AppColors.grey,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  loading: () => Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (_, __) => const Center(
                    child: Text('메모 로드 실패', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
