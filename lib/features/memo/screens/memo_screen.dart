import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
// import '../../../core/widgets/neumorphic_container.dart';
import '../../library/providers/library_providers.dart';
import '../widgets/memo_book_tile.dart';

class MemoScreen extends ConsumerWidget {
  const MemoScreen({super.key}); // Screen for memo list

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(userBooksProvider);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        elevation: 0,
        toolbarHeight: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.only(top: 10, bottom: 20, left: 24, right: 24),
            child: Text(
              '이 곳에서 메모를 작성하고\n그동안 메모한 것들을 확인하실 수 있습니다.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.burgundy.withOpacity(0.8),
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ),
      ),
      body: booksAsync.when(
        data: (userBooks) {
          // Filter out 'wish' books, as memos are usually for read/reading books
          final memoBooks = userBooks
              .where((b) => b.status == 'reading' || b.status == 'read')
              .toList();

          if (memoBooks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.edit_note, size: 64, color: AppColors.greyLight),
                  const SizedBox(height: 16),
                  Text(
                    '메모를 남길 책이 없습니다.\n서재에서 읽고 있는 책이나 읽은 책을 추가해보세요.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.grey,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: memoBooks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 0), // Tile has bottom margin
            itemBuilder: (context, index) {
              final userBook = memoBooks[index];
              return MemoBookTile(userBook: userBook);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
