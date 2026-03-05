import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/neumorphic_container.dart';
import '../../../core/widgets/neumorphic_button.dart';
import '../../../core/widgets/florence_loader.dart';
import '../../../core/utils/florence_toast.dart';
import '../../../data/models/user_book_model.dart';
import '../providers/library_providers.dart';
import '../providers/book_providers.dart';
import '../widgets/reading_record_dialog.dart';
import '../widgets/reading_completion_dialog.dart';
import '../screens/reading_ticket_screen.dart';
import '../screens/book_search_delegate.dart';

class ReadingListScreen extends ConsumerWidget {
  const ReadingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(readingListProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.ivory,
        appBar: AppBar(
          backgroundColor: AppColors.ivory,
          elevation: 0,
          toolbarHeight:
              0, // Hide default title area to only show custom bottom
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(120), // Height for text + tabs
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(
                    top: 10,
                    bottom: 20,
                    left: 24,
                    right: 24,
                  ),
                  child: Text(
                    '이 곳에서 읽고 싶은 책과 읽는 중인 책을\n관리하실 수 있습니다.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.burgundy.withOpacity(0.8),
                      fontSize: 13,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const TabBar(
                  indicatorColor: AppColors.burgundy,
                  labelColor: AppColors.burgundy,
                  unselectedLabelColor: AppColors.grey,
                  tabs: [
                    Tab(text: '읽는 중'),
                    Tab(text: '읽고 싶은'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: booksAsync.when(
          data: (books) {
            final readingBooks = books
                .where((b) => b.status == 'reading')
                .toList();
            final wishBooks = books.where((b) => b.status == 'wish').toList();

            return TabBarView(
              children: [
                _BookList(
                  books: readingBooks,
                  emptyMessage: '읽고 있는 책이 없습니다.',
                  type: 'reading',
                ),
                _BookList(
                  books: wishBooks,
                  emptyMessage: '찜한 책이 없습니다.',
                  type: 'wish',
                ),
              ],
            );
          },
          loading: () => const Center(child: FlorenceLoader()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showSearch(context: context, delegate: BookSearchDelegate(ref));
          },
          backgroundColor: AppColors.burgundy,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _BookList extends ConsumerWidget {
  final List<UserBook> books;
  final String emptyMessage;
  final String type;

  const _BookList({
    required this.books,
    required this.emptyMessage,
    required this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (books.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(color: AppColors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: () {
              // Open detail modal or screen
              // For now, let's navigate to memo list if reading, or detail if wish?
              // Or just show detail modal.
              // We need to implement detail modal opening.
              // For now, just a placeholder onTap.
            },
            child: NeumorphicContainer(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Cover Image
                  Container(
                    width: 60,
                    height: 90,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Image.network(
                      book.book.highResCoverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: Colors.grey[300]),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.book.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book.book.author,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (type == 'reading' && book.startedAt != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            '시작일: ${_formatDate(book.startedAt!)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.burgundy,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (type == 'wish')
                    IconButton(
                      icon: const Icon(
                        Icons.import_contacts_rounded,
                        color: AppColors.burgundy,
                        size: 28,
                      ),
                      tooltip: '읽기 시작',
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => Dialog(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            insetPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                            ),
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
                                    '읽기 시작',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                      color: AppColors.burgundy,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    '이 책을 "읽는 중" 서재로 이동하여\n독서를 시작하시겠습니까?',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 32),
                                  NeumorphicButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    color: AppColors.burgundy,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    borderRadius: 12,
                                    child: const Text(
                                      '시작하기',
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
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text(
                                      '취소',
                                      style: TextStyle(color: AppColors.grey),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );

                        if (confirmed == true) {
                          final userId =
                              Supabase.instance.client.auth.currentUser?.id;
                          if (userId != null) {
                            await ref
                                .read(supabaseRepositoryProvider)
                                .updateUserBookStatus(
                                  userId,
                                  book.isbn,
                                  'reading',
                                );
                            ref.invalidate(
                              userBooksProvider,
                            ); // Fix: refresh root provider
                            if (context.mounted) {
                              FlorenceToast.show(
                                context,
                                '읽는 중인 책 목록으로 이동되었습니다.',
                              );
                            }
                          }
                        }
                      },
                    ),
                  if (type == 'reading')
                    IconButton(
                      icon: const Icon(
                        Icons.library_add_check_rounded,
                        color: AppColors.burgundy,
                        size: 28,
                      ),
                      tooltip: '다 읽었어요 (서재 아카이빙)',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => ReadingRecordDialog(
                            userBook: book,
                            onConfirm:
                                (readPages, totalPages, readCount) async {
                                  final userId = Supabase
                                      .instance
                                      .client
                                      .auth
                                      .currentUser
                                      ?.id;
                                  if (userId != null) {
                                    await ref
                                        .read(supabaseRepositoryProvider)
                                        .updateUserBookStatus(
                                          userId,
                                          book.isbn,
                                          'read',
                                          readPages: readPages,
                                          totalPages: totalPages,
                                          readCount: readCount,
                                        );
                                    ref.invalidate(
                                      userBooksProvider,
                                    );

                                    if (context.mounted) {
                                      FlorenceToast.show(
                                        context,
                                        '서재에 추가되었습니다.',
                                      );
                                    }
                                  }
                                },
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month}.${date.day}';
  }
}
