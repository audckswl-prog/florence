import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../../core/widgets/florence_loader.dart';
import '../../../data/models/book_model.dart';
import '../../../core/utils/rich_text_utils.dart';
import '../providers/memo_providers.dart';
import '../../library/providers/book_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/image_zoom_viewer.dart';

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
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ImageZoomViewer(
                                  imageUrl: memo.imageUrl!,
                                  heroTag: 'memo_full_${memo.id}',
                                ),
                              ),
                            );
                          },
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 400),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                color: AppColors.ivory, // Darker backdrop for odd aspect ratios
                                width: double.infinity,
                                child: Hero(
                                  tag: 'memo_full_${memo.id}',
                                  child: CachedNetworkImage(
                                    imageUrl: memo.imageUrl!,
                                    fit: BoxFit.contain, // Maintain Aspect Ratio
                                    placeholder: (context, url) => const SizedBox(
                                      height: 200,
                                      child: Center(child: Icon(Icons.image, color: AppColors.greyLight)),
                                    ),
                                    errorWidget: (context, url, err) => const SizedBox(
                                      height: 200,
                                      child: Center(child: Icon(Icons.broken_image, color: AppColors.grey)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        RichTextUtils.extractPlainTextWithoutDate(memo.content),
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (memo.pageNumber != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Container(
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
                                  ),
                                ),
                              Text(
                                DateFormat(
                                  'yyyy.MM.dd HH:mm',
                                ).format(memo.createdAt),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: AppColors.grey),
                              ),
                            ],
                          ),
                          // Context Menu for Edit & Delete
                          if (memo.userId == Supabase.instance.client.auth.currentUser?.id)
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_horiz, color: AppColors.grey),
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  if (memo.imageUrl != null) {
                                    context.push('/memo/add-photo/$isbn', extra: {'book': book, 'memo': memo});
                                  } else {
                                    context.push('/memo/write/$isbn', extra: {'book': book, 'memo': memo});
                                  }
                                } else if (value == 'delete') {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('삭제 확인'),
                                      content: const Text('이 메모를 정말 삭제하시겠습니까?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('취소', style: TextStyle(color: AppColors.grey)),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('삭제', style: TextStyle(color: AppColors.burgundy, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    try {
                                      await ref.read(supabaseRepositoryProvider).deleteMemo(memo.id);
                                      ref.invalidate(memosProvider(isbn));
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('메모가 삭제되었습니다.')),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('삭제 실패: $e')),
                                        );
                                      }
                                    }
                                  }
                                }
                              },
                              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Text('수정'),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Text('삭제', style: TextStyle(color: AppColors.burgundy)),
                                ),
                              ],
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
