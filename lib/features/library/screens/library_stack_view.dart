import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/florence_loader.dart';
import '../providers/library_providers.dart';
import '../widgets/book_spine_widget.dart';
import '../screens/book_search_delegate.dart';
import '../../../data/models/user_book_model.dart';

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
        children: [
          // 상단 총 권수 헤더 (사진 비율 참고 적용)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 24.0, bottom: 0.0), // 책 윗부분에 거의 닿도록 아래 마진 제거
            child: Column(
              children: [
                // 1. 숫자 텍스트 (총 글자 추가, 가운데 정렬)
                Text(
                  '총 ${books.length}권',
                  style: const TextStyle(
                    color: AppColors.burgundy,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Pretendard',
                    letterSpacing: 2.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0), // 숫자와 라인 사이의 간격
                // 2. 1px 가로선 (양옆 패딩 24.0을 주어 아래쪽 붉은 선반과 가로 너비를 100% 동일하게 일치)
                Padding(
                  // 선반이 화면 양끝에서 24만큼 떨어져서 시작하므로 패딩 24.0 적용
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    height: 1.0, // 1px 두께
                    color: AppColors.burgundy, // 선반과 똑같은 버건디 라인
                  ),
                ),
              ],
            ),
          ),
          // 스크롤 가능한 책장 영역 (위쪽 스크롤)
          Flexible(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 최대 가용 너비 (양옆 패딩 24 * 2 = 48 제외한 공간에서 75%만 책장으로 사용)
                // 이렇게 함으로써 오른쪽에 자연스러운 여백이 남게 만듭니다.
                final double maxShelfWidth = (constraints.maxWidth - 48.0) * 0.75;
                
                // 책들을 선반 단위로 묶기 (아래 선반부터 윗 선반으로)
                // 현재 코드로는 Oldest부터 순서대로 묶음
                final List<List<UserBook>> shelves = [];
                List<UserBook> currentRow = [];
                double currentRowWidth = 0.0;
                
                // 책과 책 사이의 간격
                const double spacing = 1.0; 

                for (var book in displayBooks) {
                  double bookWidth = 0.0;
                  int pages = book.book.pageCount;
                  if (pages == 0) {
                     final random = Random(book.isbn.hashCode);
                     pages = 200 + random.nextInt(400);
                  }
                  final int readPages = book.readPages;
                  final int totalPages = book.totalPages ?? pages;
                  double thicknessRatio = 1.0;
                  if (readPages > 0 && totalPages > 0 && readPages <= totalPages) {
                    thicknessRatio = readPages / totalPages;
                  }
                  
                  // 방금 스케일을 복구한 가장 큰 사이즈 비율로 다시 맞춤
                  bookWidth = ((18.0 + (pages * 0.08)) * thicknessRatio).clamp(14.0, 70.0);

                  if (currentRowWidth + bookWidth + spacing > maxShelfWidth && currentRow.isNotEmpty) {
                    shelves.add(currentRow);
                    currentRow = [];
                    currentRowWidth = 0.0;
                  }
                  currentRow.add(book);
                  currentRowWidth += bookWidth + spacing;
                }
                if (currentRow.isNotEmpty) {
                  shelves.add(currentRow);
                }

                // shelves는 [0번째 줄(가장오래된책들), 1번째 줄, ... , 마지막 줄(최신책들)]
                // 아랫부분 여백을 모두 없애고 맨 밑바닥 선이 네비바 라인에 완벽히 닿도록 수정
                return ListView.builder(
                  reverse: true, // 아래쪽부터 아이템(선반) 시작
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0), // 상하 여백 완전히 제거
                  itemCount: shelves.length,
                  itemBuilder: (context, index) {
                    final shelfBooks = shelves[index];
                    // reverse: true 이므로 index == 0 인 항목이 화면의 맨 밑바닥 선반
                    return _buildShelfRow(shelfBooks, isLastShelf: index == 0);
                  },
                );
              }
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

  // 선반 한 칸(Row)을 그리는 헬퍼 위젯
  Widget _buildShelfRow(List<UserBook> shelfBooks, {bool isLastShelf = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: isLastShelf ? 12.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        // 1) 책들이 서 있는 메인 공간
        // 바닥(선반 위)에 딱 맞닿게 정렬 -> crossAxisAlignment.end
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, 
            crossAxisAlignment: CrossAxisAlignment.end,
            children: shelfBooks.map((b) => BookSpineWidget(
              key: ValueKey(b.isbn),
              userBook: b,
            )).toList(),
          ),
        ),
        
        // 2) 묵직한 나무 느낌의 선반 받침대
        Container(
          width: double.infinity,
          height: 12, // 선반 두께
          decoration: BoxDecoration(
            color: const Color(0xFF5A1E1E), // 어두운 버건디/우드 색감
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          margin: const EdgeInsets.only(bottom: 24), // 선반 사이 세로 갭 (위쪽 선반 책들이 숨쉴 공간)
        ),
      ],
    ),
   );
  }
}
