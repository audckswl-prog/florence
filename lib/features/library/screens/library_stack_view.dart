import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/florence_loader.dart';
import '../providers/library_providers.dart';
import '../widgets/book_spine_widget.dart';
import '../screens/book_search_delegate.dart';

class LibraryStackView extends ConsumerWidget {
  const LibraryStackView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(readBooksProvider);
    final books = booksAsync.asData?.value;
    final isLoading = booksAsync.isLoading || (!booksAsync.hasValue && !booksAsync.hasError);

    Widget body;
    if (booksAsync.hasError) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            '데이터를 불러오는데 실패했습니다.',
            style: TextStyle(color: AppColors.burgundy.withOpacity(0.7)),
          ),
        ),
      );
    } else if (books == null && !isLoading) {
      body = const SizedBox.shrink();
    } else if (books != null && books.isEmpty) {
      body = EmptyStateWidget(
        icon: Icons.menu_book_rounded,
        title: '서재가 비어있어요',
        subtitle: '읽은 책을 추가하여\n나만의 독서 기록을 쌓아보세요.',
        actionLabel: '책 추가하기',
        onAction: () {
          showSearch(
            context: context,
            delegate: BookSearchDelegate(ref),
          );
        },
      );
    } else if (books != null) {
      // 가장 오래된 책이 맨 아래(네비바 근처), 최신 책이 맨 위
      // 날짜 오름차순 정렬 (Oldest -> Newest)
      final displayBooks = books.toList()
        ..sort((a, b) {
          final aDate = a.finishedAt ?? a.startedAt ?? DateTime(2000);
          final bDate = b.finishedAt ?? b.startedAt ?? DateTime(2000);
          return aDate.compareTo(bDate);
        });

      body = Column(
        // mainAxisAlignment.end → 내용물이 아래에서부터 채워짐
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 책 권수 표시 (Shelf Header Style)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: AppColors.burgundy.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Center(
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(
                    color: AppColors.burgundy,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Pretendard',
                  ),
                  children: [
                    const TextSpan(
                      text: '총 ',
                      style: TextStyle(letterSpacing: 4.0), // "총"과 숫자 사이는 여유롭게
                    ),
                    TextSpan(
                      text: '${books.length}권',
                      style: const TextStyle(letterSpacing: 2.0), // 숫자와 "권" 간격 조금 더 넓힘
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 스크롤 가능한 책 스택 영역
          Flexible(
            child: ListView.builder(
              // reverse: true → 스크롤 시작점이 아래
              // ListView에서 reverse:true일 때, index 0이 맨 아래에 위치함
              // displayBooks는 [Oldest, ..., Newest] 순서이므로
              // index 0 (Oldest)가 맨 아래에 위치하게 됨.
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: displayBooks.length,
              itemBuilder: (context, index) {
                final book = displayBooks[index];
                return BookSpineWidget(
                  key: ValueKey(book.isbn),
                  userBook: book,
                );
              },
            ),
          ),

          // 바닥 받침선 (네비바 바로 위)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Column(
              children: [
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.charcoal.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.charcoal.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      body = const SizedBox.shrink();
    }

    return FlorenceLoadingOverlay(
      isLoading: isLoading,
      child: body,
    );
  }
}
